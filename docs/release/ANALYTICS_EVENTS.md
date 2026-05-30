# Shotly Analytics Events

Shotly uses only privacy-safe product events. Analytics is currently disabled in code (`ShotlyAnalytics.enabled = false`) until a provider is selected.

## Allowed events

- `app_open`
- `photo_permission_granted`
- `photo_permission_denied`
- `screen_analysis_started`
- `screen_analysis_completed`
- `screen_analysis_failed`
- `backup_exported`
- `backup_imported`
- `delete_original_requested`
- `delete_original_succeeded`
- `delete_original_failed`

## Never log

Do not send or store:

- screenshots, thumbnails, image bytes, OCR/text content
- file names, file paths, MediaStore IDs, image IDs
- folder names, stack names, memos
- search queries
- raw touch coordinates or gesture trails
- precise timestamps tied to a specific screenshot

## Provider rule

If Firebase Analytics, Crashlytics, or custom server logs are added later, keep payloads aggregate-only and update Privacy Policy + Google Play Data Safety before release.
