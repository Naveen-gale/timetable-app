# TTAPP Backend

Node.js / Express backend for the TTAPP Flutter timetable application.

Provides secure device registration, ImageKit upload authentication, media metadata storage, and contact sync — all backed by MongoDB Atlas.

---

## Stack

| Layer | Technology |
|-------|-----------|
| Runtime | Node.js ≥ 18 |
| Framework | Express 4 |
| Database | MongoDB Atlas (Mongoose 8) |
| Media CDN | ImageKit |
| Auth | JWT (jsonwebtoken) |
| Deployment | Render Web Service |

---

## API Routes

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/health` | None | Liveness check |
| POST | `/api/devices/register` | None | Register or update a device |
| PATCH | `/api/devices/:deviceId/permissions` | JWT | Update permission statuses |
| GET | `/api/devices/:deviceId` | JWT | Retrieve device record |
| POST | `/api/uploads/auth` | JWT | Get ImageKit upload auth params |
| POST | `/api/media/metadata` | JWT | Store ImageKit URL after upload |
| POST | `/api/contacts` | JWT | Store user-authorised contacts |

---

## Setup (local development)

```bash
cd backend
cp .env.example .env
# Edit .env with your credentials
npm install
npm run dev
```

Then test:

```bash
curl http://localhost:10000/health
```

Expected:

```json
{ "success": true, "message": "Backend is running" }
```

---

## Environment variables

See [`.env.example`](.env.example) for the full list.

**Never commit a real `.env` file.** Add credentials only in:
- Your local `.env` (git-ignored)
- Render environment variable settings

---

## CORS

`origin: '*'` is set because the Flutter HTTP client on Android does not send
an `Origin` header. Authentication (JWT) is the access control mechanism for
all sensitive routes.

---

## Security

- Credentials loaded exclusively from environment variables
- ImageKit private key is never returned to any client
- JWT required for all routes except `/health` and `/api/devices/register`
- Helmet sets secure HTTP headers
- Stack traces are suppressed in production responses
- No IMEI or restricted device identifiers are collected

---

## Deployment

See [`BACKEND_DEPLOYMENT.md`](BACKEND_DEPLOYMENT.md) for step-by-step Render deployment.

See [`TESTING.md`](TESTING.md) for curl test commands.
