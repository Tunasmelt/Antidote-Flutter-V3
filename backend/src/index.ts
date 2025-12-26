import express from 'express';
import cors from 'cors';
import SpotifyWebApi from 'spotify-web-api-node';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Spotify-Token'],
}));
app.use(express.json());

// ============================================================================
// SPOTIFY TOKEN MIDDLEWARE
// ============================================================================

export interface SpotifyRequest extends express.Request {
  spotifyToken?: string;
}

/**
 * Middleware to extract Spotify token from request
 * Checks both header (X-Spotify-Token) and body (spotify_token)
 */
export function extractSpotifyToken(
  req: SpotifyRequest,
  res: express.Response,
  next: express.NextFunction
) {
  // Try header first (preferred)
  const headerToken = req.headers['x-spotify-token'] as string;
  
  // Fallback to body
  const bodyToken = req.body?.spotify_token as string;
  
  // Use whichever is available
  req.spotifyToken = headerToken || bodyToken;
  
  next();
}

/**
 * Create Spotify API instance with user token
 * No Client Secret needed!
 */
function createSpotifyApi(userToken: string): SpotifyWebApi {
  return new SpotifyWebApi({
    accessToken: userToken,
    // Only Client ID needed (public, safe to use)
    clientId: process.env.SPOTIFY_CLIENT_ID,
  });
}

/**
 * Handle Spotify API errors
 */
function handleSpotifyError(error: any, res: express.Response) {
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
  
  if (error.statusCode === 404) {
    return res.status(404).json({
      error: 'Playlist not found or not accessible.',
      code: 'NOT_FOUND'
    });
  }
  
  // Other errors
  return res.status(error.statusCode || 500).json({
    error: error.message || 'Spotify API error',
    code: 'SPOTIFY_ERROR'
  });
}

/**
 * Extract Spotify playlist/track ID from URL
 */
function extractSpotifyId(url: string): string | null {
  const match = url.match(/(?:playlist|track|album)\/([a-zA-Z0-9]+)/);
  return match ? match[1] : null;
}

// ============================================================================
// API ENDPOINTS
// ============================================================================

/**
 * POST /api/analyze
 * Analyze a Spotify playlist
 */
app.post('/api/analyze', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const { url } = req.body;
    const userToken = req.spotifyToken;
    
    // Validate token exists
    if (!userToken) {
      return res.status(401).json({ 
        error: 'Spotify token required. Please connect your Spotify account.',
        code: 'TOKEN_REQUIRED'
      });
    }
    
    if (!url) {
      return res.status(400).json({ 
        error: 'Playlist URL is required' 
      });
    }
    
    // Extract playlist ID
    const playlistId = extractSpotifyId(url);
    if (!playlistId) {
      return res.status(400).json({ 
        error: 'Invalid Spotify playlist URL' 
      });
    }
    
    // Create Spotify API with user token
    const spotifyApi = createSpotifyApi(userToken);
    
    // Fetch playlist data
    const playlist = await spotifyApi.getPlaylist(playlistId);
    
    // Fetch tracks
    const tracks = await spotifyApi.getPlaylistTracks(playlistId, {
      limit: 100,
      offset: 0
    });
    
    // Analyze playlist (your analysis logic here)
    const analysisResult = {
      playlistName: playlist.body.name,
      owner: playlist.body.owner?.display_name || 'Unknown',
      coverUrl: playlist.body.images?.[0]?.url,
      trackCount: playlist.body.tracks.total,
      // ... your analysis data
    };
    
    res.json(analysisResult);
  } catch (error: any) {
    handleSpotifyError(error, res);
  }
});

/**
 * POST /api/battle
 * Battle two playlists
 */
app.post('/api/battle', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const { url1, url2 } = req.body;
    const userToken = req.spotifyToken;
    
    if (!userToken) {
      return res.status(401).json({ 
        error: 'Spotify token required',
        code: 'TOKEN_REQUIRED'
      });
    }
    
    if (!url1 || !url2) {
      return res.status(400).json({ 
        error: 'Both playlist URLs are required' 
      });
    }
    
    const spotifyApi = createSpotifyApi(userToken);
    
    // Extract playlist IDs
    const playlist1Id = extractSpotifyId(url1);
    const playlist2Id = extractSpotifyId(url2);
    
    if (!playlist1Id || !playlist2Id) {
      return res.status(400).json({ 
        error: 'Invalid playlist URLs' 
      });
    }
    
    // Fetch both playlists
    const [playlist1, playlist2] = await Promise.all([
      spotifyApi.getPlaylist(playlist1Id),
      spotifyApi.getPlaylist(playlist2Id),
    ]);
    
    // Battle logic (your comparison logic here)
    const battleResult = {
      compatibilityScore: 85,
      winner: 'playlist1',
      playlist1: {
        name: playlist1.body.name,
        owner: playlist1.body.owner?.display_name,
        score: 85,
        tracks: playlist1.body.tracks.total,
      },
      playlist2: {
        name: playlist2.body.name,
        owner: playlist2.body.owner?.display_name,
        score: 75,
        tracks: playlist2.body.tracks.total,
      },
      // ... your battle data
    };
    
    res.json(battleResult);
  } catch (error: any) {
    handleSpotifyError(error, res);
  }
});

/**
 * GET /api/recommendations
 * Get music recommendations
 */
app.get('/api/recommendations', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const { type, playlistId, seed_tracks, seed_genres, seed_artists } = req.query;
    const userToken = req.spotifyToken;
    
    if (!userToken) {
      return res.status(401).json({ 
        error: 'Spotify token required',
        code: 'TOKEN_REQUIRED'
      });
    }
    
    const spotifyApi = createSpotifyApi(userToken);
    
    // Build recommendation parameters
    const recommendationParams: any = {};
    
    if (seed_tracks) {
      recommendationParams.seed_tracks = (seed_tracks as string).split(',');
    }
    if (seed_genres) {
      recommendationParams.seed_genres = (seed_genres as string).split(',');
    }
    if (seed_artists) {
      recommendationParams.seed_artists = (seed_artists as string).split(',');
    }
    
    // Get recommendations
    const recommendations = await spotifyApi.getRecommendations(recommendationParams);
    
    res.json(recommendations.body.tracks);
  } catch (error: any) {
    handleSpotifyError(error, res);
  }
});

/**
 * POST /api/playlists
 * Create a playlist
 */
app.post('/api/playlists', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const { name, description, tracks, coverUrl } = req.body;
    const userToken = req.spotifyToken;
    
    if (!userToken) {
      return res.status(401).json({ 
        error: 'Spotify token required',
        code: 'TOKEN_REQUIRED'
      });
    }
    
    if (!name || !tracks) {
      return res.status(400).json({ 
        error: 'Name and tracks are required' 
      });
    }
    
    const spotifyApi = createSpotifyApi(userToken);
    
    // Get current user ID
    const me = await spotifyApi.getMe();
    const userId = me.body.id;
    
    // Create playlist
    const playlist = await spotifyApi.createPlaylist(userId, name, {
      description: description,
      public: false,
    });
    
    // Add tracks
    const trackUris = tracks.map((track: any) => track.uri || track.id);
    if (trackUris.length > 0) {
      await spotifyApi.addTracksToPlaylist(playlist.body.id, trackUris);
    }
    
    res.json({
      id: playlist.body.id,
      name: playlist.body.name,
      url: playlist.body.external_urls.spotify,
      trackCount: tracks.length,
    });
  } catch (error: any) {
    handleSpotifyError(error, res);
  }
});

/**
 * DELETE /api/playlists/:id
 * Delete a playlist (if user owns it)
 */
app.delete('/api/playlists/:id', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const { id } = req.params;
    const userToken = req.spotifyToken;
    
    if (!userToken) {
      return res.status(401).json({ 
        error: 'Spotify token required',
        code: 'TOKEN_REQUIRED'
      });
    }
    
    const spotifyApi = createSpotifyApi(userToken);
    
    // Note: Spotify API doesn't have a direct delete endpoint
    // You may need to unfollow/delete via user's playlists
    // This is a placeholder - implement based on your needs
    
    res.json({ message: 'Playlist deleted' });
  } catch (error: any) {
    handleSpotifyError(error, res);
  }
});

/**
 * GET /api/history
 * Get user's analysis and battle history
 */
app.get('/api/history', async (req, res) => {
  try {
    // This should query your database for user's history
    // For now, return empty array
    res.json([]);
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/stats
 * Get user statistics
 */
app.get('/api/stats', async (req, res) => {
  try {
    // This should query your database for user's stats
    // For now, return default stats
    res.json({
      analysesCount: 0,
      battlesCount: 0,
      averageScore: 0,
    });
  } catch (error: any) {
    res.status(500).json({ error: error.message });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📝 Spotify Client ID: ${process.env.SPOTIFY_CLIENT_ID ? '✅ Configured' : '❌ Missing'}`);
  console.log(`🔐 Client Secret: ${process.env.SPOTIFY_CLIENT_SECRET ? '⚠️  Still configured (should be removed)' : '✅ Removed (correct)'}`);
  
  // Log URL for local development
  if (process.env.NODE_ENV !== 'production') {
    console.log(`📍 Local URL: http://localhost:${PORT}`);
  }
});

