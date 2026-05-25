# Deploy Rakshati Backend To Render

This guide deploys only the Node.js backend from the `backend/` directory.

## 1. Create A Render Account

1. Go to [Render](https://render.com).
2. Sign in or create an account.
3. Connect your GitHub account.

## 2. Connect The Repository

1. Push this repository to GitHub.
2. In Render, choose `New +`.
3. Select `Web Service`.
4. Choose the `Rakshati` repository.

## 3. Render Service Settings

Use these exact values:

- Name: `rakshati-backend`
- Environment: `Node`
- Region: choose the closest region to your testers
- Branch: your deployment branch, usually `main`
- Root Directory: `backend`
- Build Command: `npm install && npm run build`
- Start Command: `npm start`
- Health Check Path: `/health`

## 4. Environment Variables

Add these variables in Render:

- `MONGODB_URI=your_mongodb_atlas_connection_string`
- `JWT_SECRET=replace_with_a_long_random_secret`
- `NODE_ENV=production`
- `GOOGLE_CLIENT_ID=your_google_web_client_id.apps.googleusercontent.com`

Notes:

- Do not hardcode secrets in the repository.
- Render provides `PORT` automatically. The backend already supports `process.env.PORT` with fallback `5000` for local development.

## 5. Deploy

1. Click `Create Web Service`.
2. Wait for the build and startup to complete.
3. Open the deployed URL after Render finishes.

## 6. Verify Health Endpoint

Open:

```text
https://YOUR_RENDER_URL.onrender.com/health
```

Expected response:

```json
{
  "status": "ok",
  "service": "rakshati-backend"
}
```

The response may also include a timestamp.

## 7. Connect Flutter To Render

Run the mobile app with:

```bash
flutter run --dart-define=NETWORK_BASE_URL=https://YOUR_RENDER_URL.onrender.com
```

If Google Sign-In is used:

```bash
flutter run --dart-define=NETWORK_BASE_URL=https://YOUR_RENDER_URL.onrender.com --dart-define=GOOGLE_SERVER_CLIENT_ID=your_google_web_client_id.apps.googleusercontent.com
```
