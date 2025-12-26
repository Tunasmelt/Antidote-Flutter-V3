# Backend Spotify OAuth Migration Guide

This guide shows how to update your backend to use user Spotify tokens instead of client credentials.

## Overview

**Before:** Backend uses Client Credentials flow (Client ID + Secret) - shared across all users
**After:** Backend uses user access tokens - each user authenticates with their own Spotify account

## Benefits

- ✅ No Client Secret needed (only public Client ID)
- ✅ Better rate limits (per user, not shared)
- ✅ Access to user-specific features (private playlists, saved tracks)
- ✅ More secure (user-specific tokens)
- ✅ Scalable (no shared rate limit issues)

## Migration Steps

### Step 1: Remove Client Secret Dependency

**Remove from `.env` or environment variables:**
```bash
# REMOVE THIS:
SPOTIFY_CLIENT_SECRET=your_secret_here
```

**Keep only:**
```bash
SPOTIFY_CLIENT_ID=your_client_id_here  # Public, safe to keep
```

### Step 2: Update Spotify API Client Initialization

**Before (Client Credentials):**
```typescript
import SpotifyWebApi from 'spotify-web-api-node';

// Old way - using client credentials
const spotifyApi = new SpotifyWebApi({
  clientId: process.env.SPOTIFY_CLIENT_ID,
  clientSecret: process.env.SPOTIFY_CLIENT_SECRET,
});

// Get token using client credentials
const tokenData = await spotifyApi.clientCredentialsGrant();
spotifyApi.setAccessToken(tokenData.body['access_token']);
```

**After (User Tokens):**
```typescript
import SpotifyWebApi from 'spotify-web-api-node';

// New way - using user token from request
function createSpotifyApi(userToken: string) {
  return new SpotifyWebApi({
    accessToken: userToken,
    // No clientSecret needed!
  });
}
```

### Step 3: Extract User Token from Requests

**Create a middleware to extract Spotify token:**

```typescript
// middleware/spotifyToken.ts
import { Request, Response, NextFunction } from 'express';

export interface SpotifyRequest extends Request {
  spotifyToken?: string;
}

export function extractSpotifyToken(
  req: SpotifyRequest,
  res: Response,
  next: NextFunction
) {
  // Try to get token from header first
  const headerToken = req.headers['x-spotify-token'] as string;
  
  // Fallback to request body
  const bodyToken = req.body?.spotify_token as string;
  
  // Use whichever is available
  req.spotifyToken = headerToken || bodyToken;
  
  next();
}
```

### Step 4: Update API Endpoints

#### Example: `/api/analyze` Endpoint

**Before:**
```typescript
app.post('/api/analyze', async (req, res) => {
  try {
    const { url } = req.body;
    
    // Use shared client credentials token
    const tokenData = await spotifyApi.clientCredentialsGrant();
    spotifyApi.setAccessToken(tokenData.body['access_token']);
    
    // Fetch playlist
    const playlistId = extractPlaylistId(url);
    const playlist = await spotifyApi.getPlaylist(playlistId);
    
    // Analyze and return...
    res.json(analysisResult);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

**After:**
```typescript
import { extractSpotifyToken, SpotifyRequest } from './middleware/spotifyToken';

app.post('/api/analyze', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const { url } = req.body;
    const userToken = req.spotifyToken;
    
    // Validate token exists
    if (!userToken) {
      return res.status(401).json({ 
        error: 'Spotify token required. Please connect your Spotify account.' 
      });
    }
    
    // Create Spotify API instance with user token
    const spotifyApi = createSpotifyApi(userToken);
    
    // Fetch playlist using user token
    const playlistId = extractPlaylistId(url);
    const playlist = await spotifyApi.getPlaylist(playlistId);
    
    // Analyze and return...
    res.json(analysisResult);
  } catch (error) {
    // Handle token expiration
    if (error.statusCode === 401) {
      return res.status(401).json({ 
        error: 'Spotify token expired. Please reconnect your account.',
        code: 'TOKEN_EXPIRED'
      });
    }
    res.status(500).json({ error: error.message });
  }
});
```

#### Example: `/api/battle` Endpoint

**After:**
```typescript
app.post('/api/battle', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const { url1, url2 } = req.body;
    const userToken = req.spotifyToken;
    
    if (!userToken) {
      return res.status(401).json({ 
        error: 'Spotify token required' 
      });
    }
    
    const spotifyApi = createSpotifyApi(userToken);
    
    // Fetch both playlists
    const playlist1 = await spotifyApi.getPlaylist(extractPlaylistId(url1));
    const playlist2 = await spotifyApi.getPlaylist(extractPlaylistId(url2));
    
    // Battle logic...
    res.json(battleResult);
  } catch (error) {
    if (error.statusCode === 401) {
      return res.status(401).json({ 
        error: 'Spotify token expired',
        code: 'TOKEN_EXPIRED'
      });
    }
    res.status(500).json({ error: error.message });
  }
});
```

#### Example: `/api/recommendations` Endpoint

**After:**
```typescript
app.get('/api/recommendations', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const { type, playlistId, seed_tracks, seed_genres, seed_artists } = req.query;
    const userToken = req.spotifyToken;
    
    if (!userToken) {
      return res.status(401).json({ 
        error: 'Spotify token required' 
      });
    }
    
    const spotifyApi = createSpotifyApi(userToken);
    
    // Get recommendations using user token
    const recommendations = await spotifyApi.getRecommendations({
      seed_tracks: seed_tracks?.split(','),
      seed_genres: seed_genres?.split(','),
      seed_artists: seed_artists?.split(','),
    });
    
    res.json(recommendations.body.tracks);
  } catch (error) {
    if (error.statusCode === 401) {
      return res.status(401).json({ 
        error: 'Spotify token expired',
        code: 'TOKEN_EXPIRED'
      });
    }
    res.status(500).json({ error: error.message });
  }
});
```

### Step 5: Handle Token Expiration

**Create error handler middleware:**

```typescript
// middleware/spotifyErrorHandler.ts
export function handleSpotifyError(error: any, res: Response) {
  if (error.statusCode === 401) {
    return res.status(401).json({
      error: 'Spotify token expired or invalid. Please reconnect your account.',
      code: 'TOKEN_EXPIRED',
      requiresReconnect: true
    });
  }
  
  if (error.statusCode === 403) {
    return res.status(403).json({
      error: 'Insufficient permissions. Please reconnect with required scopes.',
      code: 'INSUFFICIENT_PERMISSIONS'
    });
  }
  
  // Other errors
  return res.status(error.statusCode || 500).json({
    error: error.message || 'Spotify API error'
  });
}
```

### Step 6: Update Environment Configuration

**Update your `.env.example` or documentation:**

```bash
# Spotify Configuration
# Only Client ID is needed (public, safe to use)
SPOTIFY_CLIENT_ID=your_client_id_here

# Client Secret is NO LONGER NEEDED
# SPOTIFY_CLIENT_SECRET=  # REMOVED
```

### Step 7: Remove Client Credentials Code

**Remove any code that:**
- Calls `clientCredentialsGrant()`
- Stores client credentials tokens
- Refreshes client credentials tokens
- Uses `SPOTIFY_CLIENT_SECRET`

**Search for and remove:**
```typescript
// Remove these patterns:
spotifyApi.clientCredentialsGrant()
process.env.SPOTIFY_CLIENT_SECRET
clientSecret
```

## Complete Example Backend

See `server/index.ts` for a complete example implementation.

## Testing

### Test with User Token

1. Get a user token from Flutter app (after Spotify OAuth)
2. Test endpoint with token:

```bash
curl -X POST http://localhost:5000/api/analyze \
  -H "Content-Type: application/json" \
  -H "X-Spotify-Token: YOUR_USER_TOKEN" \
  -d '{"url": "https://open.spotify.com/playlist/37i9dQZF1DX0XUsuxWHRQd"}'
```

### Test Token Expiration

1. Use an expired token
2. Verify backend returns 401 with `TOKEN_EXPIRED` code
3. Flutter app should handle this and refresh token

## Error Codes

Backend should return these error codes for Flutter app handling:

- `TOKEN_EXPIRED` - Token expired, user needs to reconnect
- `INSUFFICIENT_PERMISSIONS` - Token missing required scopes
- `TOKEN_REQUIRED` - No token provided in request

## Migration Checklist

- [ ] Remove `SPOTIFY_CLIENT_SECRET` from environment variables
- [ ] Remove client credentials grant code
- [ ] Add `extractSpotifyToken` middleware
- [ ] Update all Spotify API endpoints to use user tokens
- [ ] Add token validation and error handling
- [ ] Test with user tokens from Flutter app
- [ ] Update documentation
- [ ] Deploy and monitor

## Rollback Plan

If needed, you can temporarily support both methods:

```typescript
// Support both for gradual migration
const userToken = req.spotifyToken;
const spotifyApi = userToken 
  ? createSpotifyApi(userToken)  // Use user token
  : await getClientCredentialsApi();  // Fallback to client credentials
```

However, the goal is to fully migrate to user tokens for better security and scalability.

