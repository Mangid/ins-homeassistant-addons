#!/usr/bin/with-contenv bashio

VERSION="0.3.0"

bashio::log.info "=========================================="
bashio::log.info " INS WireGuard Client v${VERSION}"
bashio::log.info " INS-Energietechnik"
bashio::log.info "=========================================="

# ----------------------------------------------------------
# Konfiguration
# ----------------------------------------------------------

VPN_ADDRESS=$(bashio::config 'vpn_address')
ENDPOINT=$(bashio::config 'endpoint')
SERVER_PUBLIC_KEY=$(bashio::config 'server_public_key')
CLIENT_PRIVATE_KEY=$(bashio::config 'client_private_key')
ALLOWED_IPS=$(bashio::config 'allowed_ips')
MTU=$(bashio::config 'mtu')
KEEPALIVE=$(bashio::config 'persistent_keepalive')

SUBNET_ROUTING=$(bashio::config 'subnet_routing')
LOCAL_SUBNET=$(bashio::config 'local_subnet')
LAN_INTERFACE=$(bashio::config 'lan_interface')

# ----------------------------------------------------------
# Pflichtfelder prüfen
# ----------------------------------------------------------

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

if [ -z "${ALLOWED_IPS}" ]; then
    bashio::log.error "Keine Allowed IPs konfiguriert."
    exit 1
fi

# ----------------------------------------------------------
# Subnet-Routing prüfen
# ----------------------------------------------------------

if [ "${SUBNET_ROUTING}" = "true" ]; then

    if [ -z "${LOCAL_SUBNET}" ]; then
        bashio::log.error "Subnet-Routing ist aktiv, aber local_subnet ist leer."
        exit 1
    fi

    if [ -z "${LAN_INTERFACE}" ]; then
        bashio::log.error "Subnet-Routing ist aktiv, aber lan_interface ist leer."
        exit 1
    fi

    if ! ip link show "${LAN_INTERFACE}" >/dev/null 2>&1; then
        bashio::log.error "LAN-Interface ${LAN_INTERFACE} wurde nicht gefunden."
        exit 1
    fi
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

bashio::log.info "VPN-Adresse    : ${VPN_ADDRESS}"
bashio::log.info "Endpoint       : ${ENDPOINT}"
bashio::log.info "Allowed IPs    : ${ALLOWED_IPS}"
bashio::log.info "MTU            : ${MTU}"
bashio::log.info "Keepalive      : ${KEEPALIVE}"
bashio::log.info "Subnet-Routing : ${SUBNET_ROUTING}"

# ----------------------------------------------------------
# Vorhandenes wg0 entfernen
# ----------------------------------------------------------

if ip link show wg0 >/dev/null 2>&1; then
    bashio::log.warning "