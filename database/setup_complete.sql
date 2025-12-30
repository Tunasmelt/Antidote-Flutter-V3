-- ============================================================================
-- ANTIDOTE FLUTTER - COMPLETE DATABASE SETUP SCRIPT
-- ============================================================================
-- This is a comprehensive single-file setup script that creates the entire
-- database schema for the Antidote Flutter application.
--
-- WHAT THIS SCRIPT DOES:
-- 1. Creates all tables (users, playlists, tracks, analyses, battles, recommendations)
-- 2. Creates views (history, user_stats)
-- 3. Enables Row Level Security (RLS) on all tables
-- 4. Creates RLS policies for all tables and views
-- 5. Creates indexes for optimal query performance
-- 6. Creates helper functions and triggers
--
-- RUNNING THIS SCRIPT:
-- Copy and paste this entire script into your Supabase SQL Editor and run it.
-- This will set up your complete database schema in one go.
--
-- FOR FRESH DATABASE: This script is fully idempotent - safe to run on a new
-- database or re-run on an existing database. It will drop existing objects
-- before creating new ones to ensure clean setup.
--
-- UPDATED: 2024 - Includes all current features:
-- - Spotify OAuth integration
-- - Playlist analysis with personality insights
-- - Playlist battles/comparisons
-- - Music recommendations
-- - History tracking
-- - User statistics
-- ============================================================================

-- ============================================================================
-- STEP 0: CLEANUP (for re-running on existing database)
-- ============================================================================
-- Drop existing objects in reverse dependency order to avoid conflicts

-- Drop views first (they depend on tables)
DROP VIEW IF EXISTS public.user_stats CASCADE;
DROP VIEW IF EXISTS public.history CASCADE;

-- Drop triggers (they depend on functions and tables)
DROP TRIGGER IF EXISTS extract_spotify_id_on_update ON public.playlists;
DROP TRIGGER IF EXISTS extract_spotify_id_on_insert ON public.playlists;
DROP TRIGGER IF EXISTS update_track_count_on_delete ON public.tracks;
DROP TRIGGER IF EXISTS update_track_count_on_insert ON public.tracks;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS set_updated_at_playlists ON public.playlists;
DROP TRIGGER IF EXISTS set_updated_at_users ON public.users;

-- Drop policies (they depend on tables/views)
-- Note: View policies are not created (views inherit RLS from underlying tables)
DROP POLICY IF EXISTS "Users can delete own recommendations" ON public.recommendations;
DROP POLICY IF EXISTS "Users can update own recommendations" ON public.recommendations;
DROP POLICY IF EXISTS "Users can create own recommendations" ON public.recommendations;
DROP POLICY IF EXISTS "Users can view own recommendations" ON public.recommendations;
DROP POLICY IF EXISTS "Users can delete own battles" ON public.battles;
DROP POLICY IF EXISTS "Users can update own battles" ON public.battles;
DROP POLICY IF EXISTS "Users can create own battles" ON public.battles;
DROP POLICY IF EXISTS "Users can view own battles" ON public.battles;
DROP POLICY IF EXISTS "Users can delete own analyses" ON public.analyses;
DROP POLICY IF EXISTS "Users can update own analyses" ON public.analyses;
DROP POLICY IF EXISTS "Users can create own analyses" ON public.analyses;
DROP POLICY IF EXISTS "Users can view own analyses" ON public.analyses;
DROP POLICY IF EXISTS "Users can delete tracks from own playlists" ON public.tracks;
DROP POLICY IF EXISTS "Users can update tracks in own playlists" ON public.tracks;
DROP POLICY IF EXISTS "Users can insert tracks to own playlists" ON public.tracks;
DROP POLICY IF EXISTS "Users can view tracks from own playlists" ON public.tracks;
DROP POLICY IF EXISTS "Users can delete own playlists" ON public.playlists;
DROP POLICY IF EXISTS "Users can update own playlists" ON public.playlists;
DROP POLICY IF EXISTS "Users can create own playlists" ON public.playlists;
DROP POLICY IF EXISTS "Users can view own playlists" ON public.playlists;
DROP POLICY IF EXISTS "Users can delete own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;

-- Note: We don't drop tables, functions, or indexes - they use IF NOT EXISTS
-- which makes them safe to re-run. Tables are kept to preserve data.

-- ============================================================================
-- STEP 1: SCHEMA CREATION
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Users table
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

-- Playlists table
CREATE TABLE IF NOT EXISTS public.playlists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  spotify_id TEXT,
  url TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  owner TEXT,
  cover_url TEXT,
  track_count INTEGER DEFAULT 0,
  platform TEXT DEFAULT 'spotify' CHECK (platform IN ('spotify', 'apple_music', 'youtube_music', 'soundcloud')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  analyzed_at TIMESTAMP WITH TIME ZONE,
  CONSTRAINT unique_user_playlist UNIQUE (user_id, url)
);

-- Tracks table
CREATE TABLE IF NOT EXISTS public.tracks (
  id TEXT PRIMARY KEY,
  playlist_id UUID REFERENCES public.playlists(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  artists TEXT[] NOT NULL,
  album TEXT,
  album_art_url TEXT,
  release_date DATE,
  duration_ms INTEGER,
  popularity INTEGER,
  genres TEXT[],
  spotify_id TEXT,
  audio_features JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Analyses table
CREATE TABLE IF NOT EXISTS public.analyses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  playlist_id UUID REFERENCES public.playlists(id) ON DELETE CASCADE,
  personality_type TEXT,
  personality_description TEXT,
  health_score INTEGER CHECK (health_score >= 0 AND health_score <= 100),
  health_status TEXT,
  overall_rating DECIMAL(3,1) CHECK (overall_rating >= 0 AND overall_rating <= 10),
  rating_description TEXT,
  audio_dna JSONB,
  genre_distribution JSONB,
  subgenres TEXT[],
  top_tracks JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Battles table
CREATE TABLE IF NOT EXISTS public.battles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  playlist1_id UUID REFERENCES public.playlists(id) ON DELETE CASCADE,
  playlist2_id UUID REFERENCES public.playlists(id) ON DELETE CASCADE,
  compatibility_score INTEGER CHECK (compatibility_score >= 0 AND compatibility_score <= 100),
  winner TEXT CHECK (winner IN ('playlist1', 'playlist2', 'tie')),
  winner_reason TEXT,
  shared_artists TEXT[],
  shared_genres TEXT[],
  shared_tracks JSONB,
  audio_data JSONB,
  playlist1_data JSONB,
  playlist2_data JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT battles_different_playlists CHECK (playlist1_id != playlist2_id)
);

-- Recommendations table
CREATE TABLE IF NOT EXISTS public.recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  playlist_id UUID REFERENCES public.playlists(id) ON DELETE CASCADE,
  strategy TEXT NOT NULL CHECK (strategy IN (
    'similar_audio',
    'genre_exploration',
    'artist_collaborations',
    'mood_match',
    'flavor_profile',
    'discovery'
  )),
  recommended_tracks JSONB NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- History view
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
JOIN public.playlists p ON a.playlist_id = p.id

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

-- User stats view
CREATE OR REPLACE VIEW public.user_stats AS
SELECT 
  u.id as user_id,
  COUNT(DISTINCT a.id) as analyses_count,
  COUNT(DISTINCT b.id) as battles_count,
  COUNT(DISTINCT p.id) as saved_playlists_count,
  COALESCE(AVG(a.overall_rating), 0) as average_rating,
  COALESCE(AVG(a.health_score), 0) as average_health_score,
  MAX(a.created_at) as last_analysis_at,
  MAX(b.created_at) as last_battle_at
FROM public.users u
LEFT JOIN public.analyses a ON u.id = a.user_id
LEFT JOIN public.battles b ON u.id = b.user_id
LEFT JOIN public.playlists p ON u.id = p.user_id
GROUP BY u.id;

-- ============================================================================
-- STEP 2: ENABLE ROW LEVEL SECURITY
-- ============================================================================
-- Note: Tables are created in Step 1, so these ALTER statements are safe
-- IMPORTANT: RLS can ONLY be enabled on TABLES, not on VIEWS
-- Views (history, user_stats) inherit security from underlying tables
-- and don't need RLS enabled - policies can be created directly on views

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.battles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can delete own profile" ON public.users FOR DELETE USING (auth.uid() = id);

-- Playlists policies
CREATE POLICY "Users can view own playlists" ON public.playlists FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own playlists" ON public.playlists FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own playlists" ON public.playlists FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own playlists" ON public.playlists FOR DELETE USING (auth.uid() = user_id);

-- Tracks policies
CREATE POLICY "Users can view tracks from own playlists" ON public.tracks FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.playlists p WHERE p.id = tracks.playlist_id AND p.user_id = auth.uid()));
CREATE POLICY "Users can insert tracks to own playlists" ON public.tracks FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM public.playlists p WHERE p.id = tracks.playlist_id AND p.user_id = auth.uid()));
CREATE POLICY "Users can update tracks in own playlists" ON public.tracks FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.playlists p WHERE p.id = tracks.playlist_id AND p.user_id = auth.uid()))
  WITH CHECK (EXISTS (SELECT 1 FROM public.playlists p WHERE p.id = tracks.playlist_id AND p.user_id = auth.uid()));
CREATE POLICY "Users can delete tracks from own playlists" ON public.tracks FOR DELETE
  USING (EXISTS (SELECT 1 FROM public.playlists p WHERE p.id = tracks.playlist_id AND p.user_id = auth.uid()));

-- Analyses policies
CREATE POLICY "Users can view own analyses" ON public.analyses FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own analyses" ON public.analyses FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own analyses" ON public.analyses FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own analyses" ON public.analyses FOR DELETE USING (auth.uid() = user_id);

-- Battles policies
CREATE POLICY "Users can view own battles" ON public.battles FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own battles" ON public.battles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own battles" ON public.battles FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own battles" ON public.battles FOR DELETE USING (auth.uid() = user_id);

-- Recommendations policies
CREATE POLICY "Users can view own recommendations" ON public.recommendations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own recommendations" ON public.recommendations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own recommendations" ON public.recommendations FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own recommendations" ON public.recommendations FOR DELETE USING (auth.uid() = user_id);

-- View policies
-- IMPORTANT: RLS policies CANNOT be created directly on views in PostgreSQL/Supabase.
-- Views automatically inherit RLS from their underlying tables (analyses, battles).
-- Since those tables already have RLS policies filtering by user_id, the views
-- are automatically secure - no additional policies needed.
-- 
-- If you see "history is not a table" errors, this is why - views don't support
-- CREATE POLICY. The security is inherited from underlying tables.

-- ============================================================================
-- STEP 3: CREATE INDEXES
-- ============================================================================

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username) WHERE username IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email) WHERE email IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_users_spotify_id ON public.users(spotify_id) WHERE spotify_id IS NOT NULL;

-- Playlists indexes
CREATE INDEX IF NOT EXISTS idx_playlists_user_id ON public.playlists(user_id);
CREATE INDEX IF NOT EXISTS idx_playlists_url ON public.playlists(url);
CREATE INDEX IF NOT EXISTS idx_playlists_spotify_id ON public.playlists(spotify_id) WHERE spotify_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_playlists_created_at ON public.playlists(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_playlists_analyzed_at ON public.playlists(analyzed_at DESC) WHERE analyzed_at IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_playlists_user_created ON public.playlists(user_id, created_at DESC);

-- Tracks indexes
CREATE INDEX IF NOT EXISTS idx_tracks_playlist_id ON public.tracks(playlist_id);
CREATE INDEX IF NOT EXISTS idx_tracks_spotify_id ON public.tracks(spotify_id) WHERE spotify_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tracks_name_trgm ON public.tracks USING gin(name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_tracks_artists ON public.tracks USING gin(artists);
CREATE INDEX IF NOT EXISTS idx_tracks_genres ON public.tracks USING gin(genres);
CREATE INDEX IF NOT EXISTS idx_tracks_audio_features ON public.tracks USING gin(audio_features);
CREATE INDEX IF NOT EXISTS idx_tracks_playlist_popularity ON public.tracks(playlist_id, popularity DESC NULLS LAST);

-- Analyses indexes
CREATE INDEX IF NOT EXISTS idx_analyses_user_id ON public.analyses(user_id);
CREATE INDEX IF NOT EXISTS idx_analyses_playlist_id ON public.analyses(playlist_id);
CREATE INDEX IF NOT EXISTS idx_analyses_created_at ON public.analyses(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analyses_user_created ON public.analyses(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_analyses_health_score ON public.analyses(health_score DESC);
CREATE INDEX IF NOT EXISTS idx_analyses_rating ON public.analyses(overall_rating DESC);
CREATE INDEX IF NOT EXISTS idx_analyses_personality_type ON public.analyses(personality_type) WHERE personality_type IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_analyses_genre_distribution ON public.analyses USING gin(genre_distribution);

-- Battles indexes
CREATE INDEX IF NOT EXISTS idx_battles_user_id ON public.battles(user_id);
CREATE INDEX IF NOT EXISTS idx_battles_playlist1_id ON public.battles(playlist1_id);
CREATE INDEX IF NOT EXISTS idx_battles_playlist2_id ON public.battles(playlist2_id);
CREATE INDEX IF NOT EXISTS idx_battles_created_at ON public.battles(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_battles_user_created ON public.battles(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_battles_compatibility_score ON public.battles(compatibility_score DESC);
CREATE INDEX IF NOT EXISTS idx_battles_winner ON public.battles(winner) WHERE winner IS NOT NULL;

-- Recommendations indexes
CREATE INDEX IF NOT EXISTS idx_recommendations_user_id ON public.recommendations(user_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_playlist_id ON public.recommendations(playlist_id);
CREATE INDEX IF NOT EXISTS idx_recommendations_strategy ON public.recommendations(strategy);
CREATE INDEX IF NOT EXISTS idx_recommendations_created_at ON public.recommendations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_recommendations_user_strategy_created ON public.recommendations(user_id, strategy, created_at DESC);

-- Full text search indexes
CREATE INDEX IF NOT EXISTS idx_playlists_name_search ON public.playlists USING gin(to_tsvector('english', name));
CREATE INDEX IF NOT EXISTS idx_tracks_name_search ON public.tracks USING gin(to_tsvector('english', name));

-- ============================================================================
-- STEP 4: CREATE FUNCTIONS AND TRIGGERS
-- ============================================================================

-- Helper functions
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, created_at)
  VALUES (NEW.id, NEW.email, NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.update_playlist_track_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.playlists
    SET track_count = (SELECT COUNT(*) FROM public.tracks WHERE playlist_id = NEW.playlist_id)
    WHERE id = NEW.playlist_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.playlists
    SET track_count = (SELECT COUNT(*) FROM public.tracks WHERE playlist_id = OLD.playlist_id)
    WHERE id = OLD.playlist_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Function to extract Spotify ID from URL
-- Supports various Spotify URL formats:
-- - https://open.spotify.com/playlist/37i9dQZF1DX0XUsuxWHRQd
-- - spotify:playlist:37i9dQZF1DX0XUsuxWHRQd
-- - https://open.spotify.com/track/4iV5W9uYEdYUVa79Axb7Rh
CREATE OR REPLACE FUNCTION public.extract_spotify_id(url TEXT)
RETURNS TEXT AS $$
DECLARE
  spotify_id TEXT;
BEGIN
  -- Return NULL if URL is empty or null
  IF url IS NULL OR url = '' THEN
    RETURN NULL;
  END IF;
  
  -- Try standard URL format: /playlist/ID or /track/ID or /album/ID
  SELECT (regexp_match(url, '/(?:playlist|track|album)/([a-zA-Z0-9]+)'))[1] INTO spotify_id;
  IF spotify_id IS NOT NULL THEN
    RETURN spotify_id;
  END IF;
  
  -- Try URI format: spotify:playlist:ID
  SELECT (regexp_match(url, 'spotify:(?:playlist|track|album):([a-zA-Z0-9]+)'))[1] INTO spotify_id;
  IF spotify_id IS NOT NULL THEN
    RETURN spotify_id;
  END IF;
  
  -- Return NULL if no match found
  RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE FUNCTION public.set_playlist_spotify_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.url IS NOT NULL AND NEW.platform = 'spotify' THEN
    NEW.spotify_id = public.extract_spotify_id(NEW.url);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers
CREATE TRIGGER set_updated_at_users BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at_playlists BEFORE UPDATE ON public.playlists FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
CREATE TRIGGER update_track_count_on_insert AFTER INSERT ON public.tracks FOR EACH ROW EXECUTE FUNCTION public.update_playlist_track_count();
CREATE TRIGGER update_track_count_on_delete AFTER DELETE ON public.tracks FOR EACH ROW EXECUTE FUNCTION public.update_playlist_track_count();
CREATE TRIGGER extract_spotify_id_on_insert BEFORE INSERT ON public.playlists FOR EACH ROW EXECUTE FUNCTION public.set_playlist_spotify_id();
CREATE TRIGGER extract_spotify_id_on_update BEFORE UPDATE ON public.playlists FOR EACH ROW WHEN (OLD.url IS DISTINCT FROM NEW.url OR OLD.platform IS DISTINCT FROM NEW.platform) EXECUTE FUNCTION public.set_playlist_spotify_id();

-- ============================================================================
-- SETUP COMPLETE!
-- ============================================================================
-- Your database is now ready to use.
-- Verify by running: SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
-- ============================================================================

