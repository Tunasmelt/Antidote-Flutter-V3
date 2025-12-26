# Antidote Backend API

Backend server for Antidote Flutter app with Spotify OAuth integration.

## Features

- ✅ User-based Spotify OAuth (no Client Secret needed)
- ✅ Playlist analysis
- ✅ Playlist battles/comparisons
- ✅ Music recommendations
- ✅ Playlist management

## Setup

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

Edit `.env` and add your Spotify Client ID:

```env
SPOTIFY_CLIENT_ID=your_client_id_here
```

**Important:** Do NOT add `SPOTIFY_CLIENT_SECRET` - it's not needed!

### 3. Run Development Server

```bash
npm run dev
```

Server will run on `http://localhost:5000`

### 4. Build for Production

```bash
npm run build
npm start
```

## API Endpoints

### POST /api/analyze
Analyze a Spotify playlist.

**Headers:**
- `X-Spotify-Token`: User's Spotify access token (required)

**Body:**
```json
{
  "url": "https://open.spotify.com/playlist/37i9dQZF1DX0XUsuxWHRQd"
}
```

**Response:**
```json
{
  "playlistName": "Playlist Name",
  "owner": "Owner Name",
  "trackCount": 50,
  ...
}
```

### POST /api/battle
Battle two playlists.

**Headers:**
- `X-Spotify-Token`: User's Spotify access token (required)

**Body:**
```json
{
  "url1": "https://open.spotify.com/playlist/...",
  "url2": "https://open.spotify.com/playlist/..."
}
```

### GET /api/recommendations
Get music recommendations.

**Headers:**
- `X-Spotify-Token`: User's Spotify access token (required)

**Query Parameters:**
- `type`: Recommendation type
- `seed_tracks`: Comma-separated track IDs
- `seed_genres`: Comma-separated genres
- `seed_artists`: Comma-separated artist IDs

### POST /api/playlists
Create a playlist.

**Headers:**
- `X-Spotify-Token`: User's Spotify access token (required)

**Body:**
```json
{
  "name": "My Playlist",
  "description": "Description",
  "tracks": [...]
}
```

## Error Handling

The API returns specific error codes:

- `TOKEN_REQUIRED`: No Spotify token provided
- `TOKEN_EXPIRED`: Token expired, user needs to reconnect
- `INSUFFICIENT_PERMISSIONS`: Token missing required scopes
- `NOT_FOUND`: Playlist not found or not accessible

## Migration from Client Credentials

See `SPOTIFY_OAUTH_MIGRATION.md` for detailed migration steps.

## Testing

### Test with curl

```bash
# Get a user token from Flutter app after Spotify OAuth
USER_TOKEN="your_user_token_here"

# Test analyze endpoint
curl -X POST http://localhost:5000/api/analyze \
  -H "Content-Type: application/json" \
  -H "X-Spotify-Token: $USER_TOKEN" \
  -d '{"url": "https://open.spotify.com/playlist/37i9dQZF1DX0XUsuxWHRQd"}'
```

## Architecture

- **Express.js**: Web framework
- **spotify-web-api-node**: Spotify Web API client
- **TypeScript**: Type safety
- **CORS**: Cross-origin support for Flutter app

## Security Notes

- ✅ No Client Secret stored
- ✅ User tokens are passed from Flutter app
- ✅ Tokens are validated by Spotify API
- ✅ Expired tokens return proper error codes

## License

MIT

