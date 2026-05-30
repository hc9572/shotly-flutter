# Android Release Signing

`android/app/build.gradle.kts` reads `android/key.properties` when present.

Example `android/key.properties` (do not commit):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=shotly
storeFile=app/shotly-release.jks
```

Generate keystore when ready:

```bash
keytool -genkey -v \
  -keystore android/app/shotly-release.jks \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias shotly
```

Build Play bundle:

```bash
flutter build appbundle --flavor prod --release
```

Output:

```text
build/app/outputs/bundle/prodRelease/app-prod-release.aab
```
