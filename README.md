# Rakshati

Rakshati is a Flutter mobile app and Node.js + Express backend for women-focused safety workflows, authentication, live location mapping, saved places, and connection management.

## Repository Structure

```text
backend/   Express + TypeScript API
mobile/    Flutter application
infra/     Infrastructure-related local files
```

No standalone website application directory was found during this audit, and no existing non-mobile web assets were removed.

## Backend

Location: `backend/`

Available scripts:

- `npm run build` compiles TypeScript to `dist/`
- `npm run dev` starts the backend in local watch mode
- `npm start` runs the compiled production build

Create `backend/.env` from `backend/.env.example`:

```env
PORT=5000
MONGODB_URI=your_mongodb_atlas_connection_string
JWT_SECRET=replace_with_a_long_random_secret
NODE_ENV=development
GOOGLE_CLIENT_ID=your_google_web_client_id.apps.googleusercontent.com
```

Run locally:

```bash
cd backend
npm install
npm run build
npm run dev
```

Health endpoints:

- `GET /ping`
- `GET /health`

## Mobile

Location: `mobile/`

Android package name:

- `com.abhijnan.rakshati`

Local emulator run:

```bash
cd mobile
flutter pub get
flutter run --dart-define=NETWORK_BASE_URL=http://10.0.2.2:5000
```

Production-style or LAN run:

```bash
flutter run --dart-define=NETWORK_BASE_URL=https://your-backend.onrender.com
```

If you test with a physical phone on the same Wi-Fi as your PC, replace the URL with your machine LAN address:

```bash
flutter run --dart-define=NETWORK_BASE_URL=http://YOUR_PC_IP:5000
```

If you use Google Sign-In, also pass:

```bash
--dart-define=GOOGLE_SERVER_CLIENT_ID=your_google_web_client_id.apps.googleusercontent.com
```

## Environment Variables

Backend variables:

- `PORT`: Express port. Defaults to `5000` if not provided.
- `MONGODB_URI`: MongoDB Atlas connection string.
- `JWT_SECRET`: JWT signing secret. Must be at least 16 characters.
- `NODE_ENV`: `development`, `test`, or `production`.
- `GOOGLE_CLIENT_ID`: Google web client ID for backend token verification.

Flutter dart-defines:

- `NETWORK_BASE_URL`: Base URL for the backend API.
- `GOOGLE_SERVER_CLIENT_ID`: Google web client ID for Flutter Google Sign-In.

## Render Deployment

Render deployment details are documented in [DEPLOY_RENDER.md](/F:/rakhshati/DEPLOY_RENDER.md).

Recommended Render settings:

- Root Directory: `backend`
- Build Command: `npm install && npm run build`
- Start Command: `npm start`
- Health Check Path: `/health`

## Verification Commands

```bash
cd backend
npm install
npm run build

cd ../mobile
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define=NETWORK_BASE_URL=http://10.0.2.2:5000
```
