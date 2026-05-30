# Shotly Phone Transfer MVP

Goal: make backup/restore understandable for non-technical users.

## User flow

### Old phone

1. Settings → Phone transfer → Transfer to new phone.
2. Shotly creates a temporary local HTTP transfer session.
3. Shotly shows a QR code.
4. The session stays alive only while the QR screen is open.

### New phone

1. Settings → Phone transfer → Scan QR to import.
2. Scan the QR shown on the old phone.
3. Shotly downloads the backup JSON directly from the old phone over the same Wi‑Fi.
4. Current Shotly organization data is replaced with the transferred data.

## Privacy/security

- Original images are not transferred.
- QR contains only a temporary local URL with a random token.
- Transfer works over local Wi‑Fi; no Shotly server is used.
- Closing the QR screen stops the transfer server.
- The transfer token is random per session and not persisted.

## Limitations

- Both phones must be on the same Wi‑Fi/local network.
- Some public/corporate Wi‑Fi networks block device-to-device traffic.
- Android cleartext local HTTP is enabled for this MVP because the transfer is local-only.
- File export/import remains as a fallback recovery path.
