#!/usr/bin/env bash
# PreToolUse(Write): block if the target HealthKit*.swift is already scaffolded in the manifest.
set -euo pipefail

MANIFEST="/home/user/meal-value/.claude/healthkit-manifest.json"

input=$(cat)
file_path=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)

# Only act on HealthKit*.swift files
basename=$(basename "$file_path")
if [[ "$basename" != HealthKit*.swift ]]; then
  exit 0
fi

if [[ ! -f "$MANIFEST" ]]; then
  exit 0
fi

# Check if this file already has a non-pending status in manifest
result=$(python3 - <<'PYEOF'
import sys, json, os

manifest_path = "/home/user/meal-value/.claude/healthkit-manifest.json"
import json
input_data = json.loads(sys.stdin.read()) if not sys.stdin.isatty() else {}
PYEOF
)

status=$(python3 - "$file_path" "$MANIFEST" <<'PYEOF'
import sys, json

file_path = sys.argv[1]
manifest_path = sys.argv[2]
basename = __import__('os').path.basename(file_path)

with open(manifest_path) as f:
    manifest = json.load(f)

all_types = manifest.get("scaffolded_types", []) + manifest.get("correlation_types", [])
for entry in all_types:
    swift_file = __import__('os').path.basename(entry.get("swift_file", ""))
    if swift_file == basename and entry.get("status", "pending") != "pending":
        print(f"DUPLICATE:{entry['hk_identifier']}:{entry['status']}")
        sys.exit(0)

print("OK")
PYEOF
)

if [[ "$status" == DUPLICATE:* ]]; then
  hk_id=$(echo "$status" | cut -d: -f2)
  current_status=$(echo "$status" | cut -d: -f3)
  echo "HOOK ERROR [check-manifest-duplicate]: HK type '$hk_id' already scaffolded with status='$current_status'. Reset status to 'pending' in manifest to re-scaffold." >&2
  exit 1
fi

exit 0
