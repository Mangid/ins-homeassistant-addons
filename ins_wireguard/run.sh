#!/usr/bin/with-contenv bashio

VERSION="0.3.2"

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

if [ "${SUBNET_ROUTING}" = "true" ]; then
    bashio::log.info "Lokales Netz   : ${LOCAL_SUBNET}"
    bashio::log.info "LAN-Interface  : ${LAN_INTERFACE}"
fi

# ----------------------------------------------------------
# Vorhandenes wg0 entfernen
# ----------------------------------------------------------

if ip link show wg0 >/dev/null 2>&1; then
    bashio::log.warning "wg0 existiert bereits und wird neu gestartet."
    wg-quick down /etc/wireguard/wg0.conf || true
fi

# ----------------------------------------------------------
# WireGuard starten
# ----------------------------------------------------------

bashio::log.info "=========================================="
bashio::log.info "Starte WireGuard"
bashio::log.info "=========================================="

if wg-quick up /etc/wireguard/wg0.conf; then
    bashio::log.info "WireGuard-Interface wg0 erfolgreich gestartet."
else
    bashio::log.error "WireGuard konnte nicht gestartet werden."
    exit 1
fi

# ----------------------------------------------------------
# Optionales Subnet-Routing
# ----------------------------------------------------------

if [ "${SUBNET_ROUTING}" = "true" ]; then

    bashio::log.info "=========================================="
    bashio::log.info "Aktiviere Subnet-Routing"
    bashio::log.info "=========================================="

    IP_FORWARD=$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo "unbekannt")

    bashio::log.info "IPv4 Forwarding: ${IP_FORWARD}"

    if [ "${IP_FORWARD}" != "1" ]; then
        bashio::log.warning "IPv4 Forwarding ist nicht aktiv."
        bashio::log.warning "Subnet-Routing kann dadurch eingeschränkt sein."
    fi

    # Alte identische Regeln entfernen
    iptables -D FORWARD \
        -i wg0 \
        -o "${LAN_INTERFACE}" \
        -d "${LOCAL_SUBNET}" \
        -j ACCEPT 2>/dev/null || true

    iptables -D FORWARD \
        -i "${LAN_INTERFACE}" \
        -o wg0 \
        -s "${LOCAL_SUBNET}" \
        -m conntrack \
        --ctstate ESTABLISHED,RELATED \
        -j ACCEPT 2>/dev/null || true

    iptables -t nat -D POSTROUTING \
        -s 10.10.0.0/24 \
        -d "${LOCAL_SUBNET}" \
        -o "${LAN_INTERFACE}" \
        -j MASQUERADE 2>/dev/null || true

    # INS-VPN -> Kundennetz
    iptables -I FORWARD 1 \
        -i wg0 \
        -o "${LAN_INTERFACE}" \
        -d "${LOCAL_SUBNET}" \
        -j ACCEPT

    # Antwortverkehr Kundennetz -> INS-VPN
    iptables -I FORWARD 1 \
        -i "${LAN_INTERFACE}" \
        -o wg0 \
        -s "${LOCAL_SUBNET}" \
        -m conntrack \
        --ctstate ESTABLISHED,RELATED \
        -j ACCEPT

    # NAT für INS-Zugriffe ins Kundennetz
    iptables -t nat -I POSTROUTING 1 \
        -s 10.10.0.0/24 \
        -d "${LOCAL_SUBNET}" \
        -o "${LAN_INTERFACE}" \
        -j MASQUERADE

    bashio::log.info "Subnet-Routing-Regeln erfolgreich eingerichtet."

fi

# ----------------------------------------------------------
# Status
# ----------------------------------------------------------

sleep 3

bashio::log.info "=========================================="
bashio::log.info "WireGuard Status"
bashio::log.info "=========================================="

wg show wg0 || true

bashio::log.info "=========================================="
bashio::log.info "Routing"
bashio::log.info "=========================================="

ip route show | grep -E 'wg0|10\.10\.' || true

if [ "${SUBNET_ROUTING}" = "true" ]; then

    bashio::log.info "=========================================="
    bashio::log.info "Subnet-Routing Status"
    bashio::log.info "=========================================="

    bashio::log.info "IPv4 Forwarding:"
    cat /proc/sys/net/ipv4/ip_forward || true

    bashio::log.info "FORWARD Regeln:"
    iptables -L FORWARD -n -v || true

    bashio::log.info "NAT Regeln:"
    iptables -t nat -L POSTROUTING -n -v || true

fi

bashio::log.info "=========================================="
bashio::log.info "INS WireGuard Client läuft"
bashio::log.info "=========================================="

while true; do
    sleep 3600
done