#!/usr/bin/env bash
# Verification: tests each hook with valid and invalid synthetic Swift content.
set -euo pipefail

HOOKS_DIR="/home/user/meal-value/.claude/hooks"
MANIFEST="/home/user/meal-value/.claude/healthkit-manifest.json"
PASS=0
FAIL=0

run_hook() {
  local hook="$1"
  local label="$2"
  local input_json="$3"
  local expect_exit="$4"

  actual_exit=0
  actual_output=$(echo "$input_json" | bash "$HOOKS_DIR/$hook" 2>&1) || actual_exit=$?

  if [[ "$actual_exit" -eq "$expect_exit" ]]; then
    echo "  PASS: $label"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $label (expected exit $expect_exit, got $actual_exit)"
    [[ -n "$actual_output" ]] && echo "    output: $actual_output"
    FAIL=$((FAIL + 1))
  fi
}

TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# ── Prepare a valid synthetic HealthKit Swift file ──────────────────────────
VALID_FILE="$TMPDIR_TEST/HealthKitDietaryProtein.swift"
cat > "$VALID_FILE" <<'SWIFT'
import Foundation
import HealthKit

// MARK: - HealthKitDietaryProtein

enum HealthKitDietaryProtein {}

// MARK: - HealthKitBridgeProtocol

extension HealthKitDietaryProtein: HealthKitBridgeProtocol {
    typealias AppModel = NutritionValues
    typealias HKObjectType = HKQuantitySample

    static var hkIdentifier: String { "HKQuantityTypeIdentifierDietaryProtein" }
    static var hkUnit: HKUnit { HKUnit.gram() }

    static func toHealthKitSample(from model: NutritionValues, date: Date) -> HKQuantitySample? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .dietaryProtein) else { return nil }
        let quantity = HKQuantity(unit: hkUnit, doubleValue: model.protein)
        return HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
    }

    static func fromHealthKitSample(_ sample: HKQuantitySample) -> NutritionValues? {
        var values = NutritionValues.zero
        values.protein = sample.quantity.doubleValue(for: hkUnit)
        return values
    }
}

// MARK: - HealthKitWritable

extension HealthKitDietaryProtein: HealthKitWritable {
    static func write(_ model: NutritionValues, to manager: HealthKitManager) async throws {
        guard manager.authorizationStatus(for: .dietaryProtein) == .sharingAuthorized else { return }
        guard let sample = toHealthKitSample(from: model, date: Date()) else { return }
        try await manager.save(sample)
    }
}
SWIFT

# ── Prepare an invalid file: missing import HealthKit ──────────────────────
INVALID_NO_IMPORT="$TMPDIR_TEST/HealthKitBadNoImport.swift"
cat > "$INVALID_NO_IMPORT" <<'SWIFT'
import Foundation

enum HealthKitBadNoImport {}
extension HealthKitBadNoImport: HealthKitBridgeProtocol {}
SWIFT

# ── Prepare an invalid file: unbalanced braces ─────────────────────────────
INVALID_BRACES="$TMPDIR_TEST/HealthKitBadBraces.swift"
cat > "$INVALID_BRACES" <<'SWIFT'
import Foundation
import HealthKit

enum HealthKitBadBraces {
    static func foo() {
        let x = 1
    // missing closing brace
SWIFT

# ── Prepare an invalid file: direct HKHealthStore() ───────────────────────
INVALID_STORE="$TMPDIR_TEST/HealthKitBadStore.swift"
cat > "$INVALID_STORE" <<'SWIFT'
import Foundation
import HealthKit

enum HealthKitBadStore {}
extension HealthKitBadStore: HealthKitBridgeProtocol {
    static var hkIdentifier: String { "" }
    static var hkUnit: HKUnit { HKUnit.gram() }
    static func toHealthKitSample(from model: NutritionValues, date: Date) -> HKQuantitySample? {
        let store = HKHealthStore()
        return nil
    }
    static func fromHealthKitSample(_ sample: HKQuantitySample) -> NutritionValues? { nil }
}
SWIFT

make_write_event() {
  local fp="$1"
  python3 -c "import json,sys; print(json.dumps({'tool_name':'Write','tool_input':{'file_path':sys.argv[1]},'tool_response':{'success':True}}))" "$fp"
}

echo ""
echo "=== validate-swift-syntax.sh ==="
run_hook "validate-swift-syntax.sh" "valid file passes"         "$(make_write_event "$VALID_FILE")"       0
run_hook "validate-swift-syntax.sh" "missing import HealthKit"  "$(make_write_event "$INVALID_NO_IMPORT")" 1
run_hook "validate-swift-syntax.sh" "unbalanced braces"         "$(make_write_event "$INVALID_BRACES")"   1
run_hook "validate-swift-syntax.sh" "non-swift file is no-op"   "$(make_write_event "/some/file.py")"     0

echo ""
echo "=== enforce-hk-contract.sh ==="
run_hook "enforce-hk-contract.sh" "valid file passes"           "$(make_write_event "$VALID_FILE")"       0
run_hook "enforce-hk-contract.sh" "missing import HealthKit"    "$(make_write_event "$INVALID_NO_IMPORT")" 1
run_hook "enforce-hk-contract.sh" "direct HKHealthStore()"      "$(make_write_event "$INVALID_STORE")"    1
run_hook "enforce-hk-contract.sh" "non-HK swift file is no-op"  "$(make_write_event "/some/Models.swift")" 0

echo ""
echo "=== check-manifest-duplicate.sh ==="
if [[ -f "$MANIFEST" ]]; then
  # non-pending entry
  DUPED_FILE="MealValue/HealthKitDietaryEnergy.swift"
  python3 -c "
import json
with open('$MANIFEST') as f: m = json.load(f)
for e in m.get('scaffolded_types',[]):
    if 'DietaryEnergy' in e.get('swift_file',''):
        orig = e['status']
        e['status'] = 'scaffolded'
        with open('$MANIFEST','w') as f: json.dump(m, f, indent=2)
        print(orig)
        break
" > /tmp/orig_status.txt

  run_hook "check-manifest-duplicate.sh" "duplicate scaffolded entry blocked" \
    "$(make_write_event "/home/user/meal-value/MealValue/HealthKitDietaryEnergy.swift")" 1
  run_hook "check-manifest-duplicate.sh" "non-HK file is no-op" \
    "$(make_write_event "/home/user/meal-value/MealValue/Models.swift")" 0

  # restore status
  python3 -c "
import json
orig = open('/tmp/orig_status.txt').read().strip() or 'pending'
with open('$MANIFEST') as f: m = json.load(f)
for e in m.get('scaffolded_types',[]):
    if 'DietaryEnergy' in e.get('swift_file',''):
        e['status'] = orig
        break
with open('$MANIFEST','w') as f: json.dump(m, f, indent=2)
"
else
  echo "  SKIP: manifest not found, skipping duplicate check tests"
fi

echo ""
echo "=== RESULTS ==="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
[[ "$FAIL" -eq 0 ]] && echo "  ALL TESTS PASSED" && exit 0
echo "  SOME TESTS FAILED" && exit 1
