# INS-EI V1

Standalone INS-EI runtime packaged as a Home Assistant App.

Home Assistant is used as the installation/container platform. INS-EI communicates directly with configured plant devices and does not depend on Home Assistant entities.

## First start

1. Install and start the App.
2. Open **Web UI**.
3. INS-EI starts its first-run Setup Wizard when no Site exists.
4. Configure/test devices.
5. Save the Site.
6. Restart the App.
7. INS-EI starts in Learning/Shadow-oriented default-deny mode.

Persistent Site configuration, Historian and learning data remain under the App's `/data` directory.
