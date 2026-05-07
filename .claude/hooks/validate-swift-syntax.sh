#!/usr/bin/env bash
# PostToolUse(Write): structural validation for Swift files (Python fallback, no swiftc needed).
set -euo pipefail

HOOK_NAME="validate-swift-syntax"

input=$(cat)
file_path=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)

basename=$(basename "$file_path")
if [[ "$basename" != *.swift ]]; then
  exit 0
fi

if [[ ! -f "$file_path" ]]; then
  exit 0
fi

# Per-file iteration guard (max 5 rapid retries per session)
COUNTER_FILE="/tmp/hk-hook-$(echo "$file_path" | md5sum | cut -d' ' -f1).count"
count=0
if [[ -f "$COUNTER_FILE" ]]; then
  count=$(cat "$COUNTER_FILE")
fi
count=$((count + 1))
echo "$count" > "$COUNTER_FILE"

if (( count > 5 )); then
  echo "HOOK ERROR [$HOOK_NAME]: NON_RECOVERABLE: File '$basename' has been rewritten $count times in this session. Halting loop. Please review the file manually." >&2
  exit 1
fi

python3 - "$file_path" "$basename" <<'PYEOF'
import sys, re

file_path = sys.argv[1]
basename = sys.argv[2]

with open(file_path) as f:
    content = f.read()
    lines = content.splitlines()

errors = []

# 1. Must have at least one import
if not any(line.strip().startswith("import ") for line in lines):
    errors.append("No 'import' statement found")

# 2. HealthKit files must import HealthKit
if basename.startswith("HealthKit") and basename != "HealthKitBridge.swift" and basename != "HealthKitManager.swift":
    if "import HealthKit" not in content:
        errors.append("Missing 'import HealthKit'")

# 3. Balanced braces
open_count = content.count("{")
close_count = content.count("}")
if open_count != close_count:
    errors.append(f"Unbalanced braces (opened: {open_count}, closed: {close_count})")

# 4. Balanced parentheses
open_p = content.count("(")
close_p = content.count(")")
if open_p != close_p:
    errors.append(f"Unbalanced parentheses (opened: {open_p}, closed: {close_p})")

# 5. Must declare at least one type or protocol
type_decl = re.search(r'\b(class|struct|enum|protocol|extension)\s+\w+', content)
if not type_decl:
    errors.append("No type declaration (class/struct/enum/protocol/extension) found")

# 6. No force-try
if "try!" in content:
    errors.append("Force-try 'try!' is forbidden")

# 7. No empty file
if len(content.strip()) < 10:
    errors.append("File appears to be empty or trivially short")

if errors:
    for e in errors:
        print(f"HOOK ERROR [validate-swift-syntax]: {e}", file=sys.stderr)
    sys.exit(1)

sys.exit(0)
PYEOF
