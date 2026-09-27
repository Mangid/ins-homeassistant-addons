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
echo "=== INS-EI TEST ==="
echo "Core SHA: $(cat /opt/ins-ei/core/.ins-ei-core-sha 2>/dev/null || echo unknown)"
echo "Persistent TEST data: /data"
echo "Collection interval: ${INTERVAL}s"
echo "Plugin manifests:"
find /opt/ins-ei/core/plugins -maxdepth 2 -name manifest.yaml -print || true
exec ins-ei --site /data/site.yaml --plugins /opt/ins-ei/core/plugins --data /data --interval "${INTERVAL}" --host 0.0.0.0 --port 8080
