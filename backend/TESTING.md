# TTAPP Backend — Testing Guide

All curl examples assume the server is running locally on port 10000.
Replace `http://localhost:10000` with your Render URL for production testing.

---

## 0. Prerequisites

```bash
cd backend
cp .env.example .env
# Fill in .env with valid credentials
npm install
npm run dev
```

---

## 1. Health Check

```bash
curl http://localhost:10000/health
```

**Expected (200):**

```json
{
  "success": true,
  "message": "Backend is running"
}
```

**Test: wrong path → 404**

```bash
curl http://localhost:10000/notexist
```

```json
{
  "success": false,
  "message": "Route not found."
}
```

---

## 2. Device Registration

### 2a. Register a new device

```bash
curl -s -X POST http://localhost:10000/api/devices/register \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "test-device-001",
    "manufacturer": "Xiaomi",
    "model": "Redmi 14C",
    "androidVersion": "15",
    "androidSdk": 35,
    "appVersion": "1.0.0",
    "buildNumber": "1",
    "permissions": {
      "photos": "granted",
      "videos": "granted",
      "files": "limited",
      "contacts": "denied",
      "biometric": "available"
    }
  }' | python -m json.tool
```

**Expected (200):**

```json
{
  "success": true,
  "message": "Device registered successfully.",
  "data": {
    "deviceId": "test-device-001",
    "token": "<JWT_TOKEN>",
    "registeredAt": "...",
    "updatedAt": "..."
  }
}
```

> **Save the `token` value** — you'll need it as `DEVICE_TOKEN` in the tests below.

### 2b. Re-register same device (idempotent upsert)

```bash
curl -s -X POST http://localhost:10000/api/devices/register \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "test-device-001",
    "appVersion": "1.0.1"
  }' | python -m json.tool
```

**Expected (200):** Same structure — no duplicate created.

### 2c. Validation error — missing deviceId

```bash
curl -s -X POST http://localhost:10000/api/devices/register \
  -H "Content-Type: application/json" \
  -d '{"manufacturer": "Xiaomi"}' | python -m json.tool
```

**Expected (400):**

```json
{
  "success": false,
  "message": "deviceId is required"
}
```

### 2d. Validation error — invalid permission status

```bash
curl -s -X POST http://localhost:10000/api/devices/register \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "test-device-002",
    "permissions": { "photos": "yes_please" }
  }' | python -m json.tool
```

**Expected (400):** Validation error listing allowed values.

---

## 3. Permission Update

Set `DEVICE_TOKEN` to the JWT returned by registration:

```bash
export DEVICE_TOKEN="<paste token here>"
```

### 3a. Update permissions

```bash
curl -s -X PATCH \
  http://localhost:10000/api/devices/test-device-001/permissions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DEVICE_TOKEN" \
  -d '{
    "contacts": "granted",
    "files": "granted"
  }' | python -m json.tool
```

**Expected (200):**

```json
{
  "success": true,
  "message": "Permissions updated.",
  "data": {
    "permissions": {
      "photos": "granted",
      "videos": "granted",
      "files": "granted",
      "contacts": "granted",
      "biometric": "available"
    }
  }
}
```

### 3b. No auth token → 401

```bash
curl -s -X PATCH \
  http://localhost:10000/api/devices/test-device-001/permissions \
  -H "Content-Type: application/json" \
  -d '{"photos": "granted"}' | python -m json.tool
```

**Expected (401):**

```json
{
  "success": false,
  "message": "Authentication token is required."
}
```

### 3c. Unknown device → 404

```bash
curl -s -X PATCH \
  http://localhost:10000/api/devices/does-not-exist/permissions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DEVICE_TOKEN" \
  -d '{"photos": "granted"}' | python -m json.tool
```

**Expected (404):**

```json
{
  "success": false,
  "message": "Device not found. Register the device first."
}
```

---

## 4. Get Device

```bash
curl -s \
  http://localhost:10000/api/devices/test-device-001 \
  -H "Authorization: Bearer $DEVICE_TOKEN" | python -m json.tool
```

**Expected (200):**

```json
{
  "success": true,
  "message": "Device retrieved.",
  "data": {
    "deviceId": "test-device-001",
    "manufacturer": "Xiaomi",
    "model": "Redmi 14C",
    "permissions": { ... },
    "createdAt": "...",
    "updatedAt": "..."
  }
}
```

---

## 5. Upload Authentication

```bash
curl -s -X POST \
  http://localhost:10000/api/uploads/auth \
  -H "Authorization: Bearer $DEVICE_TOKEN" | python -m json.tool
```

**Expected (200):**

```json
{
  "success": true,
  "message": "Upload auth parameters generated.",
  "data": {
    "token": "...",
    "expire": 1234567890,
    "signature": "...",
    "publicKey": "public_...",
    "urlEndpoint": "https://ik.imagekit.io/..."
  }
}
```

> Verify that `IMAGEKIT_PRIVATE_KEY` is **NOT** present anywhere in this response.

**Without ImageKit configured (503):**

If ImageKit env vars are missing, expect:

```json
{
  "success": false,
  "message": "Upload service is not configured. Contact the administrator."
}
```

---

## 6. Media Metadata

```bash
curl -s -X POST \
  http://localhost:10000/api/media/metadata \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DEVICE_TOKEN" \
  -d '{
    "deviceId": "test-device-001",
    "type": "photo",
    "fileName": "IMG_1234.jpg",
    "mimeType": "image/jpeg",
    "size": 123456,
    "imageKitUrl": "https://ik.imagekit.io/yourid/devices/test-device-001/photos/IMG_1234.jpg",
    "imageKitFileId": "ik_file_abc123"
  }' | python -m json.tool
```

**Expected (201):**

```json
{
  "success": true,
  "message": "Media metadata saved.",
  "data": {
    "id": "...",
    "deviceId": "test-device-001",
    "type": "photo",
    "fileName": "IMG_1234.jpg",
    "imageKitUrl": "https://ik.imagekit.io/...",
    "createdAt": "..."
  }
}
```

### 6b. Invalid type

```bash
curl -s -X POST \
  http://localhost:10000/api/media/metadata \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DEVICE_TOKEN" \
  -d '{
    "deviceId": "test-device-001",
    "type": "audio",
    "fileName": "song.mp3",
    "imageKitUrl": "https://ik.imagekit.io/x/song.mp3"
  }' | python -m json.tool
```

**Expected (400):** type must be photo, video, or file.

---

## 7. Contacts

```bash
curl -s -X POST \
  http://localhost:10000/api/contacts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DEVICE_TOKEN" \
  -d '{
    "deviceId": "test-device-001",
    "contacts": [
      { "name": "Alice", "phones": ["+919876543210"] },
      { "name": "Bob",   "phones": ["+919876543211", "+919876543212"] }
    ]
  }' | python -m json.tool
```

**Expected (200):**

```json
{
  "success": true,
  "message": "Contacts saved.",
  "data": {
    "inserted": 2,
    "updated": 0,
    "total": 2
  }
}
```

### 7b. Re-sync same contacts (idempotent)

Run the same request again. Expected: `inserted: 0, updated: 0` (matched, no change) or `updated: 2`.

### 7c. Empty contacts array → 400

```bash
curl -s -X POST \
  http://localhost:10000/api/contacts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DEVICE_TOKEN" \
  -d '{"deviceId": "test-device-001", "contacts": []}' | python -m json.tool
```

**Expected (400):** Validation error.

---

## 8. MongoDB Verification

After running the tests above, verify data was written to Atlas:

1. Log in to [cloud.mongodb.com](https://cloud.mongodb.com)
2. Click your cluster → **Browse Collections**
3. Check database `timetable` (or whatever your URI specifies)

| Collection | Should contain |
|-----------|---------------|
| `devices` | 1–2 device documents |
| `media` | 1 photo metadata document |
| `contacts` | 2 contact documents |

---

## 9. ImageKit Verification

After a successful `/api/uploads/auth` call and a real upload from Flutter:

1. Log in to [imagekit.io](https://imagekit.io) → **Media Library**
2. Check for folder `devices/<deviceId>/photos/`

---

## 10. Missing Environment Variables

Stop the server and unset `JWT_SECRET`:

```bash
# Temporarily: comment out JWT_SECRET in .env and restart
npm run dev
```

Try registering a device — it should succeed (token will be null in response).
Try a protected route — expect 500 with "Server configuration error." (safe message, no secret exposed).

---

## Windows Users

If `python` is not available, replace `| python -m json.tool` with:

```powershell
| ConvertFrom-Json | ConvertTo-Json -Depth 10
```

Or use [Postman](https://www.postman.com) / [Bruno](https://www.usebruno.com) for a GUI alternative.
