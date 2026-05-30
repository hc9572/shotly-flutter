# Google Play Data Safety Draft

Current implementation target: paid app, no ads, no IAP/subscription, local-first screenshot organizer.

## Data collection

- Photos/videos: **Not collected by Shotly servers**. App reads local screenshots on device for organization and similar screen analysis.
- Files/docs: Backup export/import is user-initiated local JSON via Android document picker. Phone transfer sends the same backup JSON directly between the user's old and new phones over local Wi‑Fi after QR pairing. Original images are not included.
- App activity / analytics: **Not currently collected**. Code has a disabled privacy-safe event abstraction for future use.
- Crash logs/diagnostics: **Not currently collected** unless Crashlytics or another provider is added later.

## Data sharing

- No data shared with third parties in current implementation.
- If analytics/crash provider is added, disclose provider processing before release.

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

If `ShotlyAnalytics.enabled` remains false and no analytics/crash SDK is added, answer Data Safety as no collected/shared user data, while explaining local photo access in app permission/store listing text.
