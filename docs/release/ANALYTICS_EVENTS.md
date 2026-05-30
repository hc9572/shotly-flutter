# Shotly Analytics Events

Shotly uses only privacy-safe product events. Firebase Analytics and Crashlytics are enabled for Android release builds using `ShotlyAnalytics` allowlisted events.

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

Firebase Analytics and Crashlytics payloads must remain aggregate-only. Update Privacy Policy + Google Play Data Safety before every release if new providers or event parameters are added.
