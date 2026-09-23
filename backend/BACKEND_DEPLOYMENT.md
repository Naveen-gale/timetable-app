# TTAPP Backend — Render Deployment Guide

This guide walks you through pushing the backend to GitHub and deploying it to Render as a Web Service.

---

## Prerequisites

- A [GitHub](https://github.com) account with the `timetable-app` repository
- A [Render](https://render.com) account (free tier works)
- Fresh credentials (rotate before deploying — see Security note below)

> **SECURITY — ROTATE CREDENTIALS FIRST**
> The credentials previously shared in chat are compromised.
> Before deploying, generate new ones:
> - **MongoDB**: Create a new Atlas database user with a new password
> - **ImageKit**: Regenerate the private key in the ImageKit dashboard
> - **JWT secret**: Generate with `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"`

---

## Step 1 — Verify `.gitignore`

Make sure `backend/.env` is NOT committed.

```bash
# From the repo root
cat backend/.gitignore
```

You should see `.env` listed. If `backend/.env` is already tracked, remove it:

```bash
git rm --cached backend/.env
```

---

## Step 2 — Push to GitHub

```bash
# From the repo root (timetable-app/)
git add backend/
git commit -m "feat: add Node.js backend (Phase 1)"
git push origin main
```

Confirm on GitHub that:
- `backend/.env` does **NOT** appear in the repository
- `backend/.env.example` **IS** there (placeholders only)
- `backend/node_modules/` is **NOT** there

---

## Step 3 — Create a Render Web Service

1. Log in to [https://dashboard.render.com](https://dashboard.render.com)
2. Click **New +** → **Web Service**
3. Choose **Build and deploy from a Git repository**
4. Click **Connect** next to your `timetable-app` repository

---

## Step 4 — Configure the Web Service

Fill in the fields exactly as shown:

| Field | Value |
|-------|-------|
| **Name** | `timetable-backend` (or any name you like) |
| **Region** | Closest to your users (e.g. Singapore for India) |
| **Branch** | `main` |
| **Root Directory** | `backend` |
| **Runtime** | `Node` |
| **Build Command** | `npm install` |
| **Start Command** | `npm start` |
| **Instance Type** | Free (or Starter for always-on) |

> **Root Directory is critical.**
> The repository contains both the Flutter app and the backend.
> Setting Root Directory to `backend` tells Render to treat that folder as the project root.
> Render will run `npm install` and `npm start` from inside `backend/`.

---

## Step 5 — Add Environment Variables

In the Render dashboard, go to your service → **Environment** tab → **Add Environment Variable**.

Add each variable with its **new, rotated** value:

| Key | Value |
|-----|-------|
| `PORT` | `10000` |
| `NODE_ENV` | `production` |
| `MONGODB_URI` | `mongodb+srv://YOUR_NEW_USER:YOUR_NEW_PASS@cluster0.xxxxx.mongodb.net/timetable?retryWrites=true&w=majority` |
| `IMAGEKIT_PRIVATE_KEY` | `private_YOURNEWKEY` |
| `IMAGEKIT_PUBLIC_KEY` | `public_YOURNEWKEY` |
| `IMAGEKIT_URL_ENDPOINT` | `https://ik.imagekit.io/YOURID` |
| `JWT_SECRET` | `<64-char random hex string>` |

> Render automatically injects `PORT` at runtime.
> You still need to add it manually here so local references are consistent.
> The backend reads `process.env.PORT` with a fallback to `10000`.

---

## Step 6 — Deploy

1. Click **Create Web Service**
2. Render will clone your repo, run `npm install`, then `npm start`
3. Watch the **Logs** tab for startup messages

### Expected startup logs

```
[DB] MongoDB connected: cluster0.xxxxx.mongodb.net
[Server] TTAPP backend running on port 10000
[Server] Environment: production
[Server] Health check: http://localhost:10000/health
```

### Common startup errors and fixes

| Log message | Cause | Fix |
|-------------|-------|-----|
| `MONGODB_URI is not set` | Missing env var | Add `MONGODB_URI` in Render Environment tab |
| `MongoServerError: bad auth` | Wrong MongoDB password | Rotate Atlas password, update Render env var |
| `Cannot find module 'express'` | Build failed | Check Build Command is `npm install` and Root Directory is `backend` |
| `Error: listen EADDRINUSE` | Port conflict | Not possible on Render — each service gets its own port |
| Server starts but `/health` 502 | Still cold-starting | Wait 30–60 s then retry |

---

## Step 7 — Verify MongoDB Connection

In Render logs you should see:

```
[DB] MongoDB connected: cluster0.xxxxx.mongodb.net
```

If you see a connection timeout:
- Go to MongoDB Atlas → **Network Access** → Add IP `0.0.0.0/0` (allow all, for Render)
- Or use Render's static IP feature and whitelist only that IP (Starter plan+)

---

## Step 8 — Test the Health Endpoint

Copy your Render service URL from the dashboard (top of the page). It looks like:

```
https://timetable-backend.onrender.com
```

Test it:

```bash
curl https://timetable-backend.onrender.com/health
```

Expected response:

```json
{
  "success": true,
  "message": "Backend is running"
}
```

> **Free tier note**: On the free Render tier, the service spins down after 15 minutes of inactivity.
> The first request after a sleep may take 30–60 seconds. This is normal.
> Consider upgrading to the Starter plan ($7/month) for always-on behaviour.

---

## Step 9 — Give Me the Render URL

Once `/health` returns `{ "success": true, "message": "Backend is running" }`, copy the full HTTPS URL:

```
https://YOUR-SERVICE-NAME.onrender.com
```

Send that URL to me and we will proceed with **Phase 2** — connecting the Flutter APK.

---

## Step 10 — MongoDB Atlas Network Access (if blocked)

If MongoDB connection fails from Render:

1. Log in to [https://cloud.mongodb.com](https://cloud.mongodb.com)
2. Go to **Network Access**
3. Click **Add IP Address**
4. Choose **Allow Access from Anywhere** (`0.0.0.0/0`)
5. Click **Confirm**
6. Wait ~30 seconds then redeploy on Render

---

## Render Environment Variable Reference

```
PORT=10000
NODE_ENV=production
MONGODB_URI=mongodb+srv://USER:PASS@CLUSTER.mongodb.net/timetable?retryWrites=true&w=majority
IMAGEKIT_PRIVATE_KEY=private_...
IMAGEKIT_PUBLIC_KEY=public_...
IMAGEKIT_URL_ENDPOINT=https://ik.imagekit.io/...
JWT_SECRET=<64+ char random string>
```
