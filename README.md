# Mark-it

Flutter Android app for adding watermarks, camera brand logos, EXIF-based text, and frame styles to photos. Supports gallery and camera import, RAW file picking, share-to-app, bulk processing, and saving exports to the device gallery.

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel). This project targets Dart SDK `^3.11.4` as declared in `pubspec.yaml`.
- Android toolchain: Android SDK, platform tools, and a configured device or emulator. Run `flutter doctor` and resolve any reported issues.
- JDK 17 (or the version required by your Android Gradle Plugin; Android Studio bundles a suitable JDK).

Optional but recommended:

- [Android Studio](https://developer.android.com/studio) with the Flutter and Dart plugins for debugging and SDK management.

## Clone the repository

```bash
git clone https://github.com/EntroproxTheOne/Mark-it.git
cd Mark-it
```

## Install dependencies

```bash
flutter pub get
```

Regenerate launcher icons or native splash only if you change `pubspec.yaml` branding sections:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Verify your environment

```bash
flutter doctor -v
```

Fix any items marked as errors before building.

## Run in debug mode (USB device or emulator)

1. Connect a device with USB debugging enabled, or start an Android Virtual Device.
2. From the project root:

```bash
flutter run
```

Flutter builds a debug APK, installs it on the selected device, and attaches the debugger.

To target a specific device:

```bash
flutter devices
flutter run -d <device_id>
```

## Build a release APK

From the project root:

```bash
flutter build apk --release
```

Output (single universal APK, larger):

`build/app/outputs/flutter-apk/app-release.apk`

Recommended for smaller per-CPU downloads:

```bash
flutter build apk --release --split-per-abi
```

Outputs:

- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (32-bit ARM)
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (64-bit ARM; typical for modern phones)
- `build/app/outputs/flutter-apk/app-x86_64-release.apk` (emulators / some tablets)

Install the file that matches your device architecture (most phones use `arm64-v8a`).

## Install the release APK on a physical device

1. Copy the chosen `.apk` to the phone (USB file transfer, cloud storage, or `adb`).
2. On the phone, open the file with a file manager and tap it to install.
3. If prompted, allow installation from the source you used (browser, files app, or USB).
4. Alternatively, with USB debugging enabled:

```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Use `-r` to replace an existing install. Adjust the path if you built without `--split-per-abi`.

## Project layout (high level)

- `lib/` — Dart application code (`main.dart`, `lib/src/...`)
- `android/` — Android host project (Gradle, manifest, Kotlin `MainActivity`)
- `assets/` — Fonts, logos, Lottie animations, launcher/splash source image
- `pubspec.yaml` — Dependencies, assets, `flutter_launcher_icons` and `flutter_native_splash` configuration

## Troubleshooting

- **`flutter` not found:** Add the Flutter `bin` directory to your system `PATH`, or invoke it with the full path to `flutter.bat` (Windows) or `flutter` (macOS/Linux).
- **Gradle or SDK errors:** Open `android/` in Android Studio once and let it sync; install missing SDK platforms/build-tools from the SDK Manager.
- **Signing for Play Store:** Configure signing in `android/app/build.gradle.kts` (or `build.gradle`) with your keystore; the default debug/release setup is for local installs unless you add your own signing config.
