# Shotly Flutter

Shotly is a local-first screenshot organization app for planners, PMs, UX designers, and researchers.

## Web preview

The web build uses mock screenshot data because browser builds cannot access Android MediaStore or iOS Photos.

After GitHub Pages deploys, preview URL:

https://hc9572.github.io/shotly-flutter/

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
