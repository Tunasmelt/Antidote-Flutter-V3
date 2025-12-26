# Backend Quick Start Guide

## 🚀 Quick Setup (5 minutes)

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment

```bash
# Copy example env file
cp env.example .env

# Edit .env and add your Spotify Client ID
# Only Client ID is needed - NO Client Secret!
```

```env
SPOTIFY_CLIENT_ID=your_client_id_here
PORT=5000
```

### 3. Run Server

```bash
# Development
npm run dev

# Production
npm run build
npm start
```

Server runs on `http://localhost:5000` ✅

## 📋 What Changed

### Before (Client Credentials)
- ❌ Required `SPOTIFY_CLIENT_SECRET`
- ❌ Shared rate limits
- ❌ No user-specific features

### After (User OAuth)
- ✅ Only `SPOTIFY_CLIENT_ID` needed
- ✅ User-specific tokens
- ✅ Better rate limits per user
- ✅ Access to private playlists

## 🔧 Key Changes

1. **Removed Client Secret** - No longer needed
2. **Added Token Middleware** - Extracts user tokens from requests
3. **Updated Endpoints** - All use user tokens instead of client credentials
4. **Error Handling** - Proper error codes for token expiration

## 📡 API Endpoints

All endpoints now require `X-Spotify-Token` header:

- `POST /api/analyze` - Analyze playlist
- `POST /api/battle` - Battle playlists  
- `GET /api/recommendations` - Get recommendations
- `POST /api/playlists` - Create playlist
- `DELETE /api/playlists/:id` - Delete playlist

## 🧪 Test

```bash
# Get token from Flutter app after Spotify OAuth
TOKEN="your_user_token"

# Test analyze endpoint
curl -X POST http://localhost:5000/api/analyze \
  -H "X-Spotify-Token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://open.spotify.com/playlist/37i9dQZF1DX0XUsuxWHRQd"}'
```

## 📚 Documentation

- **Migration Guide**: `SPOTIFY_OAUTH_MIGRATION.md`
- **Implementation Steps**: `IMPLEMENTATION_STEPS.md`
- **Full README**: `README.md`

## ✅ Checklist

- [ ] Removed `SPOTIFY_CLIENT_SECRET` from `.env`
- [ ] Added `SPOTIFY_CLIENT_ID` to `.env`
- [ ] Installed dependencies (`npm install`)
- [ ] Server runs without errors
- [ ] Tested with Flutter app

## 🆘 Troubleshooting

**Error: "Token required"**
- Make sure Flutter app is sending `X-Spotify-Token` header
- Check that user has connected Spotify in Flutter app

**Error: "Token expired"**
- Flutter app should automatically refresh token
- User may need to reconnect Spotify

**Error: "Insufficient permissions"**
- Check Supabase OAuth scopes configuration
- User needs to reconnect with required scopes

---

**Ready to go!** Your backend now uses user-based Spotify OAuth. 🎉

