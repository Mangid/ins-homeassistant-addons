#!/usr/bin/env bash
set -euo pipefail

INTERVAL="$(python3 - <<'PY'
import json
try:
    with open("/data/options.json", encoding="utf-8") as f:
        print(json.load(f).get("interval_seconds", 10))
except Exception:
    print(10)
PY
)"

SITE="/data/site.yaml"

echo "INS-EI V1 starting"
echo "Persistent data: /data"
echo "Collection interval: ${INTERVAL}s"

exec ins-ei \
  --site "${SITE}" \
  --plugins /opt/ins-ei/core/plugins \
  --data /data \
  --interval "${INTERVAL}" \
  --host 0.0.0.0 \
  --port 8080
