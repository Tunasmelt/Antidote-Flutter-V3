# Backend Implementation Steps

Follow these steps to implement the Spotify OAuth changes in your backend.

## Quick Start

1. **Copy the example server code**
   - Use `server/index.ts` as a reference
   - Adapt to your existing backend structure

2. **Update your environment variables**
   - Remove `SPOTIFY_CLIENT_SECRET`
   - Keep only `SPOTIFY_CLIENT_ID`

3. **Add the middleware**
   - Copy `extractSpotifyToken` middleware
   - Apply to endpoints that need Spotify API access

4. **Update your endpoints**
   - Replace client credentials with user tokens
   - Use `createSpotifyApi(userToken)` instead of client credentials

5. **Test with Flutter app**
   - Connect Spotify in Flutter app
   - Test all endpoints with user tokens

## Detailed Steps

### Step 1: Remove Client Secret

**In your `.env` file:**
```bash
# REMOVE THIS LINE:
SPOTIFY_CLIENT_SECRET=your_secret_here
```

**In your code:**
- Remove all references to `process.env.SPOTIFY_CLIENT_SECRET`
- Remove `clientSecret` from SpotifyWebApi initialization

### Step 2: Add Token Extraction Middleware

**Create `middleware/spotifyToken.ts`:**

```typescript
import { Request, Response, NextFunction } from 'express';

export interface SpotifyRequest extends Request {
  spotifyToken?: string;
}

export function extractSpotifyToken(
  req: SpotifyRequest,
  res: Response,
  next: NextFunction
) {
  const headerToken = req.headers['x-spotify-token'] as string;
  const bodyToken = req.body?.spotify_token as string;
  req.spotifyToken = headerToken || bodyToken;
  next();
}
```

### Step 3: Create Spotify API Helper

**Replace client credentials initialization:**

```typescript
// OLD (Remove this):
const spotifyApi = new SpotifyWebApi({
  clientId: process.env.SPOTIFY_CLIENT_ID,
  clientSecret: process.env.SPOTIFY_CLIENT_SECRET,
});
const tokenData = await spotifyApi.clientCredentialsGrant();
spotifyApi.setAccessToken(tokenData.body['access_token']);

// NEW:
function createSpotifyApi(userToken: string): SpotifyWebApi {
  return new SpotifyWebApi({
    accessToken: userToken,
    clientId: process.env.SPOTIFY_CLIENT_ID,
  });
}
```

### Step 4: Update Each Endpoint

**For each endpoint that uses Spotify API:**

1. Add `extractSpotifyToken` middleware
2. Check for `req.spotifyToken`
3. Create API instance with user token
4. Handle token expiration errors

**Example pattern:**

```typescript
app.post('/api/analyze', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  const userToken = req.spotifyToken;
  
  if (!userToken) {
    return res.status(401).json({ 
      error: 'Spotify token required',
      code: 'TOKEN_REQUIRED'
    });
  }
  
  const spotifyApi = createSpotifyApi(userToken);
  // Use spotifyApi for API calls...
});
```

### Step 5: Error Handling

**Add error handler for Spotify API errors:**

```typescript
function handleSpotifyError(error: any, res: Response) {
  if (error.statusCode === 401) {
    return res.status(401).json({
      error: 'Spotify token expired',
      code: 'TOKEN_EXPIRED'
    });
  }
  // Handle other errors...
}
```

### Step 6: Test

**Test with user token from Flutter:**

1. Connect Spotify in Flutter app
2. Get the access token (check Flutter logs or use debugger)
3. Test endpoint:

```bash
curl -X POST http://localhost:5000/api/analyze \
  -H "X-Spotify-Token: YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://open.spotify.com/playlist/..."}'
```

## Endpoints to Update

Update these endpoints to use user tokens:

- ✅ `POST /api/analyze` - Analyze playlist
- ✅ `POST /api/battle` - Battle playlists
- ✅ `GET /api/recommendations` - Get recommendations
- ✅ `POST /api/playlists` - Create playlist
- ✅ `DELETE /api/playlists/:id` - Delete playlist

## Common Issues

### Issue: "Token required" error
**Solution:** Make sure Flutter app is sending token in `X-Spotify-Token` header or `spotify_token` in body.

### Issue: "Token expired" error
**Solution:** Flutter app should handle this and refresh token. Backend should return `TOKEN_EXPIRED` code.

### Issue: "Insufficient permissions"
**Solution:** User needs to reconnect with required scopes. Check Supabase OAuth scopes configuration.

## Verification Checklist

- [ ] Removed `SPOTIFY_CLIENT_SECRET` from `.env`
- [ ] Removed client credentials grant code
- [ ] Added `extractSpotifyToken` middleware
- [ ] Updated all Spotify API endpoints
- [ ] Added error handling for token expiration
- [ ] Tested with user token from Flutter app
- [ ] Verified no Client Secret is used anywhere

## Need Help?

See `SPOTIFY_OAUTH_MIGRATION.md` for detailed migration guide with code examples.

