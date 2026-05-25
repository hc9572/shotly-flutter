# Shotly Flutter

Shotly is a local-first screenshot organization app for planners, PMs, UX designers, and researchers.

## Web preview

The web build uses mock screenshot data because browser builds cannot access Android MediaStore or iOS Photos.

After GitHub Pages deploys, preview URL:

https://hc9572.github.io/shotly-flutter/


## Smart Clean behavior

Smart Clean runs locally on the device inside the current app/stack detail screen.

Current rules:

- An analysis request considers every screenshot in that app stack, not a 10-minute window and not a fixed image-count sample.
- Screenshots already assigned to folders stay assigned and are not treated as new grouping targets.
- Existing folders are compared through their newest screenshot as the representative image, so small recent UI changes are prioritized.
- New/unassigned screenshots are compared against existing folder representatives first, then against each other for duplicate or similar-flow candidates.
- Feature extraction is batched and cached in memory, and the heavier grouping work runs off the UI isolate so the app should remain usable while analysis is running.
- There is no fixed Smart Clean wall-clock timeout; unreadable thumbnails are skipped instead of failing the full analysis.

Developer verification used for the current main version:

```bash
flutter analyze
flutter test
flutter run -d R3CY302237D --debug
```

Connected Android smoke evidence: Smart Clean completed a 14-image stack in 838 ms after feature extraction batching.

## Local development

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

## Android build

```bash
flutter build apk --debug
```

Android native bridge lives in `android/app/src/main/kotlin/com/shotly/shotly_app/MainActivity.kt`.
