-- ============================================================================
-- ANTIDOTE FLUTTER - SUPABASE DATABASE SCHEMA
-- ============================================================================
-- This script creates all necessary tables for the Antidote Flutter application
-- Run this script in your Supabase SQL Editor
-- 
-- FOR FRESH DATABASE: This script is safe to run on a new database
-- All tables use IF NOT EXISTS to prevent errors on re-runs
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- For text search

-- ============================================================================
-- DROP EXISTING VIEWS (if re-running on existing database)
-- ============================================================================
DROP VIEW IF EXISTS public.user_stats CASCADE;
DROP VIEW IF EXISTS public.history CASCADE;

-- ============================================================================
-- USERS TABLE
-- ============================================================================
-- Extends Supabase auth.users with additional profile information
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  email TEXT,
  spotify_id TEXT,
  avatar_url TEXT,
  display_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- PLAYLISTS TABLE
-- ============================================================================
-- Stores saved playlists from Spotify and other platforms
CREATE TABLE IF NOT EXISTS public.playlists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  spotify_id TEXT, -- Spotify playlist ID extracted from URL
  url TEXT NOT NULL, -- Full playlist URL
  name TEXT NOT NULL,
  description TEXT,
  owner TEXT, -- Playlist owner/creator name
  cover_url TEXT, -- Playlist cover image URL
  track_count INTEGER DEFAULT 0,
  platform TEXT DEFAULT 'spotify' CHECK (platform IN ('spotify', 'apple_music', 'youtube_music', 'soundcloud')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  analyzed_at TIMESTAMP WITH TIME ZONE, -- Last time this playlist was analyzed
  
  -- Ensure unique playlists per user (same URL can't be saved twice)
  CONSTRAINT unique_user_playlist UNIQUE (user_id, url)
);

-- ============================================================================
-- TRACKS TABLE
-- ============================================================================
-- Stores individual tracks from playlists with audio features
CREATE TABLE IF NOT EXISTS public.tracks (
  id TEXT PRIMARY KEY, -- Spotify track ID or generated UUID
  playlist_id UUID REFERENCES public.playlists(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  artists TEXT[] NOT NULL, -- Array of artist names
  album TEXT,
  album_art_url TEXT,
  release_date DATE,
  duration_ms INTEGER,
  popularity INTEGER,
  genres TEXT[], -- Array of genre tags
  spotify_id TEXT, -- Original Spotify track ID
  audio_features JSONB, -- Full audio features object (energy, danceability, etc.)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Index for faster lookups
  CONSTRAINT tracks_playlist_fk FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON DELETE CASCADE
);

-- ============================================================================
-- ANALYSES TABLE
-- ============================================================================
-- Stores playlist analysis results
CREATE TABLE IF NOT EXISTS public.analyses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  playlist_id UUID REFERENCES public.playlists(id) ON DELETE CASCADE,
  
  -- Analysis results
  personality_type TEXT, -- e.g., "The Explorer", "The Nostalgic"
  personality_description TEXT,
  health_score INTEGER CHECK (health_score >= 0 AND health_score <= 100),
  health_status TEXT, -- e.g., "Exceptional", "Good", "Average", "Needs Work"
  overall_rating DECIMAL(3,1) CHECK (overall_rating >= 0 AND overall_rating <= 10),
  rating_description TEXT,
  
  -- Audio DNA (averages)
  audio_dna JSONB, -- {energy, danceability, valence, acousticness, instrumentalness, tempo}
  
  -- Genre and subgenre data
  genre_distribution JSONB, -- Array of {name, value} objects
  subgenres TEXT[], -- Array of subgenre strings
  
  -- Top tracks
  top_tracks JSONB, -- Array of {name, artist, albumArt} objects
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure one analysis per playlist per user (or allow multiple for history)
  CONSTRAINT analyses_playlist_fk FOREIGN KEY (playlist_id) REFERENCES public.playlists(id) ON DELETE CASCADE
);

-- ============================================================================
-- BATTLES/COMPARISONS TABLE
-- ============================================================================
-- Stores playlist battle/comparison results
CREATE TABLE IF NOT EXISTS public.battles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  playlist1_id UUID REFERENCES public.playlists(id) ON DELETE CASCADE,
  playlist2_id UUID REFERENCES public.playlists(id) ON DELETE CASCADE,
  
  -- Battle results
  compatibility_score INTEGER CHECK (compatibility_score >= 0 AND compatibility_score <= 100),
  winner TEXT CHECK (winner IN ('playlist1', 'playlist2', 'tie')),
  winner_reason TEXT,
  
  -- Shared content
  shared_artists TEXT[], -- Array of shared artist names
  shared_genres TEXT[], -- Array of shared genre names
  shared_tracks JSONB, -- Array of {title, artist} objects
  
  -- Audio comparison data
  audio_data JSONB, -- Comparison of audio features between playlists
  
  -- Playlist battle data (scores, track counts)
  playlist1_data JSONB, -- {name, owner, image, score, tracks}
  playlist2_data JSONB, -- {name, owner, image, score, tracks}
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT battles_playlist1_fk FOREIGN KEY (playlist1_id) REFERENCES public.playlists(id) ON DELETE CASCADE,
  CONSTRAINT battles_playlist2_fk FOREIGN KEY (playlist2_id) REFERENCES public.playlists(id) ON DELETE CASCADE,
  CONSTRAINT battles_different_playlists CHECK (playlist1_id != playlist2_id)
);

-- ============================================================================
-- RECOMMENDATIONS TABLE
-- ============================================================================
-- Stores AI-powered music recommendations
CREATE TABLE IF NOT EXISTS public.recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  playlist_id UUID REFERENCES public.playlists(id) ON DELETE CASCADE,
  
  -- Recommendation strategy type
  strategy TEXT NOT NULL CHECK (strategy IN (
    'similar_audio',
    'genre_exploration',
    'artist_collaborations',
    'mood_match',
    'flavor_profile',
    'discovery'
  )),
  
  -- Recommended tracks
  recommended_tracks JSONB NOT NULL, -- Array of track objects with full details
  
  -- Metadata
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- LIKED TRACKS TABLE
-- ============================================================================
-- Stores user's liked tracks from recommendations/discovery
CREATE TABLE IF NOT EXISTS public.liked_tracks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  track_id TEXT NOT NULL, -- Internal track ID
  track_name TEXT NOT NULL,
  artist_name TEXT NOT NULL,
  album_art_url TEXT,
  preview_url TEXT,
  spotify_id TEXT, -- Spotify track ID
  liked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique liked tracks per user (same track can't be liked twice)
  CONSTRAINT unique_user_liked_track UNIQUE (user_id, spotify_id)
);

-- ============================================================================
-- TASTE PROFILES TABLE
-- ============================================================================
-- Stores computed user taste profiles aggregated from analyses
CREATE TABLE IF NOT EXISTS public.taste_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
  
  -- Aggregated taste data
  top_genres JSONB, -- Map of genre -> percentage (e.g., {"Pop": 45.5, "Rock": 30.2})
  top_artists JSONB, -- Map of artist -> percentage (e.g., {"Artist Name": 15.3})
  audio_features JSONB, -- Map of feature -> average value (e.g., {"energy": 0.75, "danceability": 0.68})
  
  -- Metadata
  total_playlists_analyzed INTEGER DEFAULT 0,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- HISTORY TABLE (VIEW)
-- ============================================================================
-- Combined view of analyses and battles for history screen
-- This is a view that combines analyses and battles for easy querying
CREATE OR REPLACE VIEW public.history AS
SELECT 
  'analysis' as type,
  a.id,
  a.user_id,
  a.created_at,
  p.name as playlist_name,
  p.cover_url,
  p.url as playlist_url,
  a.health_score as score,
  a.overall_rating as rating,
  NULL::TEXT as winner,
  NULL::INTEGER as compatibility_score
FROM public.analyses a
JOIN public.playlists p ON a.playlist_id::UUID = p.id::UUID

UNION ALL

SELECT 
  'battle' as type,
  b.id,
  b.user_id,
  b.created_at,
  CONCAT(
    COALESCE((b.playlist1_data->>'name'), 'Playlist 1'),
    ' vs ',
    COALESCE((b.playlist2_data->>'name'), 'Playlist 2')
  ) as playlist_name,
  COALESCE((b.playlist1_data->>'image'), (b.playlist2_data->>'image')) as cover_url,
  NULL::TEXT as playlist_url,
  NULL::INTEGER as score,
  NULL::DECIMAL as rating,
  b.winner,
  b.compatibility_score
FROM public.battles b;

-- ============================================================================
-- USER STATS VIEW
-- ============================================================================
-- Aggregated statistics for user profile
CREATE OR REPLACE VIEW public.user_stats AS
SELECT 
  u.id as user_id,
  COUNT(DISTINCT a.id) as analyses_count,
  COUNT(DISTINCT b.id) as battles_count,
  COUNT(DISTINCT p.id) as saved_playlists_count,
  COUNT(DISTINCT lt.id) as liked_tracks_count,
  COALESCE(AVG(a.overall_rating), 0) as average_rating,
  COALESCE(AVG(a.health_score), 0) as average_health_score,
  MAX(a.created_at) as last_analysis_at,
  MAX(b.created_at) as last_battle_at,
  MAX(tp.last_updated) as taste_profile_last_updated
FROM public.users u
LEFT JOIN public.analyses a ON u.id = a.user_id
LEFT JOIN public.battles b ON u.id = b.user_id
LEFT JOIN public.playlists p ON u.id = p.user_id
LEFT JOIN public.liked_tracks lt ON u.id = lt.user_id
LEFT JOIN public.taste_profiles tp ON u.id = tp.user_id
GROUP BY u.id;

-- ============================================================================
-- COMMENTS
-- ============================================================================
COMMENT ON TABLE public.users IS 'User profiles extending Supabase auth.users';
COMMENT ON TABLE public.playlists IS 'Saved playlists from Spotify and other platforms';
COMMENT ON TABLE public.tracks IS 'Individual tracks with audio features';
COMMENT ON TABLE public.analyses IS 'Playlist analysis results with personality insights';
COMMENT ON TABLE public.battles IS 'Playlist battle/comparison results';
COMMENT ON TABLE public.recommendations IS 'AI-powered music recommendations';
COMMENT ON TABLE public.liked_tracks IS 'User liked tracks from recommendations and discovery';
COMMENT ON TABLE public.taste_profiles IS 'Computed user taste profiles aggregated from analyses';
COMMENT ON VIEW public.history IS 'Combined view of analyses and battles for history screen';
COMMENT ON VIEW public.user_stats IS 'Aggregated user statistics for profile display';

