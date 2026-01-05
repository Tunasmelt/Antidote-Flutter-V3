import express from 'express';
import cors from 'cors';
import SpotifyWebApi from 'spotify-web-api-node';
import dotenv from 'dotenv';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { rateLimitUnauthenticated } from './middleware/rateLimiter';

dotenv.config();

// ============================================================================
// ENVIRONMENT VALIDATION
// ============================================================================

// Validate required environment variables at startup
const requiredEnvVars = ['SPOTIFY_CLIENT_ID', 'SPOTIFY_CLIENT_SECRET'];
const recommendedEnvVars = ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY'];

const missingRequired = requiredEnvVars.filter(key => !process.env[key]);
const missingRecommended = recommendedEnvVars.filter(key => !process.env[key]);

if (missingRequired.length > 0) {
  console.error('❌ FATAL: Missing required environment variables:');
  console.error('   ' + missingRequired.join(', '));
  console.error('   Application cannot function without these. Exiting.');
  process.exit(1);
}

if (missingRecommended.length > 0) {
  console.warn('⚠️  WARNING: Missing recommended environment variables:');
  console.warn('   ' + missingRecommended.join(', '));
  console.warn('   Database features will be disabled.');
}

const app = express();
const PORT = process.env.PORT || 5000;

// ============================================================================
// SUPABASE CLIENT INITIALIZATION
// ============================================================================

// Initialize Supabase client with service role key (bypasses RLS for admin operations)
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.warn('⚠️  Supabase credentials not configured. Database operations will be disabled.');
  console.warn('   Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in your .env file');
}

// Create Supabase client (using service role key for backend operations)
export const supabase: SupabaseClient | null = supabaseUrl && supabaseServiceKey
  ? createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    })
  : null;

// Middleware
// CORS Configuration - Whitelist specific origins
const allowedOrigins = process.env.NODE_ENV === 'production'
  ? [
      'https://antidote.app',
      'https://www.antidote.app',
      process.env.FRONTEND_URL,
    ].filter(Boolean)
  : [
      'http://localhost:3000',
      'http://localhost:5000',
      'http://localhost:8080',
      /^http:\/\/10\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+$/,  // Local network IPs
      /^http:\/\/192\.168\.\d{1,3}\.\d{1,3}:\d+$/,
    ];

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    
    const isAllowed = allowedOrigins.some(allowed => {
      if (typeof allowed === 'string') {
        return origin === allowed;
      }
      if (allowed instanceof RegExp) {
        return allowed.test(origin);
      }
      return false;
    });

    if (isAllowed) {
      callback(null, true);
    } else {
      console.warn(`CORS: Blocked origin: ${origin}`);
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Spotify-Token'],
  maxAge: 86400, // 24 hours
}));
app.use(express.json());

// ============================================================================
// TYPES & INTERFACES
// ============================================================================

export interface SpotifyRequest extends express.Request {
  spotifyToken?: string;
}

export interface SupabaseRequest extends express.Request {
  userId?: string;
}

interface SpotifyError extends Error {
  statusCode?: number;
  body?: {
    error?: {
      status?: number;
      message?: string;
    };
  };
}

interface TrackInput {
  uri?: string;
  id?: string;
  [key: string]: any;
}

interface RecommendationParams {
  seed_tracks?: string[];
  seed_genres?: string[];
  seed_artists?: string[];
  limit?: number;
  market?: string;
  min_energy?: number;
  max_energy?: number;
  target_energy?: number;
  [key: string]: any;
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
 * Middleware to extract and verify Supabase token from request
 * Extracts user ID from JWT token in Authorization header
 */
export async function extractSupabaseToken(
  req: SupabaseRequest,
  res: express.Response,
  next: express.NextFunction
) {
  try {
    // Get user ID from Authorization header (Supabase JWT token)
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        error: 'Authorization token required',
        code: 'AUTH_REQUIRED'
      });
    }

    const token = authHeader.replace('Bearer ', '');
    
    // Verify token and get user ID
    if (!supabase) {
      return res.status(503).json({ 
        error: 'Database not configured',
        code: 'DB_NOT_CONFIGURED'
      });
    }

    // Verify the JWT token and get user
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    
    if (authError || !user) {
      return res.status(401).json({ 
        error: 'Invalid or expired token',
        code: 'INVALID_TOKEN'
      });
    }

    // Attach user ID to request
    req.userId = user.id;
    next();
  } catch (error: unknown) {
    const err = error as Error;
    console.error('Token extraction error:', err);
    return res.status(500).json({ 
      error: 'Failed to verify token',
      code: 'TOKEN_VERIFICATION_ERROR'
    });
  }
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
function handleSpotifyError(error: SpotifyError | unknown, res: express.Response) {
  const spotifyError = error as SpotifyError;
  
  if (spotifyError.statusCode === 401) {
    return res.status(401).json({
      error: 'Spotify token expired or invalid. Please reconnect your account.',
      code: 'TOKEN_EXPIRED',
      requiresReconnect: true
    });
  }
  
  if (spotifyError.statusCode === 403) {
    return res.status(403).json({
      error: 'Insufficient permissions. Please reconnect with required scopes.',
      code: 'INSUFFICIENT_PERMISSIONS'
    });
  }
  
  if (spotifyError.statusCode === 404) {
    return res.status(404).json({
      error: 'Playlist not found or not accessible.',
      code: 'NOT_FOUND'
    });
  }
  
  // Other errors
  return res.status(spotifyError.statusCode || 500).json({
    error: spotifyError.message || 'Spotify API error',
    code: 'SPOTIFY_ERROR'
  });
}

/**
 * Extract Spotify playlist/track ID from URL
 * Supports various Spotify URL formats:
 * - https://open.spotify.com/playlist/37i9dQZF1DX0XUsuxWHRQd
 * - spotify:playlist:37i9dQZF1DX0XUsuxWHRQd
 * - https://open.spotify.com/track/4iV5W9uYEdYUVa79Axb7Rh
 */
function extractSpotifyId(url: string): string | null {
  if (!url || typeof url !== 'string') {
    return null;
  }
  
  // Try standard URL format: /playlist/ID or /track/ID or /album/ID
  let match = url.match(/(?:playlist|track|album)\/([a-zA-Z0-9]+)/);
  if (match) {
    return match[1];
  }
  
  // Try URI format: spotify:playlist:ID
  match = url.match(/spotify:(?:playlist|track|album):([a-zA-Z0-9]+)/);
  if (match) {
    return match[1];
  }
  
  return null;
}

// ============================================================================
// DATABASE HELPER FUNCTIONS
// ============================================================================

/**
 * Ensure user profile exists in database
 * Creates or updates user profile when they authenticate
 */
async function ensureUserProfile(userId: string, email?: string, displayName?: string): Promise<void> {
  if (!supabase) {
    console.warn('Supabase not configured, skipping user profile creation');
    return;
  }

  try {
    // Check if user profile exists
    const { data: existingUser } = await supabase
      .from('users')
      .select('id')
      .eq('id', userId)
      .single();

    if (!existingUser) {
      // Create new user profile
      const { error } = await supabase
        .from('users')
        .insert({
          id: userId,
          email: email || null,
          display_name: displayName || null,
        });

      if (error) {
        console.error('Error creating user profile:', error);
      }
    } else {
      // Update existing profile if email/name provided
      if (email || displayName) {
        const updateData: any = {};
        if (email) updateData.email = email;
        if (displayName) updateData.display_name = displayName;
        updateData.updated_at = new Date().toISOString();

        const { error } = await supabase
          .from('users')
          .update(updateData)
          .eq('id', userId);

        if (error) {
          console.error('Error updating user profile:', error);
        }
      }
    }
  } catch (error) {
    console.error('Error ensuring user profile:', error);
  }
}

/**
 * Save playlist to database
 * Returns playlist database ID
 */
async function savePlaylistToDatabase(
  userId: string,
  spotifyId: string,
  url: string,
  name: string,
  owner: string,
  coverUrl: string | null,
  trackCount: number,
  platform: string = 'spotify'
): Promise<string | null> {
  if (!supabase) {
    console.warn('Supabase not configured, skipping playlist save');
    return null;
  }

  try {
    // Check if playlist already exists for this user
    const { data: existing } = await supabase
      .from('playlists')
      .select('id')
      .eq('user_id', userId)
      .eq('url', url)
      .single();

    if (existing) {
      // Update existing playlist
      const { error } = await supabase
        .from('playlists')
        .update({
          name,
          owner,
          cover_url: coverUrl,
          track_count: trackCount,
          analyzed_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq('id', existing.id);

      if (error) {
        console.error('Error updating playlist:', error);
        return null;
      }
      return existing.id;
    } else {
      // Insert new playlist
      const { data, error } = await supabase
        .from('playlists')
        .insert({
          user_id: userId,
          spotify_id: spotifyId,
          url,
          name,
          owner,
          cover_url: coverUrl,
          track_count: trackCount,
          platform,
          analyzed_at: new Date().toISOString(),
        })
        .select('id')
        .single();

      if (error) {
        console.error('Error saving playlist:', error);
        return null;
      }
      return data?.id || null;
    }
  } catch (error) {
    console.error('Error saving playlist to database:', error);
    return null;
  }
}

/**
 * Save tracks to database
 */
async function saveTracksToDatabase(
  playlistId: string,
  tracks: any[],
  audioFeaturesMap: Map<string, any>
): Promise<void> {
  if (!supabase || !playlistId) {
    return;
  }

  try {
    // Delete existing tracks for this playlist
    await supabase
      .from('tracks')
      .delete()
      .eq('playlist_id', playlistId);

    // Insert tracks in batches
    const batchSize = 100;
    for (let i = 0; i < tracks.length; i += batchSize) {
      const batch = tracks.slice(i, i + batchSize);
      const trackInserts = batch.map((track: any) => {
        const trackId = track.id || track.spotify_id || `track_${Date.now()}_${i}`;
        const features = audioFeaturesMap.get(trackId) || null;
        
        return {
          id: trackId,
          playlist_id: playlistId,
          name: track.name || 'Unknown',
          artists: track.artists || [],
          album: track.album || null,
          album_art_url: track.albumArt || track.album_art_url || null,
          spotify_id: track.id || track.spotify_id || null,
          audio_features: features,
          duration_ms: track.duration_ms || null,
          popularity: track.popularity || null,
          genres: track.genres || [],
        };
      });

      const { error } = await supabase
        .from('tracks')
        .insert(trackInserts);

      if (error) {
        console.error('Error saving tracks batch:', error);
      }
    }
  } catch (error) {
    console.error('Error saving tracks to database:', error);
  }
}

/**
 * Save analysis result to database
 */
async function saveAnalysisToDatabase(
  userId: string,
  playlistId: string,
  analysisData: {
    personalityType: string;
    personalityDescription: string;
    healthScore: number;
    healthStatus: string;
    overallRating: number;
    ratingDescription: string;
    audioDna: any;
    genreDistribution: any[];
    subgenres: string[];
    topTracks: any[];
  }
): Promise<string | null> {
  if (!supabase) {
    console.warn('Supabase not configured, skipping analysis save');
    return null;
  }

  try {
    const { data, error } = await supabase
      .from('analyses')
      .insert({
        user_id: userId,
        playlist_id: playlistId,
        personality_type: analysisData.personalityType,
        personality_description: analysisData.personalityDescription,
        health_score: analysisData.healthScore,
        health_status: analysisData.healthStatus,
        overall_rating: analysisData.overallRating,
        rating_description: analysisData.ratingDescription,
        audio_dna: analysisData.audioDna,
        genre_distribution: analysisData.genreDistribution,
        subgenres: analysisData.subgenres,
        top_tracks: analysisData.topTracks,
      })
      .select('id')
      .single();

    if (error) {
      console.error('Error saving analysis:', error);
      return null;
    }
    return data?.id || null;
  } catch (error) {
    console.error('Error saving analysis to database:', error);
    return null;
  }
}

/**
 * Save battle result to database
 */
async function saveBattleToDatabase(
  userId: string,
  playlist1Id: string,
  playlist2Id: string,
  battleData: {
    compatibilityScore: number;
    winner: string;
    winnerReason?: string;
    sharedArtists: string[];
    sharedGenres: string[];
    sharedTracks: any[];
    audioData: any[];
    playlist1Data: any;
    playlist2Data: any;
  }
): Promise<string | null> {
  if (!supabase) {
    console.warn('Supabase not configured, skipping battle save');
    return null;
  }

  try {
    // Generate winner reason if not provided
    let winnerReason = battleData.winnerReason;
    if (!winnerReason) {
      if (battleData.winner === 'playlist1') {
        winnerReason = `Playlist 1 wins with score ${battleData.playlist1Data.score} vs ${battleData.playlist2Data.score}`;
      } else if (battleData.winner === 'playlist2') {
        winnerReason = `Playlist 2 wins with score ${battleData.playlist2Data.score} vs ${battleData.playlist1Data.score}`;
      } else {
        winnerReason = 'Both playlists are evenly matched';
      }
    }

    const { data, error } = await supabase
      .from('battles')
      .insert({
        user_id: userId,
        playlist1_id: playlist1Id,
        playlist2_id: playlist2Id,
        compatibility_score: battleData.compatibilityScore,
        winner: battleData.winner,
        winner_reason: winnerReason,
        shared_artists: battleData.sharedArtists,
        shared_genres: battleData.sharedGenres,
        shared_tracks: battleData.sharedTracks,
        audio_data: battleData.audioData,
        playlist1_data: battleData.playlist1Data,
        playlist2_data: battleData.playlist2Data,
      })
      .select('id')
      .single();

    if (error) {
      console.error('Error saving battle:', error);
      return null;
    }
    return data?.id || null;
  } catch (error) {
    console.error('Error saving battle to database:', error);
    return null;
  }
}

// ============================================================================
// SPOTIFY OAUTH ENDPOINTS
// ============================================================================

/**
 * GET /api/spotify/authorize
 * Generate Spotify OAuth authorization URL
 */
app.get('/api/spotify/authorize', (req, res) => {
  try {
    const clientId = process.env.SPOTIFY_CLIENT_ID;
    if (!clientId) {
      return res.status(500).json({
        error: 'Spotify Client ID not configured',
        code: 'CONFIG_ERROR'
      });
    }

    const redirectUri = req.query.redirect_uri as string || 'com.antidote.app://auth/callback';
    const state = req.query.state as string || Math.random().toString(36).substring(7);
    
    // Spotify OAuth scopes
    const scopes = [
      'user-read-private',
      'user-read-email',
      'playlist-read-private',
      'playlist-read-collaborative',
      'user-library-read',
      'user-top-read',
      'user-read-recently-played',
      'playlist-modify-public',
      'playlist-modify-private'
    ].join(' ');

    const authUrl = `https://accounts.spotify.com/authorize?` +
      `client_id=${encodeURIComponent(clientId)}&` +
      `response_type=code&` +
      `redirect_uri=${encodeURIComponent(redirectUri)}&` +
      `scope=${encodeURIComponent(scopes)}&` +
      `state=${encodeURIComponent(state)}&` +
      `show_dialog=false`;

    res.json({
      authUrl,
      state
    });
  } catch (error) {
    console.error('Error generating auth URL:', error);
    res.status(500).json({
      error: 'Failed to generate authorization URL',
      code: 'AUTH_URL_ERROR'
    });
  }
});

/**
 * POST /api/spotify/callback
 * Exchange authorization code for access and refresh tokens
 */
app.post('/api/spotify/callback', async (req, res) => {
  try {
    const { code, redirect_uri } = req.body as { code?: string; redirect_uri?: string };
    
    if (!code) {
      return res.status(400).json({
        error: 'Authorization code is required',
        code: 'CODE_REQUIRED'
      });
    }

    const clientId = process.env.SPOTIFY_CLIENT_ID;
    const clientSecret = process.env.SPOTIFY_CLIENT_SECRET;
    const redirectUri = redirect_uri || 'com.antidote.app://auth/callback';

    if (!clientId) {
      return res.status(500).json({
        error: 'Spotify Client ID not configured',
        code: 'CONFIG_ERROR'
      });
    }

    // Note: For user OAuth, we still need client_secret on backend to exchange code for tokens
    // The client_secret is kept secret on the backend and never exposed to frontend
    if (!clientSecret) {
      console.warn('⚠️  SPOTIFY_CLIENT_SECRET not configured. Token exchange will fail.');
      console.warn('   For local development, you can get this from Spotify Developer Dashboard.');
      return res.status(500).json({
        error: 'Spotify Client Secret not configured. Required for token exchange.',
        code: 'CONFIG_ERROR',
        hint: 'Add SPOTIFY_CLIENT_SECRET to your backend .env file'
      });
    }

    // Exchange code for tokens
    const tokenUrl = 'https://accounts.spotify.com/api/token';
    const params = new URLSearchParams();
    params.append('grant_type', 'authorization_code');
    params.append('code', code);
    params.append('redirect_uri', redirectUri);
    params.append('client_id', clientId);
    params.append('client_secret', clientSecret);

    const response = await fetch(tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params.toString(),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Spotify token exchange error:', errorText);
      return res.status(response.status).json({
        error: 'Failed to exchange code for tokens',
        code: 'TOKEN_EXCHANGE_ERROR',
        details: errorText
      });
    }

    const tokenData = await response.json() as {
      access_token: string;
      refresh_token?: string;
      expires_in?: number;
      token_type?: string;
      scope?: string;
    };

    // Return tokens to frontend
    res.json({
      access_token: tokenData.access_token,
      refresh_token: tokenData.refresh_token,
      expires_in: tokenData.expires_in,
      token_type: tokenData.token_type || 'Bearer',
      scope: tokenData.scope
    });
  } catch (error) {
    console.error('Error in token exchange:', error);
    res.status(500).json({
      error: 'Internal server error during token exchange',
      code: 'INTERNAL_ERROR'
    });
  }
});

/**
 * GET /api/spotify/me
 * Get Spotify user profile using access token
 */
app.get('/api/spotify/me', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const userToken = req.spotifyToken;
    
    if (!userToken) {
      return res.status(401).json({
        error: 'Spotify token required',
        code: 'TOKEN_REQUIRED'
      });
    }

    // Create Spotify API with user token
    const spotifyApi = createSpotifyApi(userToken);
    
    // Fetch user profile
    const userProfile = await spotifyApi.getMe();
    
    // Return user info
    res.json({
      id: userProfile.body.id,
      email: userProfile.body.email,
      display_name: userProfile.body.display_name,
      images: userProfile.body.images,
      country: userProfile.body.country,
      product: userProfile.body.product, // premium, free, etc.
      followers: userProfile.body.followers?.total || 0,
    });
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * GET /api/spotify/playlists
 * Get user's Spotify playlists
 */
app.get('/api/spotify/playlists', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const userToken = req.spotifyToken;
    
    if (!userToken) {
      return res.status(401).json({
        error: 'Spotify token required',
        code: 'TOKEN_REQUIRED'
      });
    }

    // Create Spotify API with user token
    const spotifyApi = createSpotifyApi(userToken);
    
    // Fetch all user playlists (handle pagination)
    const allPlaylists: any[] = [];
    let offset = 0;
    const limit = 50;
    
    while (true) {
      const response = await spotifyApi.getUserPlaylists({ limit, offset });
      const playlists = response.body.items;
      if (!playlists || playlists.length === 0) break;
      allPlaylists.push(...playlists);
      offset += limit;
      if (playlists.length < limit) break;
    }
    
    // Format response
    const formattedPlaylists = allPlaylists.map(playlist => ({
      id: playlist.id,
      name: playlist.name,
      description: playlist.description || null,
      images: playlist.images || [],
      owner: playlist.owner?.display_name || 'Unknown',
      trackCount: playlist.tracks?.total || 0,
      public: playlist.public || false,
      url: playlist.external_urls?.spotify || null,
      snapshotId: playlist.snapshot_id || null,
    }));
    
    res.json(formattedPlaylists);
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * POST /api/auth/spotify-signin
 * Create or sign in Supabase user from Spotify OAuth
 * This endpoint creates a Supabase user session after Spotify OAuth
 */
app.post('/api/auth/spotify-signin', async (req, res) => {
  try {
    const { spotifyUser, accessToken, refreshToken } = req.body as {
      spotifyUser?: {
        id: string;
        email?: string;
        display_name?: string;
        images?: any[];
      };
      accessToken?: string;
      refreshToken?: string;
    };

    if (!supabase) {
      return res.status(500).json({
        error: 'Supabase not configured',
        code: 'CONFIG_ERROR'
      });
    }

    if (!spotifyUser || !spotifyUser.id) {
      return res.status(400).json({
        error: 'Spotify user info is required',
        code: 'USER_INFO_REQUIRED'
      });
    }

    // Use Spotify email or generate one from Spotify ID
    const email = spotifyUser.email || `${spotifyUser.id}@spotify.antidote.app`;
    const displayName = spotifyUser.display_name || 'Spotify User';
    const spotifyId = spotifyUser.id;
    const avatarUrl = spotifyUser.images?.[0]?.url || null;

    // Check if user already exists in auth.users
    let userId: string | null = null;
    let userExists = false;

    try {
      // Try to find user by email using admin API
      const { data: existingUsers, error: listError } = await supabase!.auth.admin.listUsers();
      
      if (!listError && existingUsers) {
        const existingUser = existingUsers.users.find(u => 
          u.email === email || u.user_metadata?.spotify_id === spotifyId
        );
        
        if (existingUser) {
          userId = existingUser.id;
          userExists = true;
          
          // Update user metadata
          await supabase!.auth.admin.updateUserById(userId, {
            user_metadata: {
              ...existingUser.user_metadata,
              display_name: displayName,
              avatar_url: avatarUrl,
              spotify_id: spotifyId,
              provider: 'spotify',
            },
          });
        }
      }
    } catch (err) {
      console.warn('Error checking existing users:', err);
    }

    // Create new user if doesn't exist
    if (!userExists || !userId) {
      // Generate a secure random password (user won't need it, but Supabase requires it)
      const randomPassword = Math.random().toString(36).slice(-16) + 
                            Math.random().toString(36).slice(-16).toUpperCase() + 
                            '!@#';
      
      const { data: authData, error: authError } = await supabase!.auth.admin.createUser({
        email: email,
        password: randomPassword,
        email_confirm: true, // Auto-confirm email for OAuth users
        user_metadata: {
          display_name: displayName,
          avatar_url: avatarUrl,
          spotify_id: spotifyId,
          provider: 'spotify',
        },
      });

      if (authError || !authData.user) {
        return res.status(500).json({
          error: 'Failed to create user',
          code: 'USER_CREATION_ERROR',
          details: authError?.message
        });
      }

      userId = authData.user.id;
    }

    if (!userId) {
      return res.status(500).json({
        error: 'Failed to create or find user',
        code: 'USER_ERROR'
      });
    }

    // Ensure user profile exists in users table (userId is guaranteed to be non-null here)
    await ensureUserProfile(userId!, email, displayName);

    if (!userId) {
      return res.status(500).json({
        error: 'Failed to create or find user',
        code: 'USER_ERROR'
      });
    }

    // Generate a magic link for the user to sign in
    // The frontend will use this to establish a session
    const { data: linkData, error: linkError } = await supabase!.auth.admin.generateLink({
      type: 'magiclink',
      email: email,
    });

    // Return user info
    // Frontend will use the magic link to sign in
    res.json({
      userId,
      email,
      displayName,
      spotifyId,
      avatarUrl,
      magicLink: linkData?.properties?.action_link || null,
      // Also return the hashed token for direct session creation if needed
      hashedToken: linkData?.properties?.hashed_token || null,
    });
  } catch (error) {
    console.error('Error in Spotify signin:', error);
    res.status(500).json({
      error: 'Internal server error during signin',
      code: 'INTERNAL_ERROR'
    });
  }
});

/**
 * POST /api/spotify/refresh
 * Refresh Spotify access token using refresh token
 */
app.post('/api/spotify/refresh', async (req, res) => {
  try {
    const { refresh_token } = req.body as { refresh_token?: string };
    
    if (!refresh_token) {
      return res.status(400).json({
        error: 'Refresh token is required',
        code: 'REFRESH_TOKEN_REQUIRED'
      });
    }

    const clientId = process.env.SPOTIFY_CLIENT_ID;
    const clientSecret = process.env.SPOTIFY_CLIENT_SECRET;

    if (!clientId || !clientSecret) {
      return res.status(500).json({
        error: 'Spotify credentials not configured',
        code: 'CONFIG_ERROR'
      });
    }

    // Refresh token
    const tokenUrl = 'https://accounts.spotify.com/api/token';
    const params = new URLSearchParams();
    params.append('grant_type', 'refresh_token');
    params.append('refresh_token', refresh_token);
    params.append('client_id', clientId);
    params.append('client_secret', clientSecret);

    const response = await fetch(tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params.toString(),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Spotify token refresh error:', errorText);
      return res.status(response.status).json({
        error: 'Failed to refresh token',
        code: 'TOKEN_REFRESH_ERROR',
        details: errorText
      });
    }

    const tokenData = await response.json() as {
      access_token: string;
      refresh_token?: string;
      expires_in?: number;
      token_type?: string;
      scope?: string;
    };

    // Return new tokens
    res.json({
      access_token: tokenData.access_token,
      refresh_token: tokenData.refresh_token || refresh_token, // Spotify may not return new refresh token
      expires_in: tokenData.expires_in,
      token_type: tokenData.token_type || 'Bearer',
      scope: tokenData.scope
    });
  } catch (error) {
    console.error('Error in token refresh:', error);
    res.status(500).json({
      error: 'Internal server error during token refresh',
      code: 'INTERNAL_ERROR'
    });
  }
});

// ============================================================================
// SUPABASE AUTH PROXY ENDPOINTS
// ============================================================================

/**
 * POST /api/auth/signup
 * Proxy for Supabase sign up (works around DNS resolution issues on mobile)
 */
app.post('/api/auth/signup', async (req, res) => {
  try {
    const { email, password } = req.body as { email?: string; password?: string };
    
    if (!email || !password) {
      return res.status(400).json({
        error: 'Email and password are required',
        code: 'MISSING_CREDENTIALS'
      });
    }

    if (!supabase) {
      return res.status(500).json({
        error: 'Supabase not configured',
        code: 'CONFIG_ERROR'
      });
    }

    // Use Supabase admin API to create user
    const { data: authData, error: authError } = await supabase.auth.admin.createUser({
      email: email,
      password: password,
      email_confirm: true, // Auto-confirm for testing
    });

    if (authError || !authData.user) {
      return res.status(400).json({
        error: authError?.message || 'Failed to create user',
        code: 'SIGNUP_ERROR'
      });
    }

    const userId = authData.user.id;

    // Ensure user profile exists
    await ensureUserProfile(userId, email);

    // Generate session token for the user
    const { data: sessionData, error: sessionError } = await supabase.auth.admin.generateLink({
      type: 'magiclink',
      email: email,
    });

    if (sessionError || !sessionData) {
      return res.status(500).json({
        error: 'Failed to generate session',
        code: 'SESSION_ERROR'
      });
    }

    // Return user info and session token
    res.json({
      user: {
        id: userId,
        email: email,
      },
      session: {
        access_token: sessionData.properties?.hashed_token || null,
        refresh_token: null,
        expires_in: 3600,
      },
    });
  } catch (error) {
    console.error('Error in signup:', error);
    res.status(500).json({
      error: 'Internal server error during signup',
      code: 'INTERNAL_ERROR'
    });
  }
});

/**
 * POST /api/auth/signin
 * Proxy for Supabase sign in (works around DNS resolution issues on mobile)
 */
app.post('/api/auth/signin', async (req, res) => {
  try {
    const { email, password } = req.body as { email?: string; password?: string };
    
    if (!email || !password) {
      return res.status(400).json({
        error: 'Email and password are required',
        code: 'MISSING_CREDENTIALS'
      });
    }

    if (!supabase) {
      return res.status(500).json({
        error: 'Supabase not configured',
        code: 'CONFIG_ERROR'
      });
    }

    // Try to sign in using Supabase auth
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email: email,
      password: password,
    });

    if (authError || !authData.user || !authData.session) {
      return res.status(401).json({
        error: authError?.message || 'Invalid credentials',
        code: 'SIGNIN_ERROR'
      });
    }

    // Ensure user profile exists
    await ensureUserProfile(authData.user.id, email);

    // Return user info and session
    res.json({
      user: {
        id: authData.user.id,
        email: authData.user.email,
      },
      session: {
        access_token: authData.session.access_token,
        refresh_token: authData.session.refresh_token,
        expires_in: authData.session.expires_in || 3600,
      },
    });
  } catch (error) {
    console.error('Error in signin:', error);
    res.status(500).json({
      error: 'Internal server error during signin',
      code: 'INTERNAL_ERROR'
    });
  }
});

// ============================================================================
// API ENDPOINTS
// ============================================================================

/**
 * POST /api/analyze
 * Analyze a Spotify playlist
 * Rate limited: 20 requests per 15 minutes for unauthenticated users
 */
app.post('/api/analyze', 
  rateLimitUnauthenticated({ windowMs: 15 * 60 * 1000, max: 20, message: 'Too many analysis requests. Please sign in for unlimited access or try again in 15 minutes.' }),
  extractSpotifyToken, 
  async (req: SpotifyRequest, res) => {
  try {
    const { url } = req.body as { url?: string };
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
    
    // Fetch all tracks (handle pagination)
    const allTracks: any[] = [];
    let offset = 0;
    const limit = 100;
    
    while (true) {
      const tracksResponse = await spotifyApi.getPlaylistTracks(playlistId, {
        limit,
        offset
      });
      
      const tracks = tracksResponse.body.items;
      if (!tracks || tracks.length === 0) break;
      
      allTracks.push(...tracks);
      offset += limit;
      
      if (tracks.length < limit || allTracks.length >= tracksResponse.body.total) break;
    }
    
    // Extract track IDs (filter out null tracks)
    const trackIds = allTracks
      .map(item => item.track?.id)
      .filter((id): id is string => typeof id === 'string' && id.length > 0);
    
    if (trackIds.length === 0) {
      return res.status(400).json({ 
        error: 'No valid tracks found in playlist' 
      });
    }
    
    // Get audio features for all tracks (Spotify allows up to 100 at a time)
    const audioFeaturesList: any[] = [];
    for (let i = 0; i < trackIds.length; i += 100) {
      const batch = trackIds.slice(i, i + 100);
      const featuresResponse = await spotifyApi.getAudioFeaturesForTracks(batch);
      if (featuresResponse.body.audio_features) {
        audioFeaturesList.push(...featuresResponse.body.audio_features.filter((f: any) => f !== null));
      }
    }
    
    if (audioFeaturesList.length === 0) {
      return res.status(400).json({ 
        error: 'Could not fetch audio features for tracks' 
      });
    }
    
    // Calculate Audio DNA averages first (needed for personality and genre fallback)
    const avgEnergy = audioFeaturesList.reduce((sum, f) => sum + (f.energy || 0), 0) / audioFeaturesList.length;
    const avgDanceability = audioFeaturesList.reduce((sum, f) => sum + (f.danceability || 0), 0) / audioFeaturesList.length;
    const avgValence = audioFeaturesList.reduce((sum, f) => sum + (f.valence || 0), 0) / audioFeaturesList.length;
    const avgAcousticness = audioFeaturesList.reduce((sum, f) => sum + (f.acousticness || 0), 0) / audioFeaturesList.length;
    const avgInstrumentalness = audioFeaturesList.reduce((sum, f) => sum + (f.instrumentalness || 0), 0) / audioFeaturesList.length;
    const avgTempo = audioFeaturesList.reduce((sum, f) => sum + (f.tempo || 0), 0) / audioFeaturesList.length;
    
    // Audio DNA (converted to 0-100 scale)
    const audioDna = {
      energy: Math.round(avgEnergy * 100),
      danceability: Math.round(avgDanceability * 100),
      valence: Math.round(avgValence * 100),
      acousticness: Math.round(avgAcousticness * 100),
      instrumentalness: Math.round(avgInstrumentalness * 100),
      // Normalize tempo to 0-100 scale (assuming 60-200 BPM range)
      tempo: Math.min(100, Math.max(0, Math.round(((avgTempo - 60) / 140) * 100))),
    };
    
    // Determine Personality
    let personalityType = 'Trend-Aware';
    let personalityDescription = 'You have your finger on the pulse. Your playlist keeps the energy high and the vibes current.';
    
    if (avgInstrumentalness > 0.3 || (avgEnergy > 0.8 && avgDanceability < 0.4)) {
      personalityType = 'The Experimentalist';
      personalityDescription = 'You explore the outer edges of sound. Conventions don\'t bind you; you seek textures and atmospheres over catchy hooks.';
    } else if (avgAcousticness > 0.5 || avgValence < 0.3 || avgValence > 0.8) {
      personalityType = 'Mood-Driven';
      personalityDescription = 'Music is an emotional amplifier for you. You curate soundscapes that perfectly match or alter your internal state.';
    } else if (avgEnergy > 0.4 && avgAcousticness > 0.3) {
      personalityType = 'The Eclectic';
      personalityDescription = 'Why choose one lane? You cruise through genres with ease, finding the common thread between folk, pop, and rock.';
    }
    
    // Calculate Genre Distribution from actual artist data
    const genreMap: { [key: string]: number } = {};
    const artistIds = new Set<string>();
    
    // Collect unique artist IDs
    allTracks.forEach((item: any) => {
      const track = item.track;
      if (track?.artists) {
        track.artists.forEach((artist: any) => {
          if (artist.id) artistIds.add(artist.id);
        });
      }
    });
    
    // Fetch artist details to get genres (batch in groups of 50)
    const artistIdArray = Array.from(artistIds);
    const artistGenres: string[] = [];
    
    for (let i = 0; i < artistIdArray.length; i += 50) {
      const batch = artistIdArray.slice(i, i + 50);
      try {
        const artistsResponse = await spotifyApi.getArtists(batch);
        if (artistsResponse.body.artists) {
          artistsResponse.body.artists.forEach((artist: any) => {
            if (artist.genres && Array.isArray(artist.genres)) {
              artistGenres.push(...artist.genres);
            }
          });
        }
      } catch (err) {
        // If artist lookup fails, continue with simplified approach
        console.warn('Failed to fetch some artist genres:', err);
      }
    }
    
    // Count genre occurrences
    artistGenres.forEach(genre => {
      // Normalize genre names (capitalize first letter)
      const normalized = genre.split(' ').map(word => 
        word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
      ).join(' ');
      genreMap[normalized] = (genreMap[normalized] || 0) + 1;
    });
    
    // If no genres found, use simplified distribution based on audio features
    let genreDistribution: { name: string; value: number }[];
    if (Object.keys(genreMap).length === 0) {
      // Fallback: estimate genres from audio features (return percentages)
      genreDistribution = [];
      if (avgDanceability > 0.6 && avgEnergy > 0.6) {
        genreDistribution.push({ name: 'Pop', value: 40 }); // 40%
      }
      if (avgEnergy > 0.7 && avgAcousticness < 0.3) {
        genreDistribution.push({ name: 'Electronic', value: 30 }); // 30%
      }
      if (avgAcousticness > 0.4) {
        genreDistribution.push({ name: 'Acoustic', value: 30 }); // 30%
      }
      if (avgEnergy > 0.5 && avgDanceability < 0.5) {
        genreDistribution.push({ name: 'Rock', value: 30 }); // 30%
      }
      
      // Ensure we have at least some distribution
      if (genreDistribution.length === 0) {
        genreDistribution = [
          { name: 'Pop', value: 30 }, // 30%
          { name: 'Rock', value: 25 }, // 25%
          { name: 'Electronic', value: 20 }, // 20%
        ];
      }
    } else {
      // Convert genre map to array and sort by count
      // Calculate percentages based on total track count
      const totalTracks = trackIds.length;
      if (totalTracks > 0) {
        genreDistribution = Object.entries(genreMap)
          .map(([name, count]) => ({ 
            name, 
            value: Math.round((count / totalTracks) * 100) // Convert to percentage
          }))
          .sort((a, b) => b.value - a.value)
          .slice(0, 10); // Top 10 genres
      } else {
        genreDistribution = [];
      }
    }
    
    // Extract subgenres (genres that appear less frequently)
    let subgenres: string[] = [];
    if (Object.keys(genreMap).length > 0) {
      const maxValue = Math.max(...Object.values(genreMap) as number[]);
      subgenres = Object.entries(genreMap)
        .filter(([name, value]) => (value as number) < maxValue * 0.5)
        .sort((a, b) => (b[1] as number) - (a[1] as number))
        .slice(0, 6)
        .map(([name]) => name);
    }
    
    // Calculate Health Score
    const energyStdDev = Math.sqrt(
      audioFeaturesList.reduce((sum, f) => {
        const diff = (f.energy || 0) - avgEnergy;
        return sum + diff * diff;
      }, 0) / audioFeaturesList.length
    );
    
    const flowScore = energyStdDev < 0.2 ? 100 : Math.max(0, 100 - ((energyStdDev - 0.2) * 200));
    const varietyScore = trackIds.length > 0 
      ? Math.min(100, (genreDistribution.length / trackIds.length) * 500)
      : 0;
    const engagementScore = avgDanceability * 100;
    const healthScore = Math.round((flowScore * 0.4) + (varietyScore * 0.3) + (engagementScore * 0.3));
    
    let healthStatus = 'Needs Work';
    if (healthScore >= 90) healthStatus = 'Exceptional';
    else if (healthScore >= 75) healthStatus = 'Great';
    else if (healthScore >= 60) healthStatus = 'Good';
    else if (healthScore >= 40) healthStatus = 'Average';
    
    // Calculate Overall Rating
    let overallRating = healthScore / 20.0;
    if (trackIds.length < 10) overallRating *= 0.9;
    if (trackIds.length > 500) overallRating *= 0.95;
    overallRating = Math.max(1.0, Math.min(5.0, overallRating));
    
    let ratingDescription = 'Solid collection.';
    if (overallRating >= 4.8) ratingDescription = 'Masterpiece curation.';
    else if (overallRating >= 4.5) ratingDescription = 'Highly curated selection.';
    else if (overallRating >= 4.0) ratingDescription = 'Well balanced mix.';
    else if (overallRating >= 3.0) ratingDescription = 'Good potential.';
    
    // Get Top Tracks (first 5 tracks with album art)
    const topTracks = allTracks.slice(0, 5).map((item: any) => {
      const track = item.track;
      return {
        name: track?.name || 'Unknown',
        artist: track?.artists?.[0]?.name || 'Unknown',
        albumArt: track?.album?.images?.[0]?.url || null,
      };
    });
    
    // Build complete analysis result
    const analysisResult = {
      playlistName: playlist.body.name,
      owner: playlist.body.owner?.display_name || 'Unknown',
      coverUrl: playlist.body.images?.[0]?.url,
      trackCount: trackIds.length,
      audioDna,
      personalityType,
      personalityDescription,
      genreDistribution,
      subgenres,
      healthScore,
      healthStatus,
      overallRating: Math.round(overallRating * 10) / 10,
      ratingDescription,
      topTracks,
    };
    
    // Save to database if user is authenticated
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ') && supabase) {
      try {
        const token = authHeader.replace('Bearer ', '');
        const { data: { user } } = await supabase.auth.getUser(token);
        
        if (user) {
          // Ensure user profile exists
          await ensureUserProfile(user.id, user.email, user.user_metadata?.display_name);
          
          // Save playlist
          const dbPlaylistId = await savePlaylistToDatabase(
            user.id,
            playlistId,
            url,
            playlist.body.name,
            playlist.body.owner?.display_name || 'Unknown',
            playlist.body.images?.[0]?.url || null,
            trackIds.length
          );
          
          if (dbPlaylistId) {
            // Save tracks
            const audioFeaturesMap = new Map<string, any>();
            audioFeaturesList.forEach((features, index) => {
              if (trackIds[index]) {
                audioFeaturesMap.set(trackIds[index], features);
              }
            });
            
            const tracksForDb = allTracks
              .map((item: any) => item.track)
              .filter((t: any) => t && t.id)
              .map((t: any) => ({
                id: t.id,
                name: t.name,
                artists: (t.artists || []).map((a: any) => a.name),
                album: t.album?.name,
                albumArt: t.album?.images?.[0]?.url,
                duration_ms: t.duration_ms,
                popularity: t.popularity,
              }));
            
            await saveTracksToDatabase(dbPlaylistId, tracksForDb, audioFeaturesMap);
            
            // Save analysis
            await saveAnalysisToDatabase(user.id, dbPlaylistId, {
              personalityType,
              personalityDescription,
              healthScore,
              healthStatus,
              overallRating: Math.round(overallRating * 10) / 10,
              ratingDescription,
              audioDna,
              genreDistribution,
              subgenres,
              topTracks,
            });
          }
        }
      } catch (dbError) {
        // Log error but don't fail the request
        console.error('Error saving analysis to database:', dbError);
      }
    }
    
    res.json(analysisResult);
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * POST /api/battle
 * Battle two playlists
 * Rate limited: 20 requests per 15 minutes for unauthenticated users
 */
app.post('/api/battle', 
  rateLimitUnauthenticated({ windowMs: 15 * 60 * 1000, max: 20, message: 'Too many battle requests. Please sign in for unlimited access or try again in 15 minutes.' }),
  extractSpotifyToken, 
  async (req: SpotifyRequest, res) => {
  try {
    const { url1, url2 } = req.body as { url1?: string; url2?: string };
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
    
    // Fetch all tracks from both playlists
    const fetchAllTracks = async (playlistId: string) => {
      const allTracks: any[] = [];
      let offset = 0;
      const limit = 100;
      
      while (true) {
        const tracksResponse = await spotifyApi.getPlaylistTracks(playlistId, { limit, offset });
        const tracks = tracksResponse.body.items;
        if (!tracks || tracks.length === 0) break;
        allTracks.push(...tracks);
        offset += limit;
        if (tracks.length < limit || allTracks.length >= tracksResponse.body.total) break;
      }
      return allTracks;
    };
    
    const [tracks1, tracks2] = await Promise.all([
      fetchAllTracks(playlist1Id),
      fetchAllTracks(playlist2Id),
    ]);
    
    // Extract track data
    const trackData1 = tracks1
      .map(item => item.track)
      .filter(t => t && t.id)
      .map(t => ({
        id: t.id,
        name: t.name,
        artists: (t.artists || []).map((a: any) => a.name),
        album: t.album?.name,
        albumArt: t.album?.images?.[0]?.url,
      }));
    
    const trackData2 = tracks2
      .map(item => item.track)
      .filter(t => t && t.id)
      .map(t => ({
        id: t.id,
        name: t.name,
        artists: (t.artists || []).map((a: any) => a.name),
        album: t.album?.name,
        albumArt: t.album?.images?.[0]?.url,
      }));
    
    // Get audio features for both playlists
    const getAudioFeatures = async (trackIds: string[]) => {
      const features: any[] = [];
      for (let i = 0; i < trackIds.length; i += 100) {
        const batch = trackIds.slice(i, i + 100);
        const response = await spotifyApi.getAudioFeaturesForTracks(batch);
        if (response.body.audio_features) {
          features.push(...response.body.audio_features.filter((f: any) => f !== null));
        }
      }
      return features;
    };
    
    const trackIds1 = trackData1.map(t => t.id);
    const trackIds2 = trackData2.map(t => t.id);
    
    const [features1, features2] = await Promise.all([
      getAudioFeatures(trackIds1),
      getAudioFeatures(trackIds2),
    ]);
    
    // Calculate compatibility score using weighted cosine similarity
    const calculateCompatibility = (f1: any[], f2: any[]) => {
      if (f1.length === 0 || f2.length === 0) return 0;
      
      const avg = (features: any[], key: string) => 
        features.reduce((sum, f) => sum + (f[key] || 0), 0) / features.length;
      
      const avg1 = {
        energy: avg(f1, 'energy'),
        danceability: avg(f1, 'danceability'),
        valence: avg(f1, 'valence'),
        acousticness: avg(f1, 'acousticness'),
        instrumentalness: avg(f1, 'instrumentalness'),
      };
      
      const avg2 = {
        energy: avg(f2, 'energy'),
        danceability: avg(f2, 'danceability'),
        valence: avg(f2, 'valence'),
        acousticness: avg(f2, 'acousticness'),
        instrumentalness: avg(f2, 'instrumentalness'),
      };
      
      const weights = { energy: 0.25, danceability: 0.20, valence: 0.20, acousticness: 0.15, instrumentalness: 0.20 };
      
      let dotProduct = 0;
      let mag1 = 0;
      let mag2 = 0;
      
      Object.entries(weights).forEach(([key, weight]) => {
        const val1 = avg1[key as keyof typeof avg1];
        const val2 = avg2[key as keyof typeof avg2];
        dotProduct += val1 * val2 * weight;
        mag1 += val1 * val1 * weight;
        mag2 += val2 * val2 * weight;
      });
      
      if (mag1 === 0 || mag2 === 0) return 0;
      
      const similarity = dotProduct / (Math.sqrt(mag1) * Math.sqrt(mag2));
      const sigmoid = 1 / (1 + Math.exp(-5 * (similarity - 0.5)));
      return Math.round(sigmoid * 100);
    };
    
    const compatibilityScore = calculateCompatibility(features1, features2);
    
    // Find shared artists
    const artists1 = new Set(trackData1.flatMap(t => t.artists));
    const artists2 = new Set(trackData2.flatMap(t => t.artists));
    const sharedArtists = Array.from(artists1).filter(a => artists2.has(a));
    
    // Find shared genres (simplified - would need artist genre lookup for real implementation)
    const sharedGenres: string[] = [];
    
    // Find shared tracks
    const trackIds1Set = new Set(trackIds1);
    const trackIds2Set = new Set(trackIds2);
    const sharedTrackIds = trackIds1.filter(id => trackIds2Set.has(id));
    const sharedTracks = sharedTrackIds.map(id => {
      const track = trackData1.find(t => t.id === id);
      return {
        title: track?.name || 'Unknown',
        artist: track?.artists?.[0] || 'Unknown',
        spotifyId: id,
        uri: `spotify:track:${id}`,
      };
    });
    
    // Calculate playlist scores (based on health score logic)
    const calculateScore = (features: any[]) => {
      if (features.length === 0) return 0;
      const avgEnergy = features.reduce((sum, f) => sum + (f.energy || 0), 0) / features.length;
      const avgDanceability = features.reduce((sum, f) => sum + (f.danceability || 0), 0) / features.length;
      
      const energyStdDev = Math.sqrt(
        features.reduce((sum, f) => {
          const diff = (f.energy || 0) - avgEnergy;
          return sum + diff * diff;
        }, 0) / features.length
      );
      
      const flowScore = energyStdDev < 0.2 ? 100 : Math.max(0, 100 - ((energyStdDev - 0.2) * 200));
      const engagementScore = avgDanceability * 100;
      return Math.round((flowScore * 0.5) + (engagementScore * 0.5));
    };
    
    const score1 = calculateScore(features1);
    const score2 = calculateScore(features2);
    
    // Determine winner
    let winner = 'tie';
    if (score1 > score2) winner = 'playlist1';
    else if (score2 > score1) winner = 'playlist2';
    
    // Audio data for visualization
    const audioData = [
      {
        playlist: 'playlist1',
        energy: features1.length > 0 ? features1.reduce((sum, f) => sum + (f.energy || 0), 0) / features1.length : 0,
        danceability: features1.length > 0 ? features1.reduce((sum, f) => sum + (f.danceability || 0), 0) / features1.length : 0,
        valence: features1.length > 0 ? features1.reduce((sum, f) => sum + (f.valence || 0), 0) / features1.length : 0,
        acousticness: features1.length > 0 ? features1.reduce((sum, f) => sum + (f.acousticness || 0), 0) / features1.length : 0,
        tempo: features1.length > 0 ? features1.reduce((sum, f) => sum + (f.tempo || 0), 0) / features1.length : 0,
      },
      {
        playlist: 'playlist2',
        energy: features2.length > 0 ? features2.reduce((sum, f) => sum + (f.energy || 0), 0) / features2.length : 0,
        danceability: features2.length > 0 ? features2.reduce((sum, f) => sum + (f.danceability || 0), 0) / features2.length : 0,
        valence: features2.length > 0 ? features2.reduce((sum, f) => sum + (f.valence || 0), 0) / features2.length : 0,
        acousticness: features2.length > 0 ? features2.reduce((sum, f) => sum + (f.acousticness || 0), 0) / features2.length : 0,
        tempo: features2.length > 0 ? features2.reduce((sum, f) => sum + (f.tempo || 0), 0) / features2.length : 0,
      },
    ];
    
    const battleResult = {
      compatibilityScore,
      winner,
      playlist1: {
        name: playlist1.body.name,
        owner: playlist1.body.owner?.display_name || 'Unknown',
        image: playlist1.body.images?.[0]?.url,
        score: score1,
        tracks: trackIds1.length,
      },
      playlist2: {
        name: playlist2.body.name,
        owner: playlist2.body.owner?.display_name || 'Unknown',
        image: playlist2.body.images?.[0]?.url,
        score: score2,
        tracks: trackIds2.length,
      },
      sharedArtists,
      sharedGenres,
      sharedTracks,
      audioData,
    };
    
    // Save to database if user is authenticated
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ') && supabase) {
      try {
        const token = authHeader.replace('Bearer ', '');
        const { data: { user } } = await supabase.auth.getUser(token);
        
        if (user) {
          // Ensure user profile exists
          await ensureUserProfile(user.id, user.email, user.user_metadata?.display_name);
          
          // Save both playlists
          const dbPlaylist1Id = await savePlaylistToDatabase(
            user.id,
            playlist1Id,
            url1,
            playlist1.body.name,
            playlist1.body.owner?.display_name || 'Unknown',
            playlist1.body.images?.[0]?.url || null,
            trackIds1.length
          );
          
          const dbPlaylist2Id = await savePlaylistToDatabase(
            user.id,
            playlist2Id,
            url2,
            playlist2.body.name,
            playlist2.body.owner?.display_name || 'Unknown',
            playlist2.body.images?.[0]?.url || null,
            trackIds2.length
          );
          
          if (dbPlaylist1Id && dbPlaylist2Id) {
            // Save battle
            await saveBattleToDatabase(
              user.id,
              dbPlaylist1Id,
              dbPlaylist2Id,
              {
                compatibilityScore,
                winner,
                sharedArtists,
                sharedGenres,
                sharedTracks,
                audioData,
                playlist1Data: battleResult.playlist1,
                playlist2Data: battleResult.playlist2,
              }
            );
          }
        }
      } catch (dbError) {
        // Log error but don't fail the request
        console.error('Error saving battle to database:', dbError);
      }
    }
    
    res.json(battleResult);
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * GET /api/recommendations/strategies
 * List available recommendation strategies
 */
app.get('/api/recommendations/strategies', (req, res) => {
  res.json([
    {
      id: 'best_next',
      name: 'Best Next Track',
      description: 'AI picks the perfect next song based on current momentum',
      icon: '💡',
    },
    {
      id: 'mood_safe',
      name: 'Mood-Safe Pick',
      description: 'Maintains your current vibe without jarring changes',
      icon: '❤️',
    },
    {
      id: 'rare_match',
      name: 'Rare Match For You',
      description: 'Hidden gems that align with your unique taste',
      icon: '🧭',
    },
    {
      id: 'return_familiar',
      name: 'Return To Familiar',
      description: 'Deep cuts from artists you already love',
      icon: '🔄',
    },
    {
      id: 'short_session',
      name: 'Short Session Mode',
      description: 'Perfect tracks for quick 5-10 minute breaks',
      icon: '🎵',
    },
    {
      id: 'energy_adjust',
      name: 'Energy Adjustment',
      description: 'Gradually shift the energy up or down',
      icon: '⚡',
    },
    {
      id: 'professional_discovery',
      name: 'Professional Discovery',
      description: 'Multi-source AI analysis for sophisticated recommendations',
      icon: '✨',
    },
    {
      id: 'taste_expansion',
      name: 'Taste Expansion',
      description: 'Bridge to new genres while respecting your preferences',
      icon: '🌉',
    },
    {
      id: 'deep_cuts',
      name: 'Deep Cuts',
      description: 'Hidden gems from your favorite artists',
      icon: '💎',
    },
    {
      id: 'continue_session',
      name: 'Continue Session',
      description: 'Based on your recently played tracks',
      icon: '▶️',
    },
    {
      id: 'from_library',
      name: 'From Your Library',
      description: 'Deep cuts from your saved tracks',
      icon: '📚',
    },
  ]);
});

/**
 * GET /api/recommendations
 * Get music recommendations using one of 6 strategies
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
    const strategyType = type as string || 'best_next';
    
    // Build recommendation parameters
    const recommendationParams: RecommendationParams = {
      limit: 20,
    };
    
    // Strategy 1: Best Next Track - Cosine similarity on 8D audio vector
    if (strategyType === 'best_next') {
      if (playlistId) {
        const playlistIdExtracted = extractSpotifyId(playlistId as string);
        if (playlistIdExtracted) {
          // Get last few tracks from playlist for seed
          const tracksResponse = await spotifyApi.getPlaylistTracks(playlistIdExtracted, { limit: 5 });
          const trackIds = tracksResponse.body.items
            .map((item: any) => item.track?.id)
            .filter((id: any): id is string => typeof id === 'string');
          if (trackIds.length > 0) {
            recommendationParams.seed_tracks = trackIds.slice(0, 5);
          }
        }
      } else if (seed_tracks) {
        recommendationParams.seed_tracks = (seed_tracks as string).split(',').slice(0, 5);
      } else {
        return res.status(400).json({ error: 'Playlist ID or seed tracks required for best_next strategy' });
      }
    }
    
    // Strategy 2: Mood-Safe Pick - Maintain valence ±0.1, energy ±0.2
    else if (strategyType === 'mood_safe') {
      if (playlistId) {
        const playlistIdExtracted = extractSpotifyId(playlistId as string);
        if (playlistIdExtracted) {
          // Get tracks and audio features
          const tracksResponse = await spotifyApi.getPlaylistTracks(playlistIdExtracted, { limit: 10 });
          const trackIds = tracksResponse.body.items
            .map((item: any) => item.track?.id)
            .filter((id: any): id is string => typeof id === 'string');
          
          if (trackIds.length > 0) {
            // Get audio features
            const featuresResponse = await spotifyApi.getAudioFeaturesForTracks(trackIds.slice(0, 10));
            const features = featuresResponse.body.audio_features.filter((f: any) => f !== null);
            
            if (features.length > 0) {
              const avgValence = features.reduce((sum: number, f: any) => sum + (f.valence || 0), 0) / features.length;
              const avgEnergy = features.reduce((sum: number, f: any) => sum + (f.energy || 0), 0) / features.length;
              
              recommendationParams.seed_tracks = trackIds.slice(0, 5);
              recommendationParams.target_energy = avgEnergy;
              recommendationParams.min_energy = Math.max(0, avgEnergy - 0.2);
              recommendationParams.max_energy = Math.min(1, avgEnergy + 0.2);
              // Valence constraints would need min_valence/max_valence but Spotify API doesn't support this directly
              // So we use seed tracks to maintain mood
            }
          }
        }
      } else {
        return res.status(400).json({ error: 'Playlist ID required for mood_safe strategy' });
      }
    }
    
    // Strategy 3: Rare Match For You - Low popularity (<30) with high similarity (>0.85)
    else if (strategyType === 'rare_match') {
      if (playlistId) {
        const playlistIdExtracted = extractSpotifyId(playlistId as string);
        if (playlistIdExtracted) {
          const tracksResponse = await spotifyApi.getPlaylistTracks(playlistIdExtracted, { limit: 5 });
          const trackIds = tracksResponse.body.items
            .map((item: any) => item.track?.id)
            .filter((id: any): id is string => typeof id === 'string');
          if (trackIds.length > 0) {
            recommendationParams.seed_tracks = trackIds.slice(0, 5);
            // Note: Spotify API doesn't directly support popularity filtering in recommendations
            // This would need post-filtering or a different approach
          }
        }
      } else {
        recommendationParams.seed_genres = ['indie', 'alternative', 'underground'];
      }
    }
    
    // Strategy 4: Return To Familiar - Same artists, different tracks
    else if (strategyType === 'return_familiar') {
      if (playlistId) {
        const playlistIdExtracted = extractSpotifyId(playlistId as string);
        if (playlistIdExtracted) {
          const tracksResponse = await spotifyApi.getPlaylistTracks(playlistIdExtracted, { limit: 50 });
          const tracks = tracksResponse.body.items
            .map((item: any) => item.track)
            .filter((t: any) => t && t.artists && t.artists.length > 0);
          
          // Extract unique artist IDs
          const artistIds = new Set<string>();
          tracks.forEach((track: any) => {
            track.artists.forEach((artist: any) => {
              if (artist.id) artistIds.add(artist.id);
            });
          });
          
          if (artistIds.size > 0) {
            recommendationParams.seed_artists = Array.from(artistIds).slice(0, 5);
          } else {
            return res.status(400).json({ error: 'No artists found in playlist' });
          }
        }
      } else if (seed_artists) {
        recommendationParams.seed_artists = (seed_artists as string).split(',').slice(0, 5);
      } else {
        return res.status(400).json({ error: 'Playlist ID or seed artists required for return_familiar strategy' });
      }
    }
    
    // Strategy 5: Short Session Mode - Duration 5-10 minutes, high engagement
    else if (strategyType === 'short_session') {
      if (playlistId) {
        const playlistIdExtracted = extractSpotifyId(playlistId as string);
        if (playlistIdExtracted) {
          const tracksResponse = await spotifyApi.getPlaylistTracks(playlistIdExtracted, { limit: 5 });
          const trackIds = tracksResponse.body.items
            .map((item: any) => item.track?.id)
            .filter((id: any): id is string => typeof id === 'string');
          if (trackIds.length > 0) {
            recommendationParams.seed_tracks = trackIds.slice(0, 5);
            // Note: Duration filtering would need post-processing of results
            // Spotify API doesn't support duration constraints in recommendations
          }
        }
      } else {
        recommendationParams.seed_genres = ['pop', 'indie', 'acoustic'];
      }
    }
    
    // Strategy 6: Energy Adjustment - Gradual energy shift (±0.3)
    else if (strategyType === 'energy_adjust') {
      if (playlistId) {
        const playlistIdExtracted = extractSpotifyId(playlistId as string);
        if (playlistIdExtracted) {
          const tracksResponse = await spotifyApi.getPlaylistTracks(playlistIdExtracted, { limit: 10 });
          const trackIds = tracksResponse.body.items
            .map((item: any) => item.track?.id)
            .filter((id: any): id is string => typeof id === 'string');
          
          if (trackIds.length > 0) {
            const featuresResponse = await spotifyApi.getAudioFeaturesForTracks(trackIds.slice(0, 10));
            const features = featuresResponse.body.audio_features.filter((f: any) => f !== null);
            
            if (features.length > 0) {
              const avgEnergy = features.reduce((sum: number, f: any) => sum + (f.energy || 0), 0) / features.length;
              // Adjust energy up by 0.3 (or down if already high)
              const targetEnergy = avgEnergy >= 0.7 ? Math.max(0, avgEnergy - 0.3) : Math.min(1, avgEnergy + 0.3);
              
              recommendationParams.seed_tracks = trackIds.slice(0, 5);
              recommendationParams.target_energy = targetEnergy;
              recommendationParams.min_energy = Math.max(0, targetEnergy - 0.1);
              recommendationParams.max_energy = Math.min(1, targetEnergy + 0.1);
            }
          }
        }
      } else {
        return res.status(400).json({ error: 'Playlist ID required for energy_adjust strategy' });
      }
    }
    
    // Strategy 7: Professional Discovery - Multi-source analysis
    else if (strategyType === 'professional_discovery') {
      // Use top tracks, saved tracks, and recently played for comprehensive recommendations
      const [topTracks, savedTracks, recentlyPlayed] = await Promise.all([
        spotifyApi.getMyTopTracks({ time_range: 'medium_term', limit: 10 }).catch(() => ({ body: { items: [] } })),
        spotifyApi.getMySavedTracks({ limit: 10 }).catch(() => ({ body: { items: [] } })),
        spotifyApi.getMyRecentlyPlayedTracks({ limit: 5 }).catch(() => ({ body: { items: [] } })),
      ]);

      const allSeedTracks: string[] = [];
      
      // Add top tracks
      (topTracks.body.items || []).forEach((track: any) => {
        if (track.id) allSeedTracks.push(track.id);
      });
      
      // Add saved tracks
      (savedTracks.body.items || []).forEach((item: any) => {
        if (item.track?.id) allSeedTracks.push(item.track.id);
      });
      
      // Add recently played
      (recentlyPlayed.body.items || []).forEach((item: any) => {
        if (item.track?.id) allSeedTracks.push(item.track.id);
      });

      // Remove duplicates and take first 5
      recommendationParams.seed_tracks = Array.from(new Set(allSeedTracks)).slice(0, 5);
      
      if (recommendationParams.seed_tracks.length === 0) {
        return res.status(400).json({ error: 'Insufficient listening data for professional discovery' });
      }
    }
    
    // Strategy 8: Taste Expansion - Bridge to new genres
    else if (strategyType === 'taste_expansion') {
      // Get top artists and find related genres
      const topArtists = await spotifyApi.getMyTopArtists({ time_range: 'medium_term', limit: 20 })
        .catch(() => ({ body: { items: [] } }));
      
      const allGenres = new Set<string>();
      (topArtists.body.items || []).forEach((artist: any) => {
        if (artist.genres) {
          artist.genres.forEach((genre: string) => allGenres.add(genre));
        }
      });
      
      // Use top tracks as seeds but target slightly different genres
      const topTracks = await spotifyApi.getMyTopTracks({ time_range: 'medium_term', limit: 5 })
        .catch(() => ({ body: { items: [] } }));
      
      const seedTracks = (topTracks.body.items || [])
        .map((track: any) => track.id)
        .filter((id: any): id is string => typeof id === 'string')
        .slice(0, 5);
      
      if (seedTracks.length > 0) {
        recommendationParams.seed_tracks = seedTracks;
        // Add some related but not identical genres
        const genreArray = Array.from(allGenres);
        if (genreArray.length > 0) {
          recommendationParams.seed_genres = genreArray.slice(0, 2);
        }
      } else {
        return res.status(400).json({ error: 'Insufficient data for taste expansion' });
      }
    }
    
    // Strategy 9: Deep Cuts - Hidden gems from favorite artists
    else if (strategyType === 'deep_cuts') {
      const topArtists = await spotifyApi.getMyTopArtists({ time_range: 'long_term', limit: 5 })
        .catch(() => ({ body: { items: [] } }));
      
      const artistIds = (topArtists.body.items || [])
        .map((artist: any) => artist.id)
        .filter((id: any): id is string => typeof id === 'string')
        .slice(0, 5);
      
      if (artistIds.length > 0) {
        recommendationParams.seed_artists = artistIds;
        // Target lower popularity for deep cuts
        recommendationParams.target_popularity = 30;
      } else {
        return res.status(400).json({ error: 'Insufficient artist data for deep cuts' });
      }
    }
    
    // Strategy 10: Continue Your Session - Based on recently played
    else if (strategyType === 'continue_session') {
      const recentlyPlayed = await spotifyApi.getMyRecentlyPlayedTracks({ limit: 10 })
        .catch(() => ({ body: { items: [] } }));
      
      const seedTracks = (recentlyPlayed.body.items || [])
        .map((item: any) => item.track?.id)
        .filter((id: any): id is string => typeof id === 'string')
        .slice(0, 5);
      
      if (seedTracks.length > 0) {
        recommendationParams.seed_tracks = seedTracks;
      } else {
        return res.status(400).json({ error: 'No recently played tracks found' });
      }
    }
    
    // Strategy 11: From Your Library - Deep cuts from saved tracks
    else if (strategyType === 'from_library') {
      const savedTracks = await spotifyApi.getMySavedTracks({ limit: 20 })
        .catch(() => ({ body: { items: [] } }));
      
      const seedTracks = (savedTracks.body.items || [])
        .map((item: any) => item.track?.id)
        .filter((id: any): id is string => typeof id === 'string')
        .slice(0, 5);
      
      if (seedTracks.length > 0) {
        recommendationParams.seed_tracks = seedTracks;
        // Target lower popularity for hidden gems
        recommendationParams.target_popularity = 40;
      } else {
        return res.status(400).json({ error: 'No saved tracks found' });
      }
    }
    
    // Fallback: Use provided seeds or default
    else {
      if (seed_tracks && typeof seed_tracks === 'string') {
        recommendationParams.seed_tracks = seed_tracks.split(',').slice(0, 5);
      }
      if (seed_genres && typeof seed_genres === 'string') {
        recommendationParams.seed_genres = seed_genres.split(',').slice(0, 5);
      }
      if (seed_artists && typeof seed_artists === 'string') {
        recommendationParams.seed_artists = seed_artists.split(',').slice(0, 5);
      }
      
      // Default fallback
      if (!recommendationParams.seed_tracks?.length && 
          !recommendationParams.seed_genres?.length && 
          !recommendationParams.seed_artists?.length) {
        recommendationParams.seed_genres = ['pop', 'indie', 'rock'];
      }
    }
    
    // Ensure at least one seed is provided
    if (!recommendationParams.seed_tracks?.length && 
        !recommendationParams.seed_genres?.length && 
        !recommendationParams.seed_artists?.length) {
      return res.status(400).json({ 
        error: 'At least one seed (tracks, genres, or artists) is required' 
      });
    }
    
    // Get recommendations
    const recommendations = await spotifyApi.getRecommendations(recommendationParams);
    
    // Post-process results for strategies that need filtering
    let tracks = recommendations.body.tracks;
    
    if (strategyType === 'rare_match') {
      // Filter for low popularity tracks (post-processing)
      tracks = tracks.filter((track: any) => (track.popularity || 100) < 30);
    } else if (strategyType === 'short_session') {
      // Filter for tracks 5-10 minutes (300000-600000 ms)
      tracks = tracks.filter((track: any) => {
        const duration = track.duration_ms || 0;
        return duration >= 300000 && duration <= 600000;
      });
    } else if (strategyType === 'deep_cuts' || strategyType === 'from_library') {
      // Filter for lower popularity (hidden gems)
      tracks = tracks.filter((track: any) => (track.popularity || 100) < 50);
    }
    
    res.json(tracks);
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * GET /api/playlists
 * Get user's saved playlists
 */
app.get('/api/playlists', extractSupabaseToken, async (req: SupabaseRequest, res) => {
  try {
    const userId = req.userId;
    
    if (!userId) {
      return res.status(401).json({ 
        error: 'Authentication required',
        code: 'UNAUTHORIZED'
      });
    }

    if (!supabase) {
      return res.status(503).json({ 
        error: 'Database not configured',
        code: 'DB_NOT_CONFIGURED'
      });
    }

    // Query saved playlists (RLS will automatically filter by user_id)
    const { data: playlists, error: dbError } = await supabase
      .from('playlists')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (dbError) {
      console.error('Database error:', dbError);
      return res.status(500).json({ 
        error: 'Failed to fetch playlists',
        code: 'DB_ERROR'
      });
    }

    res.json(playlists || []);
  } catch (error: unknown) {
    const err = error as Error;
    console.error('Get playlists endpoint error:', err);
    res.status(500).json({ error: err.message || 'Internal server error' });
  }
});

/**
 * POST /api/playlists
 * Create a playlist
 */
app.post('/api/playlists', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const { name, description, tracks, coverUrl } = req.body as {
      name?: string;
      description?: string;
      tracks?: TrackInput[];
      coverUrl?: string;
    };
    const userToken = req.spotifyToken;
    
    if (!userToken) {
      return res.status(401).json({ 
        error: 'Spotify token required',
        code: 'TOKEN_REQUIRED'
      });
    }
    
    if (!name || !tracks || !Array.isArray(tracks)) {
      return res.status(400).json({ 
        error: 'Name and tracks (array) are required' 
      });
    }
    
    const spotifyApi = createSpotifyApi(userToken);
    
    // Create playlist (user context is from the access token)
    const playlistResponse = await spotifyApi.createPlaylist(name, {
      public: false,
      description: description,
    });
    const playlist = playlistResponse.body;
    
    // Add tracks - extract URIs or IDs
    const trackUris = tracks
      .map((track: TrackInput) => track.uri || track.id)
      .filter((uri): uri is string => typeof uri === 'string' && uri.length > 0);
    
    if (trackUris.length > 0) {
      await spotifyApi.addTracksToPlaylist(playlist.id, trackUris);
    }
    
    res.json({
      id: playlist.id,
      name: playlist.name,
      url: playlist.external_urls.spotify,
      trackCount: tracks.length,
    });
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * POST /api/playlists/save
 * Save a playlist to user's collection
 */
app.post('/api/playlists/save', extractSupabaseToken, extractSpotifyToken, async (req: SupabaseRequest & SpotifyRequest, res) => {
  try {
    const { url, name, description, coverUrl } = req.body as {
      url?: string;
      name?: string;
      description?: string;
      coverUrl?: string;
    };
    const userId = req.userId;
    const userToken = req.spotifyToken;
    
    if (!userId) {
      return res.status(401).json({ 
        error: 'Authentication required',
        code: 'UNAUTHORIZED'
      });
    }
    
    if (!url) {
      return res.status(400).json({ 
        error: 'Playlist URL is required' 
      });
    }
    
    // Extract playlist ID and fetch details if needed
    const playlistId = extractSpotifyId(url);
    if (!playlistId) {
      return res.status(400).json({ 
        error: 'Invalid playlist URL' 
      });
    }
    
    let playlistName = name;
    let playlistOwner = 'Unknown';
    let playlistCoverUrl = coverUrl || null;
    let trackCount = 0;
    
    // Fetch playlist details from Spotify if token available
    if (userToken) {
      try {
        const spotifyApi = createSpotifyApi(userToken);
        const playlist = await spotifyApi.getPlaylist(playlistId);
        playlistName = playlistName || playlist.body.name;
        playlistOwner = playlist.body.owner?.display_name || 'Unknown';
        playlistCoverUrl = playlistCoverUrl || playlist.body.images?.[0]?.url || null;
        trackCount = playlist.body.tracks?.total || 0;
      } catch (spotifyError) {
        // If Spotify fetch fails, use provided data or defaults
        console.warn('Failed to fetch playlist from Spotify, using provided data');
      }
    }
    
    if (!playlistName) {
      return res.status(400).json({ 
        error: 'Playlist name is required' 
      });
    }
    
    // Ensure user profile exists
    await ensureUserProfile(userId);
    
    // Save playlist to database
    const dbPlaylistId = await savePlaylistToDatabase(
      userId,
      playlistId,
      url,
      playlistName,
      playlistOwner,
      playlistCoverUrl,
      trackCount
    );
    
    if (!dbPlaylistId) {
      return res.status(500).json({ 
        error: 'Failed to save playlist',
        code: 'SAVE_ERROR'
      });
    }
    
    res.json({
      id: dbPlaylistId,
      message: 'Playlist saved successfully',
    });
  } catch (error: unknown) {
    const err = error as Error;
    console.error('Save playlist endpoint error:', err);
    res.status(500).json({ error: err.message || 'Internal server error' });
  }
});

/**
 * DELETE /api/playlists/:id
 * Delete a playlist (if user owns it)
 */
app.delete('/api/playlists/:id', extractSupabaseToken, async (req: SupabaseRequest, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;
    
    if (!userId) {
      return res.status(401).json({ 
        error: 'Authentication required',
        code: 'UNAUTHORIZED'
      });
    }
    
    // Delete from database (RLS will ensure user can only delete their own playlists)
    if (!supabase) {
      return res.status(503).json({ 
        error: 'Database not configured',
        code: 'DB_NOT_CONFIGURED'
      });
    }
    
    const { error } = await supabase
      .from('playlists')
      .delete()
      .eq('id', id)
      .eq('user_id', userId);
    
    if (error) {
      return res.status(500).json({ 
        error: 'Failed to delete playlist',
        code: 'DELETE_ERROR'
      });
    }
    
    res.json({ success: true, message: 'Playlist deleted successfully' });
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * GET /api/history
 * Get user's analysis and battle history
 */
app.get('/api/history', extractSupabaseToken, async (req: SupabaseRequest, res) => {
  try {
    const userId = req.userId;
    
    if (!userId) {
      return res.status(401).json({ 
        error: 'Authentication required',
        code: 'UNAUTHORIZED'
      });
    }

    if (!supabase) {
      return res.status(503).json({ 
        error: 'Database not configured',
        code: 'DB_NOT_CONFIGURED'
      });
    }

    // Query history view (RLS will automatically filter by user_id)
    const { data: history, error: dbError } = await supabase
      .from('history')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(50);

    if (dbError) {
      console.error('Database error:', dbError);
      return res.status(500).json({ 
        error: 'Failed to fetch history',
        code: 'DB_ERROR'
      });
    }

    res.json(history || []);
  } catch (error: unknown) {
    const err = error as Error;
    console.error('History endpoint error:', err);
    res.status(500).json({ error: err.message || 'Internal server error' });
  }
});

/**
 * GET /api/user/top-tracks
 * Get user's top tracks (short-term, medium-term, or long-term)
 */
app.get('/api/user/top-tracks', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const userToken = req.spotifyToken;
    const timeRange = (req.query.time_range as string) || 'medium_term'; // short_term, medium_term, long_term
    
    if (!userToken) {
      return res.status(401).json({
        error: 'Spotify token required',
        code: 'TOKEN_REQUIRED'
      });
    }

    const spotifyApi = createSpotifyApi(userToken);
    
    // Validate time_range
    if (!['short_term', 'medium_term', 'long_term'].includes(timeRange)) {
      return res.status(400).json({
        error: 'Invalid time_range. Must be short_term, medium_term, or long_term',
        code: 'INVALID_TIME_RANGE'
      });
    }

    const response = await spotifyApi.getMyTopTracks({
      time_range: timeRange as 'short_term' | 'medium_term' | 'long_term',
      limit: 50
    });

    const tracks = (response.body.items || []).map((track: any) => ({
      id: track.id,
      name: track.name,
      artists: track.artists.map((a: any) => ({ id: a.id, name: a.name })),
      album: {
        id: track.album.id,
        name: track.album.name,
        images: track.album.images,
      },
      duration_ms: track.duration_ms,
      popularity: track.popularity,
      preview_url: track.preview_url,
      external_urls: track.external_urls,
    }));

    res.json({
      time_range: timeRange,
      tracks,
      total: response.body.total || tracks.length,
    });
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * GET /api/user/top-artists
 * Get user's top artists (short-term, medium-term, or long-term)
 */
app.get('/api/user/top-artists', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const userToken = req.spotifyToken;
    const timeRange = (req.query.time_range as string) || 'medium_term';
    
    if (!userToken) {
      return res.status(401).json({
        error: 'Spotify token required',
        code: 'TOKEN_REQUIRED'
      });
    }

    const spotifyApi = createSpotifyApi(userToken);
    
    if (!['short_term', 'medium_term', 'long_term'].includes(timeRange)) {
      return res.status(400).json({
        error: 'Invalid time_range. Must be short_term, medium_term, or long_term',
        code: 'INVALID_TIME_RANGE'
      });
    }

    const response = await spotifyApi.getMyTopArtists({
      time_range: timeRange as 'short_term' | 'medium_term' | 'long_term',
      limit: 50
    });

    const artists = (response.body.items || []).map((artist: any) => ({
      id: artist.id,
      name: artist.name,
      genres: artist.genres || [],
      images: artist.images || [],
      popularity: artist.popularity,
      external_urls: artist.external_urls,
    }));

    res.json({
      time_range: timeRange,
      artists,
      total: response.body.total || artists.length,
    });
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * GET /api/user/recently-played
 * Get user's recently played tracks
 */
app.get('/api/user/recently-played', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const userToken = req.spotifyToken;
    const limit = parseInt(req.query.limit as string) || 50;
    
    if (!userToken) {
      return res.status(401).json({
        error: 'Spotify token required',
        code: 'TOKEN_REQUIRED'
      });
    }

    const spotifyApi = createSpotifyApi(userToken);
    
    const response = await spotifyApi.getMyRecentlyPlayedTracks({
      limit: Math.min(limit, 50) // Spotify API max is 50
    });

    const tracks = (response.body.items || [])
      .filter((item: any) => item.track && item.track.id)
      .map((item: any) => ({
        track: {
          id: item.track.id,
          name: item.track.name || 'Unknown',
          artists: (item.track.artists || []).map((a: any) => ({ id: a.id || '', name: a.name || 'Unknown' })),
          album: {
            id: item.track.album?.id || '',
            name: item.track.album?.name || 'Unknown',
            images: item.track.album?.images || [],
          },
          duration_ms: item.track.duration_ms || 0,
          popularity: item.track.popularity || 0,
          preview_url: item.track.preview_url || null,
          external_urls: item.track.external_urls || {},
        },
        played_at: item.played_at || null,
      }));

    res.json({
      tracks,
      total: tracks.length,
    });
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * GET /api/user/saved-tracks
 * Get user's saved/liked tracks
 */
app.get('/api/user/saved-tracks', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const userToken = req.spotifyToken;
    const limit = parseInt(req.query.limit as string) || 50;
    const offset = parseInt(req.query.offset as string) || 0;
    
    if (!userToken) {
      return res.status(401).json({
        error: 'Spotify token required',
        code: 'TOKEN_REQUIRED'
      });
    }

    const spotifyApi = createSpotifyApi(userToken);
    
    // Fetch all saved tracks (handle pagination)
    const allTracks: any[] = [];
    let currentOffset = offset;
    const pageLimit = Math.min(limit, 50); // Spotify API max is 50 per request
    
    while (allTracks.length < limit) {
      const response = await spotifyApi.getMySavedTracks({
        limit: pageLimit,
        offset: currentOffset
      });
      
      const items = response.body.items || [];
      if (items.length === 0) break;
      
      allTracks.push(...items);
      currentOffset += items.length;
      
      if (items.length < pageLimit) break;
    }

    const tracks = allTracks.slice(0, limit).map((item: any) => ({
      added_at: item.added_at,
      track: {
        id: item.track.id,
        name: item.track.name,
        artists: item.track.artists.map((a: any) => ({ id: a.id, name: a.name })),
        album: {
          id: item.track.album.id,
          name: item.track.album.name,
          images: item.track.album.images,
        },
        duration_ms: item.track.duration_ms,
        popularity: item.track.popularity,
        preview_url: item.track.preview_url,
        external_urls: item.track.external_urls,
      },
    }));

    res.json({
      tracks,
      total: tracks.length,
      offset,
      limit,
    });
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * GET /api/user/saved-albums
 * Get user's saved albums
 */
app.get('/api/user/saved-albums', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const userToken = req.spotifyToken;
    const limit = parseInt(req.query.limit as string) || 50;
    const offset = parseInt(req.query.offset as string) || 0;
    
    if (!userToken) {
      return res.status(401).json({
        error: 'Spotify token required',
        code: 'TOKEN_REQUIRED'
      });
    }

    const spotifyApi = createSpotifyApi(userToken);
    
    // Fetch all saved albums (handle pagination)
    const allAlbums: any[] = [];
    let currentOffset = offset;
    const pageLimit = Math.min(limit, 50);
    
    while (allAlbums.length < limit) {
      const response = await spotifyApi.getMySavedAlbums({
        limit: pageLimit,
        offset: currentOffset
      });
      
      const items = response.body.items || [];
      if (items.length === 0) break;
      
      allAlbums.push(...items);
      currentOffset += items.length;
      
      if (items.length < pageLimit) break;
    }

    const albums = allAlbums.slice(0, limit).map((item: any) => ({
      added_at: item.added_at,
      album: {
        id: item.album.id,
        name: item.album.name,
        artists: item.album.artists.map((a: any) => ({ id: a.id, name: a.name })),
        images: item.album.images || [],
        release_date: item.album.release_date,
        total_tracks: item.album.total_tracks,
        external_urls: item.album.external_urls,
      },
    }));

    res.json({
      albums,
      total: albums.length,
      offset,
      limit,
    });
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * GET /api/profile/taste
 * Get enhanced taste profile aggregating playlists, top tracks, top artists, and saved tracks
 */
app.get('/api/profile/taste', extractSpotifyToken, extractSupabaseToken, async (req: SpotifyRequest & SupabaseRequest, res) => {
  try {
    const userToken = req.spotifyToken;
    const userId = req.userId;
    
    if (!userToken) {
      return res.status(401).json({
        error: 'Spotify token required',
        code: 'TOKEN_REQUIRED'
      });
    }

    if (!userId || !supabase) {
      return res.status(401).json({
        error: 'Authentication required',
        code: 'UNAUTHORIZED'
      });
    }

    const spotifyApi = createSpotifyApi(userToken);

    // Fetch data from multiple sources in parallel
    const [topTracksShort, topTracksMedium, topTracksLong, 
           topArtistsShort, topArtistsMedium, topArtistsLong,
           recentlyPlayed, savedTracksResponse] = await Promise.all([
      spotifyApi.getMyTopTracks({ time_range: 'short_term', limit: 50 }).catch(() => ({ body: { items: [] } })),
      spotifyApi.getMyTopTracks({ time_range: 'medium_term', limit: 50 }).catch(() => ({ body: { items: [] } })),
      spotifyApi.getMyTopTracks({ time_range: 'long_term', limit: 50 }).catch(() => ({ body: { items: [] } })),
      spotifyApi.getMyTopArtists({ time_range: 'short_term', limit: 50 }).catch(() => ({ body: { items: [] } })),
      spotifyApi.getMyTopArtists({ time_range: 'medium_term', limit: 50 }).catch(() => ({ body: { items: [] } })),
      spotifyApi.getMyTopArtists({ time_range: 'long_term', limit: 50 }).catch(() => ({ body: { items: [] } })),
      spotifyApi.getMyRecentlyPlayedTracks({ limit: 50 }).catch(() => ({ body: { items: [] } })),
      spotifyApi.getMySavedTracks({ limit: 50 }).catch(() => ({ body: { items: [] } })),
    ]);

    // Get analyzed playlists from database
    const { data: analyses } = await supabase
      .from('analyses')
      .select('audio_dna, genre_distribution, top_tracks, personality_type')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(50);

    // Aggregate genres from all sources
    const genreMap: { [key: string]: number } = {};
    const artistMap: { [key: string]: number } = {};
    const audioFeaturesList: any[] = [];

    // Process top tracks
    const processTracks = (tracks: any[], weight: number) => {
      tracks.forEach((item: any) => {
        const track = item.track || item;
        if (track.artists) {
          track.artists.forEach((artist: any) => {
            const artistName = artist.name || artist;
            artistMap[artistName] = (artistMap[artistName] || 0) + weight;
          });
        }
      });
    };

    processTracks(topTracksShort.body.items || [], 3); // Short-term weighted higher
    processTracks(topTracksMedium.body.items || [], 2);
    processTracks(topTracksLong.body.items || [], 1);
    processTracks((recentlyPlayed.body.items || []).map((i: any) => i.track), 2);
    processTracks((savedTracksResponse.body.items || []).map((i: any) => i.track), 1.5);

    // Process top artists
    const processArtists = (artists: any[], weight: number) => {
      artists.forEach((artist: any) => {
        const artistName = artist.name;
        artistMap[artistName] = (artistMap[artistName] || 0) + weight;
        if (artist.genres) {
          artist.genres.forEach((genre: string) => {
            genreMap[genre] = (genreMap[genre] || 0) + weight;
          });
        }
      });
    };

    processArtists(topArtistsShort.body.items || [], 3);
    processArtists(topArtistsMedium.body.items || [], 2);
    processArtists(topArtistsLong.body.items || [], 1);

    // Process analyses from database
    if (analyses) {
      analyses.forEach((analysis: any) => {
        if (analysis.genre_distribution) {
          analysis.genre_distribution.forEach((genre: any) => {
            genreMap[genre.name || genre] = (genreMap[genre.name || genre] || 0) + (genre.value || 1);
          });
        }
        if (analysis.audio_dna) {
          audioFeaturesList.push(analysis.audio_dna);
        }
      });
    }

    // Calculate average audio features
    const avgAudioFeatures = audioFeaturesList.length > 0
      ? {
          energy: audioFeaturesList.reduce((sum, f) => sum + (f.energy || 0), 0) / audioFeaturesList.length,
          danceability: audioFeaturesList.reduce((sum, f) => sum + (f.danceability || 0), 0) / audioFeaturesList.length,
          valence: audioFeaturesList.reduce((sum, f) => sum + (f.valence || 0), 0) / audioFeaturesList.length,
          acousticness: audioFeaturesList.reduce((sum, f) => sum + (f.acousticness || 0), 0) / audioFeaturesList.length,
          instrumentalness: audioFeaturesList.reduce((sum, f) => sum + (f.instrumentalness || 0), 0) / audioFeaturesList.length,
          tempo: audioFeaturesList.reduce((sum, f) => sum + (f.tempo || 0), 0) / audioFeaturesList.length,
        }
      : null;

    // Get top genres and artists
    const topGenres = Object.entries(genreMap)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 10)
      .map(([name, value]) => ({ name, value }));

    const topArtists = Object.entries(artistMap)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 20)
      .map(([name, value]) => ({ name, value }));

    // Analyze listening evolution
    const shortTermGenres = new Set(
      (topArtistsShort.body.items || []).flatMap((a: any) => a.genres || [])
    );
    const longTermGenres = new Set(
      (topArtistsLong.body.items || []).flatMap((a: any) => a.genres || [])
    );
    const newGenres = Array.from(shortTermGenres).filter(g => !longTermGenres.has(g));
    const evolvingGenres = Array.from(shortTermGenres).filter(g => longTermGenres.has(g));

    res.json({
      topGenres,
      topArtists,
      audioFeatures: avgAudioFeatures,
      listeningEvolution: {
        newGenres,
        evolvingGenres,
        shortTermCount: topTracksShort.body.items?.length || 0,
        mediumTermCount: topTracksMedium.body.items?.length || 0,
        longTermCount: topTracksLong.body.items?.length || 0,
      },
      sources: {
        topTracks: {
          short: topTracksShort.body.items?.length || 0,
          medium: topTracksMedium.body.items?.length || 0,
          long: topTracksLong.body.items?.length || 0,
        },
        topArtists: {
          short: topArtistsShort.body.items?.length || 0,
          medium: topArtistsMedium.body.items?.length || 0,
          long: topArtistsLong.body.items?.length || 0,
        },
        recentlyPlayed: recentlyPlayed.body.items?.length || 0,
        savedTracks: savedTracksResponse.body.items?.length || 0,
        analyzedPlaylists: analyses?.length || 0,
      },
    });
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * POST /api/mood/analyze
 * Analyze mood from recently played tracks
 */
app.post('/api/mood/analyze', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const userToken = req.spotifyToken;
    const { limit = 20 } = req.body as { limit?: number };
    
    if (!userToken) {
      return res.status(401).json({
        error: 'Spotify token required',
        code: 'TOKEN_REQUIRED'
      });
    }

    const spotifyApi = createSpotifyApi(userToken);
    
    // Get recently played tracks
    const recentlyPlayed = await spotifyApi.getMyRecentlyPlayedTracks({
      limit: Math.min(limit, 50)
    });

    const tracks = (recentlyPlayed.body.items || [])
      .map((item: any) => item.track)
      .filter((t: any) => t && t.id);
    const trackIds = tracks
      .map((t: any) => t?.id)
      .filter((id: any): id is string => typeof id === 'string' && id.length > 0);

    if (trackIds.length === 0) {
      return res.status(400).json({
        error: 'No recently played tracks found',
        code: 'NO_TRACKS'
      });
    }

    // Get audio features for recently played tracks
    const audioFeaturesList: any[] = [];
    for (let i = 0; i < trackIds.length; i += 100) {
      const batch = trackIds.slice(i, i + 100);
      const featuresResponse = await spotifyApi.getAudioFeaturesForTracks(batch);
      if (featuresResponse.body.audio_features) {
        audioFeaturesList.push(...featuresResponse.body.audio_features.filter((f: any) => f !== null));
      }
    }

    if (audioFeaturesList.length === 0) {
      return res.status(400).json({
        error: 'Could not fetch audio features',
        code: 'NO_FEATURES'
      });
    }

    // Calculate mood indicators
    const avgEnergy = audioFeaturesList.reduce((sum, f) => sum + (f.energy || 0), 0) / audioFeaturesList.length;
    const avgValence = audioFeaturesList.reduce((sum, f) => sum + (f.valence || 0), 0) / audioFeaturesList.length;
    const avgDanceability = audioFeaturesList.reduce((sum, f) => sum + (f.danceability || 0), 0) / audioFeaturesList.length;
    const avgTempo = audioFeaturesList.reduce((sum, f) => sum + (f.tempo || 0), 0) / audioFeaturesList.length;

    // Determine mood category
    let moodCategory = 'neutral';
    let moodDescription = 'Balanced listening mood';
    
    if (avgValence > 0.7 && avgEnergy > 0.6) {
      moodCategory = 'happy_energetic';
      moodDescription = 'Upbeat and energetic vibes';
    } else if (avgValence > 0.7 && avgEnergy <= 0.6) {
      moodCategory = 'happy_calm';
      moodDescription = 'Positive and relaxed';
    } else if (avgValence <= 0.4 && avgEnergy > 0.6) {
      moodCategory = 'intense';
      moodDescription = 'Intense and powerful';
    } else if (avgValence <= 0.4 && avgEnergy <= 0.4) {
      moodCategory = 'melancholic';
      moodDescription = 'Reflective and somber';
    } else if (avgDanceability > 0.7) {
      moodCategory = 'dance';
      moodDescription = 'Ready to move';
    } else if (avgTempo < 80) {
      moodCategory = 'chill';
      moodDescription = 'Chill and laid-back';
    }

    res.json({
      mood: {
        category: moodCategory,
        description: moodDescription,
        confidence: Math.min(100, Math.round((1 - Math.abs(avgValence - 0.5) - Math.abs(avgEnergy - 0.5)) * 100)),
      },
      audioFeatures: {
        energy: Math.round(avgEnergy * 100),
        valence: Math.round(avgValence * 100),
        danceability: Math.round(avgDanceability * 100),
        // Normalize tempo to 0-100 scale for consistency
        tempo: Math.min(100, Math.max(0, Math.round(((avgTempo - 60) / 140) * 100))),
      },
      tracksAnalyzed: audioFeaturesList.length,
      timestamp: new Date().toISOString(),
    });
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * POST /api/mood/playlist
 * Generate mood-based playlist
 */
app.post('/api/mood/playlist', extractSpotifyToken, async (req: SpotifyRequest, res) => {
  try {
    const userToken = req.spotifyToken;
    const { mood, limit = 20 } = req.body as { mood?: string; limit?: number };
    
    if (!userToken) {
      return res.status(401).json({
        error: 'Spotify token required',
        code: 'TOKEN_REQUIRED'
      });
    }

    const spotifyApi = createSpotifyApi(userToken);
    
    // Get recently played for seed tracks
    const recentlyPlayed = await spotifyApi.getMyRecentlyPlayedTracks({ limit: 5 });
    const seedTracks = (recentlyPlayed.body.items || [])
      .map((item: any) => item.track?.id)
      .filter((id: any): id is string => typeof id === 'string')
      .slice(0, 5);

    // Mood-based recommendation parameters
    const recommendationParams: any = {
      limit: Math.min(limit, 50),
      seed_tracks: seedTracks.length > 0 ? seedTracks : undefined,
    };

    // Adjust parameters based on mood
    if (mood === 'happy_energetic') {
      recommendationParams.target_energy = 0.8;
      recommendationParams.target_valence = 0.8;
      recommendationParams.min_energy = 0.6;
      recommendationParams.min_valence = 0.6;
    } else if (mood === 'happy_calm') {
      recommendationParams.target_energy = 0.4;
      recommendationParams.target_valence = 0.7;
      recommendationParams.max_energy = 0.6;
      recommendationParams.min_valence = 0.5;
    } else if (mood === 'intense') {
      recommendationParams.target_energy = 0.8;
      recommendationParams.target_valence = 0.3;
      recommendationParams.min_energy = 0.6;
      recommendationParams.max_valence = 0.5;
    } else if (mood === 'melancholic') {
      recommendationParams.target_energy = 0.3;
      recommendationParams.target_valence = 0.3;
      recommendationParams.max_energy = 0.5;
      recommendationParams.max_valence = 0.5;
    } else if (mood === 'dance') {
      recommendationParams.target_danceability = 0.8;
      recommendationParams.target_energy = 0.7;
      recommendationParams.min_danceability = 0.6;
    } else if (mood === 'chill') {
      recommendationParams.target_energy = 0.3;
      recommendationParams.target_tempo = 70;
      recommendationParams.max_energy = 0.5;
    }

    // Fallback to default genres if no seed tracks
    if (!recommendationParams.seed_tracks || recommendationParams.seed_tracks.length === 0) {
      recommendationParams.seed_genres = ['pop', 'indie', 'alternative'];
    }

    const recommendations = await spotifyApi.getRecommendations(recommendationParams);
    
    res.json({
      mood,
      tracks: recommendations.body.tracks,
      total: recommendations.body.tracks.length,
    });
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * GET /api/personality/listening
 * Analyze listening personality comparing playlist curation vs actual listening
 */
app.get('/api/personality/listening', extractSpotifyToken, extractSupabaseToken, async (req: SpotifyRequest & SupabaseRequest, res) => {
  try {
    const userToken = req.spotifyToken;
    const userId = req.userId;
    
    if (!userToken || !userId || !supabase) {
      return res.status(401).json({
        error: 'Authentication required',
        code: 'UNAUTHORIZED'
      });
    }

    const spotifyApi = createSpotifyApi(userToken);

    // Get top tracks (actual listening)
    const [topTracks, topArtists] = await Promise.all([
      spotifyApi.getMyTopTracks({ time_range: 'medium_term', limit: 50 }).catch(() => ({ body: { items: [] } })),
      spotifyApi.getMyTopArtists({ time_range: 'medium_term', limit: 50 }).catch(() => ({ body: { items: [] } })),
    ]);

    // Get analyzed playlists (curation)
    const { data: analyses } = await supabase
      .from('analyses')
      .select('audio_dna, genre_distribution, personality_type')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .limit(20);

    // Analyze listening vs curation
    const listeningGenres = new Set(
      (topArtists.body.items || []).flatMap((a: any) => a.genres || [])
    );
    
    const curationGenres = new Set(
      (analyses || []).flatMap((a: any) => 
        (a.genre_distribution || []).map((g: any) => g.name || g)
      )
    );

    const overlapGenres = Array.from(listeningGenres).filter(g => curationGenres.has(g));
    const listeningOnlyGenres = Array.from(listeningGenres).filter(g => !curationGenres.has(g));
    const curationOnlyGenres = Array.from(curationGenres).filter(g => !listeningGenres.has(g));

    // Calculate personality traits
    const listeningPersonality = {
      explorer: listeningOnlyGenres.length > overlapGenres.length,
      loyalist: overlapGenres.length > listeningOnlyGenres.length,
      curator: curationOnlyGenres.length > 0,
      balanced: Math.abs(listeningOnlyGenres.length - curationOnlyGenres.length) <= 2,
    };

    // Determine primary personality
    let primaryPersonality = 'balanced';
    if (listeningPersonality.explorer) primaryPersonality = 'explorer';
    else if (listeningPersonality.loyalist) primaryPersonality = 'loyalist';
    else if (listeningPersonality.curator) primaryPersonality = 'curator';

    res.json({
      personality: {
        type: primaryPersonality,
        traits: listeningPersonality,
        description: getPersonalityDescription(primaryPersonality),
      },
      comparison: {
        listeningGenres: Array.from(listeningGenres),
        curationGenres: Array.from(curationGenres),
        overlap: overlapGenres,
        listeningOnly: listeningOnlyGenres,
        curationOnly: curationOnlyGenres,
      },
      stats: {
        topTracksCount: topTracks.body.items?.length || 0,
        topArtistsCount: topArtists.body.items?.length || 0,
        analyzedPlaylistsCount: analyses?.length || 0,
      },
    });
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

// Helper function for personality descriptions
function getPersonalityDescription(type: string): string {
  const descriptions: { [key: string]: string } = {
    explorer: 'You actively seek new music beyond your playlists. Your listening habits show you\'re always discovering new sounds and genres.',
    loyalist: 'You stick close to what you know. Your playlists and listening habits align closely, showing consistent taste preferences.',
    curator: 'You carefully craft playlists that may differ from your casual listening. You enjoy organizing music thoughtfully.',
    balanced: 'You strike a balance between exploration and curation. Your playlists and listening habits complement each other well.',
  };
  return descriptions[type] || descriptions.balanced;
}

/**
 * POST /api/playlists/optimize
 * Suggest playlist optimizations based on taste profile and listening data
 */
app.post('/api/playlists/optimize', extractSpotifyToken, extractSupabaseToken, async (req: SpotifyRequest & SupabaseRequest, res) => {
  try {
    const userToken = req.spotifyToken;
    const userId = req.userId;
    const { playlistId, url } = req.body as { playlistId?: string; url?: string };
    
    if (!userToken || !userId || !supabase) {
      return res.status(401).json({
        error: 'Authentication required',
        code: 'UNAUTHORIZED'
      });
    }

    if (!playlistId && !url) {
      return res.status(400).json({
        error: 'Playlist ID or URL is required',
        code: 'PLAYLIST_REQUIRED'
      });
    }

    const spotifyApi = createSpotifyApi(userToken);
    const extractedPlaylistId = playlistId || extractSpotifyId(url || '');
    
    if (!extractedPlaylistId) {
      return res.status(400).json({
        error: 'Invalid playlist ID or URL',
        code: 'INVALID_PLAYLIST'
      });
    }

    // Get playlist tracks
    const playlist = await spotifyApi.getPlaylist(extractedPlaylistId);
    const tracksResponse = await spotifyApi.getPlaylistTracks(extractedPlaylistId, { limit: 100 });
    const playlistTracks = (tracksResponse.body.items || [])
      .map((item: any) => item.track)
      .filter((t: any) => t && t.id);
    
    if (playlistTracks.length === 0) {
      return res.status(400).json({
        error: 'Playlist has no tracks',
        code: 'EMPTY_PLAYLIST'
      });
    }
    
    const playlistTrackIds = playlistTracks.map((t: any) => t.id);

    // Get user's taste profile
    const [topTracks, topArtists, savedTracks] = await Promise.all([
      spotifyApi.getMyTopTracks({ time_range: 'medium_term', limit: 50 }).catch(() => ({ body: { items: [] } })),
      spotifyApi.getMyTopArtists({ time_range: 'medium_term', limit: 50 }).catch(() => ({ body: { items: [] } })),
      spotifyApi.getMySavedTracks({ limit: 50 }).catch(() => ({ body: { items: [] } })),
    ]);

    // Get audio features for playlist tracks
    const audioFeaturesList: any[] = [];
    for (let i = 0; i < playlistTrackIds.length; i += 100) {
      const batch = playlistTrackIds.slice(i, i + 100);
      const featuresResponse = await spotifyApi.getAudioFeaturesForTracks(batch);
      if (featuresResponse.body.audio_features) {
        audioFeaturesList.push(...featuresResponse.body.audio_features.filter((f: any) => f !== null));
      }
    }

    // Calculate playlist averages (with safety check)
    if (audioFeaturesList.length === 0) {
      return res.status(400).json({
        error: 'No audio features available for playlist',
        code: 'NO_FEATURES'
      });
    }
    
    const avgEnergy = audioFeaturesList.reduce((sum, f) => sum + (f.energy || 0), 0) / audioFeaturesList.length;
    const avgValence = audioFeaturesList.reduce((sum, f) => sum + (f.valence || 0), 0) / audioFeaturesList.length;
    const avgDanceability = audioFeaturesList.reduce((sum, f) => sum + (f.danceability || 0), 0) / audioFeaturesList.length;

    // Get user's preferred genres from top artists
    const userGenres = new Set<string>();
    (topArtists.body.items || []).forEach((artist: any) => {
      if (artist.genres) {
        artist.genres.forEach((g: string) => userGenres.add(g));
      }
    });

    // Get playlist genres
    const playlistArtistIds = new Set<string>();
    playlistTracks.forEach((track: any) => {
      if (track.artists) {
        track.artists.forEach((artist: any) => {
          if (artist.id) playlistArtistIds.add(artist.id);
        });
      }
    });

    const playlistArtists = await Promise.all(
      Array.from(playlistArtistIds).slice(0, 50).map(id => 
        spotifyApi.getArtist(id).catch(() => ({ body: { genres: [] } }))
      )
    );

    const playlistGenres = new Set<string>();
    playlistArtists.forEach((response: any) => {
      if (response.body.genres) {
        response.body.genres.forEach((g: string) => playlistGenres.add(g));
      }
    });

    // Find missing genres
    const missingGenres = Array.from(userGenres).filter(g => !playlistGenres.has(g));

    // Generate recommendations to fill gaps
    const topTrackIds = (topTracks.body.items || [])
      .map((track: any) => track.id)
      .filter((id: any): id is string => typeof id === 'string')
      .slice(0, 5);

    let suggestions: any[] = [];
    if (topTrackIds.length > 0) {
      const recommendations = await spotifyApi.getRecommendations({
        seed_tracks: topTrackIds,
        limit: 10,
        target_energy: avgEnergy,
        target_valence: avgValence,
        target_danceability: avgDanceability,
      });
      suggestions = recommendations.body.tracks.filter((track: any) => 
        !playlistTrackIds.includes(track.id)
      ).slice(0, 5);
    }

    res.json({
      playlist: {
        id: extractedPlaylistId,
        name: playlist.body.name,
        trackCount: playlistTracks.length,
      },
      analysis: {
        currentEnergy: Math.round(avgEnergy * 100),
        currentValence: Math.round(avgValence * 100),
        currentDanceability: Math.round(avgDanceability * 100),
        genres: Array.from(playlistGenres),
      },
      optimization: {
        missingGenres,
        suggestions: suggestions.map((track) => ({
          id: track.id,
          name: track.name,
          artists: track.artists.map((a: any) => a.name),
          album: track.album.name,
          albumArt: track.album.images?.[0]?.url,
          preview_url: track.preview_url,
        })),
        score: calculateOptimizationScore(playlistGenres, userGenres, audioFeaturesList.length),
      },
    });
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

// Helper function to calculate optimization score
function calculateOptimizationScore(playlistGenres: Set<string>, userGenres: Set<string>, trackCount: number): number {
  const overlap = Array.from(playlistGenres).filter(g => userGenres.has(g)).length;
  const totalUserGenres = userGenres.size;
  const genreMatch = totalUserGenres > 0 ? (overlap / totalUserGenres) * 100 : 0;
  const trackCountScore = Math.min(100, (trackCount / 50) * 100);
  return Math.round((genreMatch * 0.7) + (trackCountScore * 0.3));
}

/**
 * POST /api/playlists/generate
 * Generate smart playlists based on taste profile, mood, or activity
 */
app.post('/api/playlists/generate', extractSpotifyToken, extractSupabaseToken, async (req: SpotifyRequest & SupabaseRequest, res) => {
  try {
    const userToken = req.spotifyToken;
    const userId = req.userId;
    const { type, mood, activity, limit = 30 } = req.body as { 
      type?: string; 
      mood?: string; 
      activity?: string; 
      limit?: number;
    };
    
    if (!userToken || !userId) {
      return res.status(401).json({
        error: 'Authentication required',
        code: 'UNAUTHORIZED'
      });
    }

    const spotifyApi = createSpotifyApi(userToken);
    let recommendationParams: any = { limit: Math.min(limit, 50) };

    // Activity-based playlists
    if (activity === 'workout') {
      const topTracks = await spotifyApi.getMyTopTracks({ time_range: 'medium_term', limit: 5 })
        .catch(() => ({ body: { items: [] } }));
      recommendationParams.seed_tracks = (topTracks.body.items || [])
        .map((t: any) => t.id)
        .filter((id: any): id is string => typeof id === 'string')
        .slice(0, 5);
      recommendationParams.target_energy = 0.8;
      recommendationParams.min_energy = 0.7;
      recommendationParams.target_danceability = 0.8;
    } else if (activity === 'study') {
      const savedTracks = await spotifyApi.getMySavedTracks({ limit: 10 })
        .catch(() => ({ body: { items: [] } }));
      recommendationParams.seed_tracks = (savedTracks.body.items || [])
        .map((item: any) => item.track?.id)
        .filter((id: any): id is string => typeof id === 'string')
        .slice(0, 5);
      recommendationParams.target_energy = 0.3;
      recommendationParams.max_energy = 0.5;
      recommendationParams.target_instrumentalness = 0.5;
    } else if (activity === 'party') {
      const topTracks = await spotifyApi.getMyTopTracks({ time_range: 'short_term', limit: 5 })
        .catch(() => ({ body: { items: [] } }));
      recommendationParams.seed_tracks = (topTracks.body.items || [])
        .map((t: any) => t.id)
        .filter((id: any): id is string => typeof id === 'string')
        .slice(0, 5);
      recommendationParams.target_energy = 0.9;
      recommendationParams.target_danceability = 0.9;
      recommendationParams.target_valence = 0.8;
    } else if (mood) {
      // Mood-based (reuse mood playlist logic)
      const recentlyPlayed = await spotifyApi.getMyRecentlyPlayedTracks({ limit: 5 })
        .catch(() => ({ body: { items: [] } }));
      recommendationParams.seed_tracks = (recentlyPlayed.body.items || [])
        .map((item: any) => item.track?.id)
        .filter((id: any): id is string => typeof id === 'string')
        .slice(0, 5);
      
      if (mood === 'happy_energetic') {
        recommendationParams.target_energy = 0.8;
        recommendationParams.target_valence = 0.8;
      } else if (mood === 'chill') {
        recommendationParams.target_energy = 0.3;
        recommendationParams.target_tempo = 70;
      }
    } else {
      // Default: taste profile based
      const topTracks = await spotifyApi.getMyTopTracks({ time_range: 'medium_term', limit: 5 })
        .catch(() => ({ body: { items: [] } }));
      recommendationParams.seed_tracks = (topTracks.body.items || [])
        .map((t: any) => t.id)
        .filter((id: any): id is string => typeof id === 'string')
        .slice(0, 5);
    }

    // Fallback to default genres
    if (!recommendationParams.seed_tracks || recommendationParams.seed_tracks.length === 0) {
      recommendationParams.seed_genres = ['pop', 'indie', 'rock'];
    }

    const recommendations = await spotifyApi.getRecommendations(recommendationParams);
    
    res.json({
      type: type || 'taste_profile',
      mood,
      activity,
      tracks: recommendations.body.tracks,
      total: recommendations.body.tracks.length,
    });
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * GET /api/discovery/timeline
 * Generate discovery timeline tracking music discovery and taste evolution
 */
app.get('/api/discovery/timeline', extractSpotifyToken, extractSupabaseToken, async (req: SpotifyRequest & SupabaseRequest, res) => {
  try {
    const userToken = req.spotifyToken;
    const userId = req.userId;
    
    if (!userToken || !userId || !supabase) {
      return res.status(401).json({
        error: 'Authentication required',
        code: 'UNAUTHORIZED'
      });
    }

    const spotifyApi = createSpotifyApi(userToken);

    // Get top tracks across different time ranges
    const [topTracksShort, topTracksMedium, topTracksLong, topArtistsShort, topArtistsLong] = await Promise.all([
      spotifyApi.getMyTopTracks({ time_range: 'short_term', limit: 20 }).catch(() => ({ body: { items: [] } })),
      spotifyApi.getMyTopTracks({ time_range: 'medium_term', limit: 20 }).catch(() => ({ body: { items: [] } })),
      spotifyApi.getMyTopTracks({ time_range: 'long_term', limit: 20 }).catch(() => ({ body: { items: [] } })),
      spotifyApi.getMyTopArtists({ time_range: 'short_term', limit: 20 }).catch(() => ({ body: { items: [] } })),
      spotifyApi.getMyTopArtists({ time_range: 'long_term', limit: 20 }).catch(() => ({ body: { items: [] } })),
    ]);

    // Get analyses from database (ordered by date)
    const { data: analyses } = await supabase
      .from('analyses')
      .select('created_at, genre_distribution, personality_type, audio_dna')
      .eq('user_id', userId)
      .order('created_at', { ascending: true });

    // Analyze genre evolution
    const genreEvolution: { [key: string]: { firstSeen: string; frequency: number } } = {};
    const timelineEvents: any[] = [];

    if (analyses) {
      analyses.forEach((analysis: any, index: number) => {
        const date = analysis.created_at;
        const genres = analysis.genre_distribution || [];
        
        genres.forEach((genre: any) => {
          const genreName = genre.name || genre;
          if (!genreEvolution[genreName]) {
            genreEvolution[genreName] = {
              firstSeen: date,
              frequency: 0,
            };
            timelineEvents.push({
              type: 'genre_discovery',
              date,
              genre: genreName,
              description: `Discovered ${genreName}`,
            });
          }
          genreEvolution[genreName].frequency++;
        });

        if (index === 0 || index === analyses.length - 1) {
          timelineEvents.push({
            type: 'milestone',
            date,
            description: index === 0 
              ? 'First playlist analyzed' 
              : 'Latest playlist analyzed',
            personality: analysis.personality_type,
          });
        }
      });
    }

    // Compare short-term vs long-term to find new discoveries
    const shortTermArtists = new Set((topArtistsShort.body.items || []).map((a: any) => a.id));
    const longTermArtists = new Set((topArtistsLong.body.items || []).map((a: any) => a.id));
    const newArtists = (topArtistsShort.body.items || [])
      .filter((a: any) => !longTermArtists.has(a.id))
      .slice(0, 5);

    newArtists.forEach((artist: any) => {
      timelineEvents.push({
        type: 'artist_discovery',
        date: new Date().toISOString(),
        artist: {
          id: artist.id,
          name: artist.name,
          genres: artist.genres || [],
        },
        description: `New favorite: ${artist.name}`,
      });
    });

    // Sort timeline by date
    timelineEvents.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

    // Calculate taste evolution metrics
    const shortTermGenres = new Set(
      (topArtistsShort.body.items || []).flatMap((a: any) => a.genres || [])
    );
    const longTermGenres = new Set(
      (topArtistsLong.body.items || []).flatMap((a: any) => a.genres || [])
    );
    const genreExpansion = Array.from(shortTermGenres).filter(g => !longTermGenres.has(g)).length;
    const genreStability = Array.from(shortTermGenres).filter(g => longTermGenres.has(g)).length;

    res.json({
      timeline: timelineEvents,
      evolution: {
        genreExpansion,
        genreStability,
        totalGenresDiscovered: Object.keys(genreEvolution).length,
        newArtistsCount: newArtists.length,
        analysesCount: analyses?.length || 0,
      },
      genres: Object.entries(genreEvolution)
        .map(([name, data]) => ({ name, ...data }))
        .sort((a, b) => b.frequency - a.frequency)
        .slice(0, 10),
      periods: {
        shortTerm: {
          tracks: topTracksShort.body.items?.length || 0,
          artists: topArtistsShort.body.items?.length || 0,
          genres: shortTermGenres.size,
        },
        longTerm: {
          tracks: topTracksLong.body.items?.length || 0,
          artists: topArtistsLong.body.items?.length || 0,
          genres: longTermGenres.size,
        },
      },
    });
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * GET /api/stats
 * Get user statistics
 */
app.get('/api/stats', extractSupabaseToken, async (req: SupabaseRequest, res) => {
  try {
    const userId = req.userId;
    
    if (!userId) {
      return res.status(401).json({ 
        error: 'Authentication required',
        code: 'UNAUTHORIZED'
      });
    }

    if (!supabase) {
      return res.status(503).json({ 
        error: 'Database not configured',
        code: 'DB_NOT_CONFIGURED'
      });
    }

    // Query user_stats view (RLS will automatically filter by user_id)
    const { data: stats, error: dbError } = await supabase
      .from('user_stats')
      .select('*')
      .eq('user_id', userId)
      .single();

    if (dbError) {
      console.error('Database error:', dbError);
      return res.status(500).json({ 
        error: 'Failed to fetch stats',
        code: 'DB_ERROR'
      });
    }

    // Return stats with default values if null
    res.json({
      analysesCount: stats?.analyses_count || 0,
      battlesCount: stats?.battles_count || 0,
      savedPlaylistsCount: stats?.saved_playlists_count || 0,
      averageRating: stats?.average_rating || 0,
      averageHealthScore: stats?.average_health_score || 0,
      lastAnalysisAt: stats?.last_analysis_at || null,
      lastBattleAt: stats?.last_battle_at || null,
    });
  } catch (error: unknown) {
    const err = error as Error;
    console.error('Stats endpoint error:', err);
    res.status(500).json({ error: err.message || 'Internal server error' });
  }
});

// Health check - Comprehensive monitoring endpoint
app.get('/health', async (req, res) => {
  const health: {
    status: 'ok' | 'degraded';
    timestamp: string;
    uptime: number;
    environment: string;
    checks: {
      database: 'healthy' | 'unhealthy' | 'not_configured';
      spotify: 'healthy' | 'unhealthy' | 'not_configured';
    };
  } = {
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
    checks: {
      database: 'not_configured',
      spotify: 'not_configured',
    },
  };

  // Check database connectivity
  if (supabase) {
    try {
      const { error } = await supabase.from('users').select('id').limit(1);
      health.checks.database = error ? 'unhealthy' : 'healthy';
      if (error) health.status = 'degraded';
    } catch (e) {
      health.checks.database = 'unhealthy';
      health.status = 'degraded';
    }
  }

  // Check Spotify API
  if (process.env.SPOTIFY_CLIENT_ID) {
    try {
      const response = await fetch('https://api.spotify.com/v1', { method: 'HEAD' });
      health.checks.spotify = response.ok ? 'healthy' : 'unhealthy';
      if (!response.ok) health.status = 'degraded';
    } catch (e) {
      health.checks.spotify = 'unhealthy';
      health.status = 'degraded';
    }
  }

  res.status(health.status === 'ok' ? 200 : 503).json(health);
});

// Start server
app.listen(PORT, () => {
  console.log(`✅ Antidote Backend Server running on port ${PORT}`);
  console.log(`🌐 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`📝 Spotify Client ID: ${process.env.SPOTIFY_CLIENT_ID ? '✅ Configured' : '❌ Missing'}`);
  console.log(`🔐 Client Secret: ${process.env.SPOTIFY_CLIENT_SECRET ? '⚠️  Still configured (should be removed)' : '✅ Removed (correct)'}`);
  console.log(`🗄️  Supabase: ${supabase ? '✅ Connected' : '❌ Not configured'}`);
  
  // Log URL for local development
  if (process.env.NODE_ENV !== 'production') {
    console.log(`📍 Local URL: http://localhost:${PORT}`);
  }
});

