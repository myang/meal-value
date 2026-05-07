#!/usr/bin/env python3
"""
Structural verification for MealValue HealthKit Swift files.
Does not require swiftc — checks patterns, imports, and manifest consistency.
"""
import json
import os
import re
import sys

ROOT = "/home/user/meal-value"
SWIFT_DIR = os.path.join(ROOT, "MealValue")
MANIFEST_PATH = os.path.join(ROOT, ".claude/healthkit-manifest.json")

PASS = "\033[32mPASS\033[0m"
FAIL = "\033[31mFAIL\033[0m"
WARN = "\033[33mWARN\033[0m"

results = []

def check(label, condition, severity="FAIL"):
    tag = PASS if condition else (FAIL if severity == "FAIL" else WARN)
    results.append((label, condition, severity))
    status = "PASS" if condition else severity
    print(f"  [{status:4s}] {label}")
    return condition

# ── Per-file checks ──────────────────────────────────────────────────────────
hk_files = [
    f for f in os.listdir(SWIFT_DIR)
    if f.startswith("HealthKit") and f.endswith(".swift")
]

if not hk_files:
    print("No HealthKit*.swift files found in MealValue/ — nothing to verify yet.")
    sys.exit(0)

print(f"\nFound {len(hk_files)} HealthKit Swift file(s):\n")

for fname in sorted(hk_files):
    fpath = os.path.join(SWIFT_DIR, fname)
    with open(fpath) as f:
        content = f.read()

    print(f"── {fname}")

    if fname == "HealthKitBridge.swift":
        check("  declares HealthKitBridgeProtocol",
              "protocol HealthKitBridgeProtocol" in content)
        check("  declares HealthKitWritable",
              "protocol HealthKitWritable" in content)
        check("  declares HealthKitReadable",
              "protocol HealthKitReadable" in content)
        check("  imports Foundation",
              "import Foundation" in content)
        print()
        continue

    if fname == "HealthKitManager.swift":
        check("  imports Foundation",           "import Foundation" in content)
        check("  imports HealthKit",            "import HealthKit" in content)
        check("  static let shared",            "static let shared" in content)
        check("  private let store = HKHealthStore()",
              "private let store = HKHealthStore()" in content)
        check("  no direct HKHealthStore() outside init",
              content.count("HKHealthStore()") == 1)
        print()
        continue

    # Generated quantity/correlation type files
    check("  imports Foundation",        "import Foundation" in content)
    check("  imports HealthKit",         "import HealthKit" in content)
    check("  HealthKitBridgeProtocol conformance in extension",
          bool(re.search(r'extension\s+\w+\s*:\s*HealthKitBridgeProtocol', content)))
    check("  hkIdentifier static property",
          "static var hkIdentifier: String" in content)
    check("  hkUnit static property",
          "static var hkUnit: HKUnit" in content)
    check("  toHealthKitSample implemented (not fatalError)",
          "func toHealthKitSample(" in content and "fatalError" not in content)
    check("  fromHealthKitSample implemented (not fatalError)",
          "func fromHealthKitSample(" in content and "fatalError" not in content)
    check("  no try!",                   "try!" not in content)
    check("  no // TODO:",               "// TODO:" not in content)
    check("  namespace uses enum (not class/struct)",
          bool(re.search(r'^enum\s+HealthKit', content, re.MULTILINE)))
    check("  no direct HKHealthStore()",
          not bool(re.search(r'(?<!private let store = )HKHealthStore\s*\(\s*\)', content)))
    print()

# ── Manifest consistency check ───────────────────────────────────────────────
print("── Manifest consistency")
if not os.path.exists(MANIFEST_PATH):
    print(f"  [WARN] Manifest not found at {MANIFEST_PATH}")
else:
    with open(MANIFEST_PATH) as f:
        manifest = json.load(f)

    all_entries = manifest.get("scaffolded_types", []) + manifest.get("correlation_types", [])
    for entry in all_entries:
        swift_file = entry.get("swift_file", "")
        hk_id = entry.get("hk_identifier", "?")
        status = entry.get("status", "pending")
        if not swift_file:
            continue
        exists = os.path.exists(swift_file)
        if status in ("scaffolded", "reviewed", "validated"):
            check(f"  {hk_id}: swift_file exists at {os.path.basename(swift_file)}", exists)
        if status == "validated":
            check(f"  {hk_id}: validated_at is set",
                  entry.get("validated_at") is not None)

print()

# ── Summary ──────────────────────────────────────────────────────────────────
failures = [r for r in results if not r[1] and r[2] == "FAIL"]
warnings = [r for r in results if not r[1] and r[2] == "WARN"]

print(f"=== SUMMARY: {len(results)} checks, "
      f"{len(results)-len(failures)-len(warnings)} passed, "
      f"{len(failures)} failed, {len(warnings)} warnings ===")

if failures:
    print("\nFailed checks:")
    for label, _, _ in failures:
        print(f"  - {label.strip()}")
    sys.exit(1)

print("All structural checks passed.")
sys.exit(0)
