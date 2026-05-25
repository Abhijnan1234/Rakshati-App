# Rakshati Mobile

## Run With Local Backend

Android emulator:

```bash
flutter pub get
flutter run --dart-define=NETWORK_BASE_URL=http://10.0.2.2:5000
```

Physical Android device on the same Wi-Fi:

```bash
flutter run --dart-define=NETWORK_BASE_URL=http://YOUR_PC_IP:5000
```

Render-hosted backend:

```bash
flutter run --dart-define=NETWORK_BASE_URL=https://your-backend.onrender.com
```

If Google Sign-In is enabled, also pass:

```bash
flutter run --dart-define=NETWORK_BASE_URL=https://your-backend.onrender.com --dart-define=GOOGLE_SERVER_CLIENT_ID=your_google_web_client_id.apps.googleusercontent.com
```

## Required Dart Defines

- `NETWORK_BASE_URL`
- `GOOGLE_SERVER_CLIENT_ID` for Google Sign-In

## Important Firebase Notes

- `mobile/android/app/google-services.json` must target `com.abhijnan.rakshati`
- the Firebase Android app package must also be `com.abhijnan.rakshati`
- `GOOGLE_SERVER_CLIENT_ID` must be the Google web client ID, not the Android client ID
