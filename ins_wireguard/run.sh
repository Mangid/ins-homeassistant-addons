#!/usr/bin/with-contenv bashio

VERSION="0.3.3"

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
# Hilfsfunktionen
# ----------------------------------------------------------

log_separator() {
    bashio::log.info "=========================================="
}

# Erste nutzbare Test-IP aus einem /24-Netz ableiten.
# Beispiel: 192.168.0.0/24 -> 192.168.0.1
get_test_ip() {
    local subnet="$1"

    if echo "${subnet}" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.0/24$'; then
        echo "${subnet}" | sed -E 's/\.0\/24$/.1/'
    else
        echo ""
    fi
}

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

        bashio::log.info "Verfügbare Interfaces:"
        ip -br link || true

        exit 1
    fi
fi

# ----------------------------------------------------------
# Diagnose VOR WireGuard
# ----------------------------------------------------------

log_separator
bashio::log.info "System-/Netzwerkdiagnose vor WireGuard"
log_separator

bashio::log.info "Interfaces:"
ip -br addr || true

bashio::log.info "Routing-Tabelle:"
ip route show || true

bashio::log.info "Policy-Routing:"
ip rule show || true

bashio::log.info "Netzwerk-Namespace:"
readlink /proc/self/ns/net || true

if [ "${SUBNET_ROUTING}" = "true" ]; then
    bashio::log.info "LAN-Interface ${LAN_INTERFACE}:"
    ip addr show dev "${LAN_INTERFACE}" || true

    bashio::log.info "Route zum lokalen Netz ${LOCAL_SUBNET}:"
    ip route show "${LOCAL_SUBNET}" || true
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

log_separator
bashio::log.info "Starte WireGuard"
log_separator

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

    log_separator
    bashio::log.info "Aktiviere Subnet-Routing"
    log_separator

    IP_FORWARD=$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null || echo "unbekannt")

    bashio::log.info "IPv4 Forwarding: ${IP_FORWARD}"

    if [ "${IP_FORWARD}" != "1" ]; then
        bashio::log.warning "IPv4 Forwarding ist nicht aktiv."
        bashio::log.warning "Subnet-Routing kann dadurch eingeschränkt sein."
    fi

    # Alte identische Regeln entfernen
    while iptables -D FORWARD \
        -i wg0 \
        -o "${LAN_INTERFACE}" \
        -d "${LOCAL_SUBNET}" \
        -j ACCEPT 2>/dev/null; do
        :
    done

    while iptables -D FORWARD \
        -i "${LAN_INTERFACE}" \
        -o wg0 \
        -s "${LOCAL_SUBNET}" \
        -m conntrack \
        --ctstate ESTABLISHED,RELATED \
        -j ACCEPT 2>/dev/null; do
        :
    done

    while iptables -t nat -D POSTROUTING \
        -s 10.10.0.0/24 \
        -d "${LOCAL_SUBNET}" \
        -o "${LAN_INTERFACE}" \
        -j MASQUERADE 2>/dev/null; do
        :
    done

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
# Diagnose NACH WireGuard
# ----------------------------------------------------------

sleep 3

log_separator
bashio::log.info "WireGuard Status"
log_separator

wg show wg0 || true

log_separator
bashio::log.info "Netzwerkdiagnose nach WireGuard"
log_separator

bashio::log.info "Interfaces:"
ip -br addr || true

bashio::log.info "Routing-Tabelle:"
ip route show || true

bashio::log.info "Policy-Routing:"
ip rule show || true

bashio::log.info "Route zum WireGuard-Server:"
SERVER_IP=$(echo "${ENDPOINT}" | sed 's/:[0-9]*$//')
ip route get "${SERVER_IP}" || true

if [ "${SUBNET_ROUTING}" = "true" ]; then

    TEST_IP=$(get_test_ip "${LOCAL_SUBNET}")

    log_separator
    bashio::log.info "Subnet-Routing Diagnose"
    log_separator

    bashio::log.info "IPv4 Forwarding:"
    cat /proc/sys/net/ipv4/ip_forward || true

    bashio::log.info "wg0:"
    ip addr show dev wg0 || true

    bashio::log.info "${LAN_INTERFACE}:"
    ip addr show dev "${LAN_INTERFACE}" || true

    bashio::log.info "Route zum lokalen Netz:"
    ip route show "${LOCAL_SUBNET}" || true

    if [ -n "${TEST_IP}" ]; then
        bashio::log.info "Kernel-Route zu Test-IP ${TEST_IP}:"
        ip route get "${TEST_IP}" || true

        bashio::log.info "Ping zu Test-IP ${TEST_IP}:"
        ping -c 3 -W 2 "${TEST_IP}" || true
    else
        bashio::log.warning "Automatische Test-IP nur für /24-Netze verfügbar."
    fi

    bashio::log.info "FORWARD Regeln:"
    iptables -L FORWARD -n -v --line-numbers || true

    bashio::log.info "NAT Regeln:"
    iptables -t nat -L POSTROUTING -n -v --line-numbers || true

    bashio::log.info "iptables Backend:"
    iptables --version || true

    if command -v nft >/dev/null 2>&1; then
        bashio::log.info "nftables ist verfügbar."
        nft list ruleset 2>/dev/null | head -n 200 || true
    else
        bashio::log.info "nft Kommando ist nicht verfügbar."
    fi
fi

log_separator
bashio::log.info "INS WireGuard Client läuft"
log_separator

while true; do
    sleep 3600
done