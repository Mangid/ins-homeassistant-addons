# INS WireGuard Client

Home Assistant App für den zentralen Fernwartungszugriff von INS-Energietechnik.

## Funktionen

- WireGuard Client für Home Assistant OS
- Split-Tunneling
- Optionales Subnet-Routing
- Zugriff auf Geräte im entfernten Kundennetz
- NAT/MASQUERADE für Kundennetze
- Unterstützung für ARM64 und AMD64
- Automatische Diagnoseausgaben
- Keine produktiven Schlüssel im Repository

## Architektur

```text
INS Admin
    |
    | WireGuard
    v
Zentraler VPN-Server
    |
    | WireGuard
    v
Kundenstandort
    |
    +---- Home Assistant
    +---- Heizungssteuerung
    +---- Smartmeter
    +---- Wechselrichter
    +---- weitere Netzwerkgeräte