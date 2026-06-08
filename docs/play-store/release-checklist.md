# Play Store Release Checklist

## Required Before Submission

- Publish the Privacy Policy URL publicly:
  `https://sukunaat.com/orderpilot-pro/privacy-policy/`
- Add the same Privacy Policy URL in Play Console.
- Complete Data safety using `docs/play-store/data-safety.md`.
- Complete App access using `docs/play-store/app-access.md`.
- Confirm demo Store ID `889123` works for reviewers.
- Upload Android App Bundle `.aab`, not APK.
- Use Play App Signing.
- Add screenshots: phone screenshots required; tablet optional if supported.
- Add app icon, feature graphic, short description, full description.
- Set content rating questionnaire.
- Select target audience: business/staff users, not children.
- Confirm ads: No, unless ads are added later.
- Confirm permissions:
  - Internet: required for store API and notifications.
  - Notifications: required for new order alerts.
  - Receive boot completed: required to keep notification support after restart.
  - Vibrate: notification vibration.
  - Access network state: proxy/VPN security check.

## Current App Notes

- Package name: `com.orderPilotPro.orders`
- App version: `1.3.1+23`
- App creates no public consumer account.
- Store/order data lives in each merchant's WordPress database.

## Google Policy Notes Checked

- Google requires all apps to provide a privacy policy link in Play Console and inside the app.
- Google requires a Data safety section.
- From August 31, 2025, new apps and updates submitted to Google Play must target Android 15 / API 35 or higher.

## Build Command

```powershell
flutter build appbundle --release
```

Output:

```text
build/app/outputs/bundle/release/app-release.aab
```
