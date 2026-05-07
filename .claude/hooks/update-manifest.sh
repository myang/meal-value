#!/usr/bin/env bash
# PostToolUse(Write): update manifest entry to status "scaffolded" after successful write.
set -euo pipefail

MANIFEST="/home/user/meal-value/.claude/healthkit-manifest.json"

input=$(cat)
file_path=$(echo "$input" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)

basename=$(basename "$file_path")
if [[ "$basename" != HealthKit*.swift ]]; then
  exit 0
fi
# Base infrastructure files don't get manifest entries updated here
if [[ "$basename" == "HealthKitBridge.swift" || "$basename" == "HealthKitManager.swift" ]]; then
  exit 0
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "WARNING [update-manifest]: manifest not found at $MANIFEST, skipping update" >&2
  exit 0
fi

python3 - "$file_path" "$MANIFEST" <<'PYEOF'
import sys, json, os
from datetime import datetime, timezone

file_path = sys.argv[1]
manifest_path = sys.argv[2]
basename = os.path.basename(file_path)

with open(manifest_path) as f:
    manifest = json.load(f)

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
updated = False

for section in ("scaffolded_types", "correlation_types"):
    for entry in manifest.get(section, []):
        entry_basename = os.path.basename(entry.get("swift_file", ""))
        if entry_basename == basename and entry.get("status") == "pending":
            entry["status"] = "scaffolded"
            entry["scaffolded_at"] = now
            entry["swift_file"] = file_path
            updated = True

with open(manifest_path, "w") as f:
    json.dump(manifest, f, indent=2)

if updated:
    print(f"[update-manifest] Set status=scaffolded for {basename}")
PYEOF
