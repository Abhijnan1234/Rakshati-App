# Deploy Rakshati Backend To Render

This guide covers deploying the Node.js backend from `backend/` and configuring the required environment variables safely.

## 1. Create A Render Web Service

1. Sign in to [Render](https://render.com).
2. Connect your GitHub account.
3. Click `New +`.
4. Select `Web Service`.
5. Choose the `Rakshati` repository.

## 2. Render Service Settings

Use these values:

- Name: `rakshati-backend`
- Environment: `Node`
- Root Directory: `backend`
- Build Command: `npm install && npm run build`
- Start Command: `npm start`
- Health Check Path: `/health`

## 3. Environment Variables In Render

In the Render dashboard:

1. Open your `rakshati-backend` service.
2. Go to the `Environment` tab.
3. Add these variables one by one:

- `MONGODB_URI`
- `JWT_SECRET`
- `NODE_ENV`
- `GOOGLE_CLIENT_ID`

Recommended values:

- `NODE_ENV=production`
- `MONGODB_URI=<your MongoDB Atlas connection string>`
- `JWT_SECRET=<your generated production secret>`
- `GOOGLE_CLIENT_ID=<your Google web client id>`

Notes:

- Never paste real secrets into tracked files.
- Render will provide `PORT` automatically.
- The backend already reads configuration from environment variables in `backend/src/config/env.ts`.

## 4. MongoDB Atlas

To obtain the MongoDB connection string:

1. Open MongoDB Atlas.
2. Select your cluster.
3. Click `Connect`.
4. Select `Drivers`.
5. Choose `Node.js`.
6. Copy the connection string.
7. Replace:

- `<username>`
- `<password>`
- `<database>`

Example placeholder format:

```env
MONGODB_URI=mongodb+srv://<username>:<password>@<cluster>.mongodb.net/<database>?retryWrites=true&w=majority
```

## 5. JWT Secret

Generate a strong production secret. Any 32-byte or longer random value is a good baseline.

Examples:

```bash
openssl rand -hex 32
```

```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

```powershell
[Convert]::ToHexString((1..32 | ForEach-Object { Get-Random -Minimum 0 -Maximum 256 }))
```

Use the generated value as:

```env
JWT_SECRET=<generate-a-random-secret-here>
```

## 6. Deploy

1. Click `Create Web Service`.
2. Wait for the build and startup to finish.
3. Open the deployed URL.

## 7. Verify Deployment

Check:

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
