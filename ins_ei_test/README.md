# INS-EI TEST

Dedicated development/test Home Assistant App for INS-EI.

**Never use this App as the production release channel.**

The TEST App has its own slug and persistent `/data`, separate from `INS-EI V1`.

Promotion rule: a Core SHA may enter the PROD app only after TEST has passed startup, setup, plugin discovery, persistence, restart and recovery checks.
