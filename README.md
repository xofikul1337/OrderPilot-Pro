# OrderPilot Pro

OrderPilot Pro is a Flutter app for WooCommerce order notifications, staff order viewing, and seen-status tracking through the OrderPilot WordPress plugin, Cloudflare Worker, D1, and OneSignal.

## Features

- Connects with a store code from the WordPress plugin.
- Receives WooCommerce order notifications.
- Shows new/seen order tabs.
- Tracks order seen state, seen staff name, and seen time through the backend.
- Includes Home, Settings, and Developer screens with swipe navigation.
- Uses a branded app icon and splash screen.

## Run From VS Code

Install Flutter stable, Android SDK, and the Flutter extension for VS Code. Then clone this repository and run:

```powershell
flutter pub get
flutter doctor
flutter run
```

Select an Android emulator or USB-connected Android device from VS Code before running the app.

## Release Build

This project supports release signing from `android/key.properties`.

Required local files:

- `android/key.properties`
- `android/app/orderpilot-release.jks`

These files are intentionally ignored by Git. Keep a private backup of them. If the keystore is lost, future APK updates cannot be signed with the same app identity.

Build the small Android APKs with:

```powershell
flutter build apk --release --obfuscate --split-debug-info=symbols --target-platform android-arm,android-arm64 --split-per-abi
```

Samsung Galaxy A02s and many older Android phones should use:

```text
build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
```

Modern 64-bit phones can use:

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## Backend Notes

The private Cloudflare Worker and WordPress plugin sources are kept in the local `Website Code/` folder and are intentionally excluded from this app repository. The live Worker currently uses Cloudflare D1 for app data and KV only for license dashboard data.
