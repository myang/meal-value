#!/usr/bin/env bash
# PostToolUse(Write): enforce HealthKit integration rules from CLAUDE.md.
set -euo pipefail

HOOK_NAME="enforce-hk-contract"

input=$(cat)
file_path=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)

basename=$(basename "$file_path")

# Only act on HealthKit*.swift files, excluding base infrastructure files
if [[ "$basename" != HealthKit*.swift ]]; then
  exit 0
fi
if [[ "$basename" == "HealthKitBridge.swift" || "$basename" == "HealthKitManager.swift" ]]; then
  exit 0
fi

if [[ ! -f "$file_path" ]]; then
  exit 0
fi

python3 - "$file_path" "$basename" <<'PYEOF'
import sys, re

file_path = sys.argv[1]
basename = sys.argv[2]

with open(file_path) as f:
    content = f.read()

errors = []

# Rule 1: must import HealthKit
if "import HealthKit" not in content:
    errors.append("MISSING: 'import HealthKit'")

# Rule 2: must declare HealthKitBridgeProtocol conformance in an extension
if "HealthKitBridgeProtocol" not in content:
    errors.append("MISSING: 'HealthKitBridgeProtocol' conformance declaration")

# Rule 3: no direct HKHealthStore() instantiation (singleton violation)
if re.search(r'HKHealthStore\s*\(\s*\)', content):
    errors.append("VIOLATION: Direct 'HKHealthStore()' instantiation is forbidden. Use 'HealthKitManager.shared' instead.")

# Rule 4: no force-try
if "try!" in content:
    errors.append("VIOLATION: 'try!' is forbidden in HealthKit integration code")

# Rule 5: if file contains write path, must check authorization
has_write_path = "func write(" in content or "async throws" in content
has_auth_check = "sharingAuthorized" in content or "authorizationStatus" in content
if has_write_path and not has_auth_check:
    errors.append("MISSING: Authorization check (sharingAuthorized / authorizationStatus) required before writing to HealthKit")

# Rule 6: HKQuantityType.quantityType(forIdentifier:) must not be force-unwrapped
force_unwrap_hk = re.search(r'quantityType\(forIdentifier:[^)]+\)\s*!', content)
if force_unwrap_hk:
    errors.append("VIOLATION: Force-unwrap on 'quantityType(forIdentifier:)' is forbidden. Use 'guard let' or 'if let'.")

# Rule 7: no // TODO: comments
if "// TODO:" in content:
    errors.append("VIOLATION: '// TODO:' comments are forbidden. Use '// SCAFFOLD: <reason>' for incomplete stubs.")

if errors:
    for e in errors:
        print(f"HOOK ERROR [{basename[:-6]}]: {e}", file=sys.stderr)
    sys.exit(1)

sys.exit(0)
PYEOF
