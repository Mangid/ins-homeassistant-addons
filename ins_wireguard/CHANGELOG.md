# Changelog

## 0.3.2

### Added
- Optionales Subnet-Routing für Kundennetze
- Konfigurierbares lokales Kundennetz
- Konfigurierbares LAN-Interface
- IPv4-Forwarding-Prüfung
- Automatische FORWARD-Regeln für Kundennetze
- NAT/MASQUERADE für Zugriffe aus dem INS-VPN
- Diagnoseausgabe für Routing, Firewall und NAT

### Fixed
- Subnet-Routing unter Home Assistant OS
- Kein Schreibzugriff auf `/proc/sys/net/ipv4/ip_forward` mehr erforderlich
- Bash-Syntaxprüfung bereits während des Docker-Builds

### Tested
- WireGuard-Tunnel über Home Assistant OS
- Zugriff auf Home Assistant im entfernten LAN
- Zugriff auf weitere Geräte im entfernten LAN
- Split-Tunneling
- Persistente serverseitige Routing- und Firewall-Konfiguration

## 0.2.5

- Produktiver WireGuard-Tunnel erfolgreich implementiert
- WireGuard-Status und Routing-Diagnose ergänzt

## 0.2.4

- BashIO-Logging korrigiert
- Runtime-Diagnose ergänzt

## 0.2.1

- Home-Assistant-Build-Konfiguration korrigiert

## 0.1.0

- Erste lokale Testversion