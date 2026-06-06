# OrderPilot Pro

Flutter app for receiving and managing WooCommerce order notifications.

## Run From VS Code

Install Flutter stable, Android SDK, and the Flutter extension for VS Code.
Then clone the repository and run:

```powershell
flutter pub get
flutter doctor
flutter run
```

Select an Android emulator or a USB-connected Android device from VS Code
before running the app.

## Private Backend Sources

The local `Website Code/` directory contains private Cloudflare Worker and
WordPress plugin sources. It is intentionally excluded from this repository.
