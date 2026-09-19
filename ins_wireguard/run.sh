#!/usr/bin/with-contenv bashio

VERSION="0.2.4"

bashio::log.info "=========================================="
bashio::log.info " INS WireGuard Client v${VERSION}"
bashio::log.info " INS-Energietechnik"
bashio::log.info "=========================================="

VPN_ADDRESS=$(bashio::config 'vpn_address')
ENDPOINT=$(bashio::config 'endpoint')
SERVER_PUBLIC_KEY=$(bashio::config 'server_public_key')
CLIENT_PRIVATE_KEY=$(bashio::config 'client_private_key')
ALLOWED_IPS=$(bashio::config 'allowed_ips')
MTU=$(bashio::config 'mtu')
KEEPALIVE=$(bashio::config 'persistent_keepalive')

if [ -z "${VPN_ADDRESS}" ]; then
    bashio::log.error "Keine WireGuard VPN-Adresse konfiguriert."
    exit 1
fi

if [ -z "${CLIENT_PRIVATE_KEY}" ]; then
    bashio::log.error "Kein Client Private Key konfiguriert."
    exit 1
fi

if [ -z "${SERVER_PUBLIC_KEY}" ]; then
    bashio::log.error "Kein Server Public Key konfiguriert."
    exit 1
fi

if [ -z "${ENDPOINT}" ]; then
    bashio::log.error "Kein WireGuard Endpoint konfiguriert."
    exit 1
fi

mkdir -p /etc/wireguard
chmod 700 /etc/wireguard

cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${VPN_ADDRESS}
MTU = ${MTU}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
AllowedIPs = ${ALLOWED_IPS}
Endpoint = ${ENDPOINT}
PersistentKeepalive = ${KEEPALIVE}
EOF

chmod 600 /etc/wireguard/wg0.conf

bashio::log.info "VPN-Adresse : ${VPN_ADDRESS}"
bashio::log.info "Endpoint    : ${ENDPOINT}"
bashio::log.info "Allowed IPs : ${ALLOWED_IPS}"
bashio::log.info "MTU         : ${MTU}"
bashio::log.info "Keepalive   : ${KEEPALIVE}"

bashio::log.info "=========================================="
bashio::log.info "Starte Runtime-Diagnose"
bashio::log.info "=========================================="

bashio::log.info "TEST 1: Skript läuft nach Konfiguration"

bashio::log.info "TEST 2: Prüfe ip"
if command -v ip >/dev/null 2>&1; then
    bashio::log.info "ip gefunden: $(command -v ip)"
else
    bashio::log.error "ip nicht gefunden"
fi

bashio::log.info "TEST 3: Prüfe wg"
if command -v wg >/dev/null 2>&1; then
    bashio::log.info "wg gefunden: $(command -v wg)"
else
    bashio::log.error "wg nicht gefunden"
fi

bashio::log.info "TEST 4: Prüfe wg-quick"
if command -v wg-quick >/dev/null 2>&1; then
    bashio::log.info "wg-quick gefunden: $(command -v wg-quick)"
else
    bashio::log.error "wg-quick nicht gefunden"
fi

bashio::log.info "TEST 5: Prüfe /dev/net/tun"
if [ -e /dev/net/tun ]; then
    bashio::log.info "/dev/net/tun vorhanden"
else
    bashio::log.error "/dev/net/tun NICHT vorhanden"
fi

bashio::log.info "TEST 6: Netzwerk-Interfaces"
ip link show || true

bashio::log.info "TEST 7: WireGuard-Version"
wg --version || true

bashio::log.info "=========================================="
bashio::log.info "Diagnose abgeschlossen"
bashio::log.info "WireGuard wird noch nicht gestartet."
bashio::log.info "=========================================="

while true; do
    sleep 3600
done