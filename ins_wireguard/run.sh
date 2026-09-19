#!/usr/bin/with-contenv bashio
set -e

VERSION="0.2.0"

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

# ----------------------------------------------------------
# Konfiguration prüfen
# ----------------------------------------------------------

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

# ----------------------------------------------------------
# WireGuard-Konfiguration erzeugen
# ----------------------------------------------------------

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

# ----------------------------------------------------------
# Eventuell vorhandenes Interface entfernen
# ----------------------------------------------------------

if ip link show wg0 >/dev/null 2>&1; then
    bashio::log.warning "Vorhandenes wg0-Interface wird entfernt."
    wg-quick down wg0 || true
fi

# ----------------------------------------------------------
# WireGuard starten
# ----------------------------------------------------------

bash