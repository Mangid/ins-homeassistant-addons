# INS WireGuard Client

Home Assistant App für den zentralen Fernzugriff von INS-Energietechnik.

## Funktion

Die App verbindet eine Home-Assistant-Installation als WireGuard-Client mit dem zentralen INS-WireGuard-Server.

## Netzwerk

Zentraler WireGuard-Server:

- Endpoint: `13.140.162.147:51820`
- VPN-Netz: `10.10.0.0/24`

Jede Kundeninstallation erhält eine eigene WireGuard-IP.

Beispiel:

- INS Laptop: `10.10.0.2`
- Kaufmann: `10.10.0.10`

## Sicherheit

Private WireGuard-Schlüssel werden nicht im Repository gespeichert.

Der Client Private Key wird ausschließlich über die lokale App-Konfiguration der jeweiligen Home-Assistant-Installation hinterlegt.

## Status

Version 0.2.0

Aktuell:
- WireGuard Client
- Split-Tunneling
- ARM64 und AMD64

Geplant:
- Handshake-Überwachung
- Subnet-Routing
- Diagnose
- Verbindungsstatus