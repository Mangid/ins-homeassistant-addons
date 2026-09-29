#!/usr/bin/env bash
set -euo pipefail
read -r INTERVAL TIMEZONE < <(python3 - <<'PY'
import json
try:
    with open("/data/options.json", encoding="utf-8") as f:
        o=json.load(f)
        print(o.get("interval_seconds", 10), o.get("timezone", "Europe/Vienna"))
except Exception:
    print(10, "Europe/Vienna")
PY
)
export TZ="$TIMEZONE"
echo "=== INS-EI TEST ==="
echo "Core SHA: $(cat /opt/ins-ei/core/.ins-ei-core-sha 2>/dev/null || echo unknown)"
echo "Persistent TEST data: /data"

readarray -t MQTT_OPTS < <(python3 - <<'PY'
import json
try:
    with open('/data/options.json','r',encoding='utf-8') as f:
        o=json.load(f)
except Exception:
    o={}
for key, default in [
    ('mqtt_enabled', False),('mqtt_host',''),('mqtt_port',8883),
    ('mqtt_username',''),('mqtt_password',''),('mqtt_tls',True)
]:
    v=o.get(key,default)
    if isinstance(v,bool): v='true' if v else 'false'
    print(v)
PY
)
export INS_EI_MQTT_ENABLED="${MQTT_OPTS[0]}"
export INS_EI_MQTT_HOST="${MQTT_OPTS[1]}"
export INS_EI_MQTT_PORT="${MQTT_OPTS[2]}"
export INS_EI_MQTT_USERNAME="${MQTT_OPTS[3]}"
export INS_EI_MQTT_PASSWORD="${MQTT_OPTS[4]}"
export INS_EI_MQTT_TLS="${MQTT_OPTS[5]}"
echo "Collection interval: ${INTERVAL}s"
echo "Timezone: ${TIMEZONE}"
echo "Plugin manifests:"
find /opt/ins-ei/core/plugins -maxdepth 2 -name manifest.yaml -print || true
exec ins-ei --site /data/site.yaml --plugins /opt/ins-ei/core/plugins --data /data --interval "${INTERVAL}" --host 0.0.0.0 --port 8080
