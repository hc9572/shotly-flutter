# Google Play Data Safety Draft

Current implementation target: paid app, no ads, no IAP/subscription, local-first screenshot organizer.

## Data collection

- Photos/videos: **Not collected by Shotly servers**. App reads local screenshots on device for organization and similar screen analysis.
- Files/docs: Backup export/import is user-initiated local JSON via Android document picker. Phone transfer sends the same backup JSON directly between the user's old and new phones over local Wi‑Fi after QR pairing. Original images are not included.
- App activity / analytics: **Collected** via Firebase Analytics using privacy-safe allowlisted product events only.
- Crash logs/diagnostics: **Collected** via Firebase Crashlytics for stability and troubleshooting.
- Device or other IDs: **May be collected** by Firebase SDKs for analytics/crash reporting identifiers.

## Data sharing

- Firebase processes analytics/crash data as a service provider. Do not upload screenshots, image content, file names, notes, folder names, or search queries.

## Security

- Data is stored locally on device.
- Backup files are saved only when user explicitly exports them.
- Backup includes Shotly organization data only, not original screenshots.

## Permissions

- Photos/images permission: needed to show and organize screenshots.
- Android document picker: used for user-selected backup export/import.
- Camera permission: used to scan Shotly phone-transfer QR codes.
- Internet/local network: used only for direct local Wi‑Fi phone transfer; no Shotly server is contacted for transfer.

## Before Play submission

Answer Data Safety using the Firebase-enabled state: photos/images are accessed locally but not collected; app activity, crash logs/diagnostics, and Firebase identifiers may be collected for analytics, app functionality, and product improvement.
