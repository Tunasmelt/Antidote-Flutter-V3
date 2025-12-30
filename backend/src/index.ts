import express from 'express';
import cors from 'cors';
import SpotifyWebApi from 'spotify-web-api-node';
import dotenv from 'dotenv';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

dotenv.config();

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
app.use(cors({
  origin: true,
  credentials: true,
  methods: ['GET', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Spotify-Token'],
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
// API ENDPOINTS
// ============================================================================

/**
 * POST /api/analyze
 * Analyze a Spotify playlist
 */
app.post('/api/analyze', extractSpotifyToken, async (req: SpotifyRequest, res) => {
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
      tempo: Math.round(avgTempo),
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
    
    res.json(analysisResult);
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * POST /api/battle
 * Battle two playlists
 */
app.post('/api/battle', extractSpotifyToken, async (req: SpotifyRequest, res) => {
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
    
    res.json(battleResult);
  } catch (error: unknown) {
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
    const recommendationParams: RecommendationParams = {
      limit: 20, // Default limit
    };
    
    // Handle type-based recommendations
    if ((type === 'best_next' || type === 'mood_safe') && playlistId) {
      // Get tracks from playlist and use as seeds
      const playlistIdExtracted = extractSpotifyId(playlistId as string);
      if (playlistIdExtracted) {
        const tracksResponse = await spotifyApi.getPlaylistTracks(playlistIdExtracted, { limit: 5 });
        const trackIds = tracksResponse.body.items
          .map((item: any) => item.track?.id)
          .filter((id: any): id is string => typeof id === 'string');
        if (trackIds.length > 0) {
          recommendationParams.seed_tracks = trackIds.slice(0, 5);
        }
      }
    } else if (type && !playlistId) {
      // Handle strategy-based recommendations without playlist
      // Use default genres based on strategy type
      const strategyGenres: { [key: string]: string[] } = {
        'similar_audio': ['pop', 'indie', 'alternative'],
        'genre_exploration': ['rock', 'electronic', 'hip-hop', 'jazz', 'classical'],
        'artist_collaborations': ['pop', 'indie'],
        'mood_match': ['pop', 'indie', 'acoustic'],
        'flavor_profile': ['indie', 'alternative', 'folk'],
        'discovery': ['indie', 'alternative', 'electronic'],
      };
      
      if (strategyGenres[type as string]) {
        recommendationParams.seed_genres = strategyGenres[type as string].slice(0, 5);
      } else {
        // Default fallback genres
        recommendationParams.seed_genres = ['pop', 'indie', 'rock'];
      }
    } else {
      // Use provided seeds
      if (seed_tracks && typeof seed_tracks === 'string') {
        recommendationParams.seed_tracks = seed_tracks.split(',').slice(0, 5);
      }
      if (seed_genres && typeof seed_genres === 'string') {
        recommendationParams.seed_genres = seed_genres.split(',').slice(0, 5);
      }
      if (seed_artists && typeof seed_artists === 'string') {
        recommendationParams.seed_artists = seed_artists.split(',').slice(0, 5);
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
    
    res.json(recommendations.body.tracks);
  } catch (error: unknown) {
    handleSpotifyError(error, res);
  }
});

/**
 * GET /api/playlists
 * Get user's saved playlists
 */
app.get('/api/playlists', async (req, res) => {
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

    // Query saved playlists (RLS will automatically filter by user_id)
    const { data: playlists, error: dbError } = await supabase
      .from('playlists')
      .select('*')
      .eq('user_id', user.id)
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
app.get('/api/history', async (req, res) => {
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

    // Query history view (RLS will automatically filter by user_id)
    const { data: history, error: dbError } = await supabase
      .from('history')
      .select('*')
      .eq('user_id', user.id)
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
 * GET /api/stats
 * Get user statistics
 */
app.get('/api/stats', async (req, res) => {
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

    // Query user_stats view (RLS will automatically filter by user_id)
    const { data: stats, error: dbError } = await supabase
      .from('user_stats')
      .select('*')
      .eq('user_id', user.id)
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
  console.log(`🗄️  Supabase: ${supabase ? '✅ Connected' : '❌ Not configured'}`);
  
  // Log URL for local development
  if (process.env.NODE_ENV !== 'production') {
    console.log(`📍 Local URL: http://localhost:${PORT}`);
  }
});

