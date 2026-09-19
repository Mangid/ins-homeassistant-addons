#!/usr/bin/with-contenv bashio

VERSION="0.2.5"

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
    bashio::log.error "Keine VPN-Adresse konfiguriert."
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
    bashio::log.error "Kein Endpoint konfiguriert."
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
bashio::log.info "Starte WireGuard"
bashio::log.info "=========================================="

# Eventuell vorhandenes wg0 sauber entfernen
if ip link show wg0 >/dev/null 2>&1; then
    bashio::log.warning "wg0 existiert bereits und wird neu gestartet."
    wg-quick down /etc/wireguard/wg0.conf || true
fi

if wg-quick up /etc/wireguard/wg0.conf; then
    bashio::log.info "WireGuard-Interface wg0 erfolgreich gestartet."
else
    bashio::log.error "WireGuard konnte nicht gestartet werden."
    exit 1
fi

sleep 3

bashio::log.info "=========================================="
bashio::log.info "WireGuard Status"
bashio::log.info "=========================================="

wg show wg0 || true

bashio::log.info "=========================================="
bashio::log.info "Routing"
bashio::log.info "=========================================="

ip route show | grep -E '10\.10\.0\.0|wg0' || true

bashio::log.info "=========================================="
bashio::log.info "INS WireGuard Client läuft"
bashio::log.info "=========================================="

while true; do
    sleep 3600
done