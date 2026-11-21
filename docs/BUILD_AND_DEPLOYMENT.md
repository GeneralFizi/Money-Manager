# Money Manager — Build, Development & Deployment Guide

This runbook covers local setup, Android Studio debugging, production builds across Android/iOS/Web, release signing requirements, OAuth configuration, and CI/CD automation.

---

## 1. Prerequisites

| Tool | Requirement | Notes |
| :--- | :--- | :--- |
| **Flutter SDK** | Stable (bundles Dart `^3.14.0`) | `pubspec.yaml` specifies `sdk: ^3.14.0` |
| **Java JDK** | JDK 17 or JDK 21 | Android Gradle sets `JavaVersion.VERSION_17`; CI uses Temurin JDK 21 |
| **Android SDK** | Configured in `android/local.properties` | `flutter.sdk` and user-writable `sdk.dir` required for Gradle & AVDs |
| **Xcode** (optional) | macOS only | Required for local iOS builds; GitHub Actions handles unsigned `.ipa` builds on `macos-latest` |

Install dependencies and run verification checks from the project root:

```powershell
flutter pub get
flutter analyze
flutter test
```

---

## 2. Running in Android Studio

1. **Install Plugins:** Install the **Flutter** plugin (which bundles **Dart**) under **Settings → Plugins**.
2. **Open Project Root:** Open the repository root folder (the directory containing `pubspec.yaml`, not the `android/` subfolder alone) to enable Flutter Hot Reload.
3. **Target Device Selection:** Ensure the top toolbar device selector targets an **Android Emulator**, physical device, or **Chrome/Edge** — **not** `Windows (desktop)` (the project targets `--platforms=android,ios,web`).
4. **Emulator Performance Tips:**
   - Configure the AVD with **4 GB RAM** (`hw.ramSize=4096`, `vm.heapSize=512`) and host GPU acceleration (`hw.gpu.mode=host`). Cold-boot the AVD after modifying `config.ini`.
   - For faster UI responsiveness in Android Studio, launch in **Profile Mode** (**Run → Flutter Run 'main.dart' in Profile Mode**) or add `--no-enable-impeller` under **Edit Configurations → Additional run args** if emulated OpenGLES stutters.

---

## 3. Release Builds & Packaging

### Android APK (Sideload / Direct Install)

- **Universal APK (ARM + x86_64):**
  ```powershell
  flutter build apk --release
  ```
  Output: `build/app/outputs/flutter-apk/app-release.apk`
- **Per-ABI Split APKs (smaller per-device downloads):**
  ```powershell
  flutter build apk --release --split-per-abi
  ```
  Produces `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, and `app-x86_64-release.apk`.

### Google Play App Bundle (`.aab`)

```powershell
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### Offline-First Web PWA

```powershell
flutter build web --pwa-strategy=offline-first
```
Serve `build/web/` over any static HTTPS host (`manifest.json` sets `"display": "standalone"`, `web/index.html` includes iOS Home Screen `apple-mobile-web-app-*` meta tags).

### iOS (macOS Runner)

```bash
flutter build ios --release --no-codesign
mkdir -p build/ios/ipa/Payload
cp -r build/ios/iphoneos/Runner.app build/ios/ipa/Payload/
cd build/ios/ipa && zip -r MoneyManager-iOS-unsigned.ipa Payload
```

---

## 4. Production Release Checklist

### 4.1 Android Signing Keystore (`android/app/build.gradle.kts`)

> **Important:** `android/app/build.gradle.kts` (`buildTypes.release`) currently uses `signingConfig = signingConfigs.getByName("debug")` so local `flutter run --release` builds install directly.

Before distributing on Google Play or distributing production updates cleanly:
1. Generate a release upload keystore with `keytool`.
2. Add a `release` `signingConfigs` block (reading credentials from an untracked `android/key.properties` file).
3. Update `buildTypes.release` to reference `signingConfigs.getByName("release")`.

### 4.2 Direct Google Drive API OAuth Setup (Optional)

Direct in-app Google Drive API upload/restore (`GoogleDriveService`) requires platform OAuth credentials registered in Google Cloud Console:
1. Enable the **Google Drive API** in a Google Cloud Console project.
2. Configure an OAuth Consent Screen requesting only `https://www.googleapis.com/auth/drive.file`.
3. Create platform OAuth Client IDs:
   - **Android:** Application ID `com.moneymanager.money_manager` + your keystore SHA-1 fingerprint.
   - **iOS:** Bundle ID matching `ios/Runner`.
   - **Web / Custom:** Enter the Web/Server OAuth Client ID inside the app under **Backup → Google OAuth Client ID**.

If OAuth is not configured, users can still use **Share Backup File** (`LocalExportService.shareJsonBackup`) to send JSON backups directly to the Google Drive or Files app using the native OS Share Sheet.

---

## 5. CI/CD Pipeline (`.github/workflows/build-mobile.yml`)

Triggered on pushes to `main`/`master` and manual `workflow_dispatch`:

1. **`test` (`ubuntu-latest`):** Runs `flutter pub get`, `flutter analyze`, and `flutter test`.
2. **`build-android-and-pwa` (`ubuntu-latest`, needs `test`):** Sets up Temurin Java 21, builds `app-release.apk` and the `offline-pwa-web` static bundle, and uploads both as GitHub Actions artifacts (`android-release-apk`, `offline-pwa-web`).
3. **`build-ios` (`macos-latest`, needs `test`):** Runs `flutter build ios --release --no-codesign`, packages `Payload/Runner.app` into `MoneyManager-iOS-unsigned.ipa`, and uploads `ios-unsigned-ipa`.
