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
-- - Liked tracks storage
-- - Taste profile caching
-- ============================================================================

-- ============================================================================
-- STEP 0: CLEANUP (for re-running on existing database)
-- ============================================================================
-- Drop existing objects in reverse dependency order to avoid conflicts

-- Drop views first (they depend on tables)
DROP VIEW IF EXISTS public.user_stats CASCADE;
DROP VIEW IF EXISTS public.history CASCADE;

-- Drop new table triggers (only if tables exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'liked_tracks') THEN
    DROP TRIGGER IF EXISTS set_updated_at_liked_tracks ON public.liked_tracks;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'taste_profiles') THEN
    DROP TRIGGER IF EXISTS set_updated_at_taste_profiles ON public.taste_profiles;
  END IF;
END $$;

-- Drop triggers (they depend on functions and tables)
-- Only drop if tables exist
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'playlists') THEN
    DROP TRIGGER IF EXISTS extract_spotify_id_on_update ON public.playlists;
    DROP TRIGGER IF EXISTS extract_spotify_id_on_insert ON public.playlists;
    DROP TRIGGER IF EXISTS set_updated_at_playlists ON public.playlists;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tracks') THEN
    DROP TRIGGER IF EXISTS update_track_count_on_delete ON public.tracks;
    DROP TRIGGER IF EXISTS update_track_count_on_insert ON public.tracks;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
    DROP TRIGGER IF EXISTS set_updated_at_users ON public.users;
  END IF;
END $$;
-- Auth triggers can always be dropped (auth schema always exists)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop policies (they depend on tables/views)
-- Note: View policies are not created (views inherit RLS from underlying tables)
-- Drop policies for new tables (only if tables exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'taste_profiles') THEN
    DROP POLICY IF EXISTS "Users can delete own taste profiles" ON public.taste_profiles;
    DROP POLICY IF EXISTS "Users can update own taste profiles" ON public.taste_profiles;
    DROP POLICY IF EXISTS "Users can create own taste profiles" ON public.taste_profiles;
    DROP POLICY IF EXISTS "Users can view own taste profiles" ON public.taste_profiles;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'liked_tracks') THEN
    DROP POLICY IF EXISTS "Users can delete own liked tracks" ON public.liked_tracks;
    DROP POLICY IF EXISTS "Users can update own liked tracks" ON public.liked_tracks;
    DROP POLICY IF EXISTS "Users can create own liked tracks" ON public.liked_tracks;
    DROP POLICY IF EXISTS "Users can view own liked tracks" ON public.liked_tracks;
  END IF;
END $$;
-- Drop policies for existing tables (only if tables exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'recommendations') THEN
    DROP POLICY IF EXISTS "Users can delete own recommendations" ON public.recommendations;
    DROP POLICY IF EXISTS "Users can update own recommendations" ON public.recommendations;
    DROP POLICY IF EXISTS "Users can create own recommendations" ON public.recommendations;
    DROP POLICY IF EXISTS "Users can view own recommendations" ON public.recommendations;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'battles') THEN
    DROP POLICY IF EXISTS "Users can delete own battles" ON public.battles;
    DROP POLICY IF EXISTS "Users can update own battles" ON public.battles;
    DROP POLICY IF EXISTS "Users can create own battles" ON public.battles;
    DROP POLICY IF EXISTS "Users can view own battles" ON public.battles;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'analyses') THEN
    DROP POLICY IF EXISTS "Users can delete own analyses" ON public.analyses;
    DROP POLICY IF EXISTS "Users can update own analyses" ON public.analyses;
    DROP POLICY IF EXISTS "Users can create own analyses" ON public.analyses;
    DROP POLICY IF EXISTS "Users can view own analyses" ON public.analyses;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tracks') THEN
    DROP POLICY IF EXISTS "Users can delete tracks from own playlists" ON public.tracks;
    DROP POLICY IF EXISTS "Users can update tracks in own playlists" ON public.tracks;
    DROP POLICY IF EXISTS "Users can insert tracks to own playlists" ON public.tracks;
    DROP POLICY IF EXISTS "Users can view tracks from own playlists" ON public.tracks;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'playlists') THEN
    DROP POLICY IF EXISTS "Users can delete own playlists" ON public.playlists;
    DROP POLICY IF EXISTS "Users can update own playlists" ON public.playlists;
    DROP POLICY IF EXISTS "Users can create own playlists" ON public.playlists;
    DROP POLICY IF EXISTS "Users can view own playlists" ON public.playlists;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
    DROP POLICY IF EXISTS "Users can delete own profile" ON public.users;
    DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
    DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
    DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
  END IF;
END $$;

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

-- Ensure all required columns exist in users table (for existing tables)
DO $$
BEGIN
  -- Add username if missing (nullable, so no default needed)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'users' 
                 AND column_name = 'username') THEN
    ALTER TABLE public.users ADD COLUMN username TEXT;
    -- Add unique constraint if it doesn't exist (using partial unique index for nullable column)
    IF NOT EXISTS (SELECT 1 FROM pg_indexes 
                   WHERE schemaname = 'public' 
                   AND tablename = 'users' 
                   AND indexname = 'users_username_key') THEN
      CREATE UNIQUE INDEX users_username_key ON public.users(username) WHERE username IS NOT NULL;
    END IF;
  END IF;
  
  -- Add other missing columns
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'users' 
                 AND column_name = 'spotify_id') THEN
    ALTER TABLE public.users ADD COLUMN spotify_id TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'users' 
                 AND column_name = 'avatar_url') THEN
    ALTER TABLE public.users ADD COLUMN avatar_url TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'users' 
                 AND column_name = 'display_name') THEN
    ALTER TABLE public.users ADD COLUMN display_name TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'users' 
                 AND column_name = 'updated_at') THEN
    ALTER TABLE public.users ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
  END IF;
END $$;

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

-- Ensure all required columns exist (for existing tables)
DO $$
DECLARE
  has_url BOOLEAN;
  has_name BOOLEAN;
BEGIN
  -- Check if columns exist
  SELECT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'playlists' 
                 AND column_name = 'url') INTO has_url;
  
  SELECT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'playlists' 
                 AND column_name = 'name') INTO has_name;
  
  -- Add url column if it doesn't exist (required)
  IF NOT has_url THEN
    ALTER TABLE public.playlists ADD COLUMN url TEXT;
    -- Set a default value for existing rows
    UPDATE public.playlists SET url = 'https://open.spotify.com/playlist/unknown' WHERE url IS NULL;
    ALTER TABLE public.playlists ALTER COLUMN url SET NOT NULL;
  END IF;
  
  -- Add name column if it doesn't exist
  IF NOT has_name THEN
    ALTER TABLE public.playlists ADD COLUMN name TEXT;
    -- Update existing rows with a default value (use url if available, otherwise default)
    IF has_url THEN
      UPDATE public.playlists SET name = COALESCE(url, 'Unnamed Playlist') WHERE name IS NULL;
    ELSE
      UPDATE public.playlists SET name = 'Unnamed Playlist' WHERE name IS NULL;
    END IF;
    -- Make it NOT NULL after setting defaults
    ALTER TABLE public.playlists ALTER COLUMN name SET NOT NULL;
  END IF;
  
  -- Add other columns if they don't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'playlists' 
                 AND column_name = 'cover_url') THEN
    ALTER TABLE public.playlists ADD COLUMN cover_url TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'playlists' 
                 AND column_name = 'analyzed_at') THEN
    ALTER TABLE public.playlists ADD COLUMN analyzed_at TIMESTAMP WITH TIME ZONE;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'playlists' 
                 AND column_name = 'platform') THEN
    ALTER TABLE public.playlists ADD COLUMN platform TEXT DEFAULT 'spotify';
    -- Add check constraint if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE table_schema = 'public' 
                   AND table_name = 'playlists' 
                   AND constraint_name = 'playlists_platform_check') THEN
      ALTER TABLE public.playlists ADD CONSTRAINT playlists_platform_check 
        CHECK (platform IN ('spotify', 'apple_music', 'youtube_music', 'soundcloud'));
    END IF;
  END IF;
  
  -- Ensure unique constraint exists for playlists (for existing tables)
  IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                 WHERE table_schema = 'public' 
                 AND table_name = 'playlists' 
                 AND constraint_name = 'unique_user_playlist') THEN
    -- Add unique constraint if columns exist
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_schema = 'public' 
               AND table_name = 'playlists' 
               AND column_name = 'user_id')
       AND EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'playlists' 
                   AND column_name = 'url') THEN
      ALTER TABLE public.playlists ADD CONSTRAINT unique_user_playlist 
        UNIQUE (user_id, url);
    END IF;
  END IF;
END $$;

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

-- Ensure all required columns exist in tracks table (for existing tables)
DO $$
DECLARE
  has_name BOOLEAN;
  has_artists BOOLEAN;
BEGIN
  -- Check if required columns exist
  SELECT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'tracks' 
                 AND column_name = 'name') INTO has_name;
  
  SELECT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'tracks' 
                 AND column_name = 'artists') INTO has_artists;
  
  -- Add name if missing (required)
  IF NOT has_name THEN
    ALTER TABLE public.tracks ADD COLUMN name TEXT;
    UPDATE public.tracks SET name = 'Unknown Track' WHERE name IS NULL;
    ALTER TABLE public.tracks ALTER COLUMN name SET NOT NULL;
  END IF;
  
  -- Add artists if missing (required)
  IF NOT has_artists THEN
    ALTER TABLE public.tracks ADD COLUMN artists TEXT[];
    UPDATE public.tracks SET artists = ARRAY['Unknown Artist'] WHERE artists IS NULL;
    ALTER TABLE public.tracks ALTER COLUMN artists SET NOT NULL;
  END IF;
  
  -- Add other optional columns if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'tracks' 
                 AND column_name = 'album_art_url') THEN
    ALTER TABLE public.tracks ADD COLUMN album_art_url TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'tracks' 
                 AND column_name = 'audio_features') THEN
    ALTER TABLE public.tracks ADD COLUMN audio_features JSONB;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'tracks' 
                 AND column_name = 'genres') THEN
    ALTER TABLE public.tracks ADD COLUMN genres TEXT[];
  END IF;
END $$;

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

-- Ensure all required columns exist in analyses table (for existing tables)
DO $$
BEGIN
  -- Add health_score if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'analyses' 
                 AND column_name = 'health_score') THEN
    ALTER TABLE public.analyses ADD COLUMN health_score INTEGER;
    -- Add check constraint if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE table_schema = 'public' 
                   AND table_name = 'analyses' 
                   AND constraint_name = 'analyses_health_score_check') THEN
      ALTER TABLE public.analyses ADD CONSTRAINT analyses_health_score_check 
        CHECK (health_score IS NULL OR (health_score >= 0 AND health_score <= 100));
    END IF;
  END IF;
  
  -- Add other missing columns
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'analyses' 
                 AND column_name = 'health_status') THEN
    ALTER TABLE public.analyses ADD COLUMN health_status TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'analyses' 
                 AND column_name = 'overall_rating') THEN
    ALTER TABLE public.analyses ADD COLUMN overall_rating DECIMAL(3,1);
    -- Add check constraint if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE table_schema = 'public' 
                   AND table_name = 'analyses' 
                   AND constraint_name = 'analyses_rating_check') THEN
      ALTER TABLE public.analyses ADD CONSTRAINT analyses_rating_check 
        CHECK (overall_rating IS NULL OR (overall_rating >= 0 AND overall_rating <= 10));
    END IF;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'analyses' 
                 AND column_name = 'rating_description') THEN
    ALTER TABLE public.analyses ADD COLUMN rating_description TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'analyses' 
                 AND column_name = 'audio_dna') THEN
    ALTER TABLE public.analyses ADD COLUMN audio_dna JSONB;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'analyses' 
                 AND column_name = 'genre_distribution') THEN
    ALTER TABLE public.analyses ADD COLUMN genre_distribution JSONB;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'analyses' 
                 AND column_name = 'subgenres') THEN
    ALTER TABLE public.analyses ADD COLUMN subgenres TEXT[];
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'analyses' 
                 AND column_name = 'top_tracks') THEN
    ALTER TABLE public.analyses ADD COLUMN top_tracks JSONB;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'analyses' 
                 AND column_name = 'personality_type') THEN
    ALTER TABLE public.analyses ADD COLUMN personality_type TEXT;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'analyses' 
                 AND column_name = 'personality_description') THEN
    ALTER TABLE public.analyses ADD COLUMN personality_description TEXT;
  END IF;
END $$;

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

-- Ensure all required columns exist in battles table (for existing tables)
DO $$
BEGIN
  -- Add missing columns
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'battles' 
                 AND column_name = 'compatibility_score') THEN
    ALTER TABLE public.battles ADD COLUMN compatibility_score INTEGER;
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE table_schema = 'public' 
                   AND table_name = 'battles' 
                   AND constraint_name = 'battles_compatibility_score_check') THEN
      ALTER TABLE public.battles ADD CONSTRAINT battles_compatibility_score_check 
        CHECK (compatibility_score IS NULL OR (compatibility_score >= 0 AND compatibility_score <= 100));
    END IF;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'battles' 
                 AND column_name = 'playlist1_data') THEN
    ALTER TABLE public.battles ADD COLUMN playlist1_data JSONB;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'battles' 
                 AND column_name = 'playlist2_data') THEN
    ALTER TABLE public.battles ADD COLUMN playlist2_data JSONB;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'battles' 
                 AND column_name = 'shared_tracks') THEN
    ALTER TABLE public.battles ADD COLUMN shared_tracks JSONB;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'battles' 
                 AND column_name = 'audio_data') THEN
    ALTER TABLE public.battles ADD COLUMN audio_data JSONB;
  END IF;
  
  -- Add winner column if missing
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'battles' 
                 AND column_name = 'winner') THEN
    ALTER TABLE public.battles ADD COLUMN winner TEXT;
    -- Add check constraint for winner if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE table_schema = 'public' 
                   AND table_name = 'battles' 
                   AND constraint_name = 'battles_winner_check') THEN
      ALTER TABLE public.battles ADD CONSTRAINT battles_winner_check 
        CHECK (winner IS NULL OR winner IN ('playlist1', 'playlist2', 'tie'));
    END IF;
  END IF;
  
  -- Add check constraint for different playlists if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                 WHERE table_schema = 'public' 
                 AND table_name = 'battles' 
                 AND constraint_name = 'battles_different_playlists') THEN
    ALTER TABLE public.battles ADD CONSTRAINT battles_different_playlists 
      CHECK (playlist1_id != playlist2_id);
  END IF;
END $$;

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

-- Ensure all required columns exist in recommendations table (for existing tables)
DO $$
BEGIN
  -- Add strategy if missing (required)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'recommendations' 
                 AND column_name = 'strategy') THEN
    ALTER TABLE public.recommendations ADD COLUMN strategy TEXT;
    UPDATE public.recommendations SET strategy = 'discovery' WHERE strategy IS NULL;
    ALTER TABLE public.recommendations ALTER COLUMN strategy SET NOT NULL;
    -- Add check constraint
    IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                   WHERE table_schema = 'public' 
                   AND table_name = 'recommendations' 
                   AND constraint_name = 'recommendations_strategy_check') THEN
      ALTER TABLE public.recommendations ADD CONSTRAINT recommendations_strategy_check 
        CHECK (strategy IN ('similar_audio', 'genre_exploration', 'artist_collaborations', 'mood_match', 'flavor_profile', 'discovery'));
    END IF;
  END IF;
  
  -- Add recommended_tracks if missing (required)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = 'recommendations' 
                 AND column_name = 'recommended_tracks') THEN
    ALTER TABLE public.recommendations ADD COLUMN recommended_tracks JSONB;
    UPDATE public.recommendations SET recommended_tracks = '[]'::JSONB WHERE recommended_tracks IS NULL;
    ALTER TABLE public.recommendations ALTER COLUMN recommended_tracks SET NOT NULL;
  END IF;
END $$;

-- Liked tracks table
CREATE TABLE IF NOT EXISTS public.liked_tracks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  track_id TEXT NOT NULL,
  track_name TEXT NOT NULL,
  artist_name TEXT NOT NULL,
  album_art_url TEXT,
  preview_url TEXT,
  spotify_id TEXT,
  liked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT unique_user_liked_track UNIQUE (user_id, spotify_id)
);

-- Ensure unique constraint exists for liked_tracks (for existing tables)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                 WHERE table_schema = 'public' 
                 AND table_name = 'liked_tracks' 
                 AND constraint_name = 'unique_user_liked_track') THEN
    -- Add unique constraint if columns exist
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_schema = 'public' 
               AND table_name = 'liked_tracks' 
               AND column_name = 'user_id')
       AND EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'liked_tracks' 
                   AND column_name = 'spotify_id') THEN
      ALTER TABLE public.liked_tracks ADD CONSTRAINT unique_user_liked_track 
        UNIQUE (user_id, spotify_id);
    END IF;
  END IF;
END $$;

-- Taste profiles table
CREATE TABLE IF NOT EXISTS public.taste_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE UNIQUE,
  top_genres JSONB,
  top_artists JSONB,
  audio_features JSONB,
  total_playlists_analyzed INTEGER DEFAULT 0,
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure unique constraint exists for taste_profiles (for existing tables)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                 WHERE table_schema = 'public' 
                 AND table_name = 'taste_profiles' 
                 AND constraint_name = 'taste_profiles_user_id_key') THEN
    -- Add unique constraint if column exists
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_schema = 'public' 
               AND table_name = 'taste_profiles' 
               AND column_name = 'user_id') THEN
      ALTER TABLE public.taste_profiles ADD CONSTRAINT taste_profiles_user_id_key 
        UNIQUE (user_id);
    END IF;
  END IF;
END $$;

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

-- User stats view
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
-- STEP 2: ENABLE ROW LEVEL SECURITY
-- ============================================================================
-- Note: Tables are created in Step 1, so these ALTER statements are safe
-- IMPORTANT: RLS can ONLY be enabled on TABLES, not on VIEWS
-- Views (history, user_stats) inherit security from underlying tables
-- and don't need RLS enabled - policies can be created directly on views

-- Enable RLS on all tables (only if tables exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
    ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'playlists') THEN
    ALTER TABLE public.playlists ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tracks') THEN
    ALTER TABLE public.tracks ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'analyses') THEN
    ALTER TABLE public.analyses ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'battles') THEN
    ALTER TABLE public.battles ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'recommendations') THEN
    ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'liked_tracks') THEN
    ALTER TABLE public.liked_tracks ENABLE ROW LEVEL SECURITY;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'taste_profiles') THEN
    ALTER TABLE public.taste_profiles ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Users policies (only create if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'Users can view own profile') THEN
      CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'Users can insert own profile') THEN
      CREATE POLICY "Users can insert own profile" ON public.users FOR INSERT WITH CHECK (auth.uid() = id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'Users can update own profile') THEN
      CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'Users can delete own profile') THEN
      CREATE POLICY "Users can delete own profile" ON public.users FOR DELETE USING (auth.uid() = id);
    END IF;
  END IF;
END $$;

-- Playlists policies (only create if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'playlists') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'playlists' AND policyname = 'Users can view own playlists') THEN
      CREATE POLICY "Users can view own playlists" ON public.playlists FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'playlists' AND policyname = 'Users can create own playlists') THEN
      CREATE POLICY "Users can create own playlists" ON public.playlists FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'playlists' AND policyname = 'Users can update own playlists') THEN
      CREATE POLICY "Users can update own playlists" ON public.playlists FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'playlists' AND policyname = 'Users can delete own playlists') THEN
      CREATE POLICY "Users can delete own playlists" ON public.playlists FOR DELETE USING (auth.uid() = user_id);
    END IF;
  END IF;
END $$;

-- Tracks policies (only create if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tracks') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'tracks' AND policyname = 'Users can view tracks from own playlists') THEN
      CREATE POLICY "Users can view tracks from own playlists" ON public.tracks FOR SELECT
        USING (EXISTS (SELECT 1 FROM public.playlists p WHERE p.id = tracks.playlist_id AND p.user_id = auth.uid()));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'tracks' AND policyname = 'Users can insert tracks to own playlists') THEN
      CREATE POLICY "Users can insert tracks to own playlists" ON public.tracks FOR INSERT
        WITH CHECK (EXISTS (SELECT 1 FROM public.playlists p WHERE p.id = tracks.playlist_id AND p.user_id = auth.uid()));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'tracks' AND policyname = 'Users can update tracks in own playlists') THEN
      CREATE POLICY "Users can update tracks in own playlists" ON public.tracks FOR UPDATE
        USING (EXISTS (SELECT 1 FROM public.playlists p WHERE p.id = tracks.playlist_id AND p.user_id = auth.uid()))
        WITH CHECK (EXISTS (SELECT 1 FROM public.playlists p WHERE p.id = tracks.playlist_id AND p.user_id = auth.uid()));
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'tracks' AND policyname = 'Users can delete tracks from own playlists') THEN
      CREATE POLICY "Users can delete tracks from own playlists" ON public.tracks FOR DELETE
        USING (EXISTS (SELECT 1 FROM public.playlists p WHERE p.id = tracks.playlist_id AND p.user_id = auth.uid()));
    END IF;
  END IF;
END $$;

-- Analyses policies (only create if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'analyses') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'analyses' AND policyname = 'Users can view own analyses') THEN
      CREATE POLICY "Users can view own analyses" ON public.analyses FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'analyses' AND policyname = 'Users can create own analyses') THEN
      CREATE POLICY "Users can create own analyses" ON public.analyses FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'analyses' AND policyname = 'Users can update own analyses') THEN
      CREATE POLICY "Users can update own analyses" ON public.analyses FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'analyses' AND policyname = 'Users can delete own analyses') THEN
      CREATE POLICY "Users can delete own analyses" ON public.analyses FOR DELETE USING (auth.uid() = user_id);
    END IF;
  END IF;
END $$;

-- Battles policies (only create if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'battles') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'battles' AND policyname = 'Users can view own battles') THEN
      CREATE POLICY "Users can view own battles" ON public.battles FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'battles' AND policyname = 'Users can create own battles') THEN
      CREATE POLICY "Users can create own battles" ON public.battles FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'battles' AND policyname = 'Users can update own battles') THEN
      CREATE POLICY "Users can update own battles" ON public.battles FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'battles' AND policyname = 'Users can delete own battles') THEN
      CREATE POLICY "Users can delete own battles" ON public.battles FOR DELETE USING (auth.uid() = user_id);
    END IF;
  END IF;
END $$;

-- Recommendations policies (only create if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'recommendations') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'recommendations' AND policyname = 'Users can view own recommendations') THEN
      CREATE POLICY "Users can view own recommendations" ON public.recommendations FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'recommendations' AND policyname = 'Users can create own recommendations') THEN
      CREATE POLICY "Users can create own recommendations" ON public.recommendations FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'recommendations' AND policyname = 'Users can update own recommendations') THEN
      CREATE POLICY "Users can update own recommendations" ON public.recommendations FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'recommendations' AND policyname = 'Users can delete own recommendations') THEN
      CREATE POLICY "Users can delete own recommendations" ON public.recommendations FOR DELETE USING (auth.uid() = user_id);
    END IF;
  END IF;
END $$;

-- Liked tracks policies (only create if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'liked_tracks') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'liked_tracks' AND policyname = 'Users can view own liked tracks') THEN
      CREATE POLICY "Users can view own liked tracks" ON public.liked_tracks FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'liked_tracks' AND policyname = 'Users can create own liked tracks') THEN
      CREATE POLICY "Users can create own liked tracks" ON public.liked_tracks FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'liked_tracks' AND policyname = 'Users can update own liked tracks') THEN
      CREATE POLICY "Users can update own liked tracks" ON public.liked_tracks FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'liked_tracks' AND policyname = 'Users can delete own liked tracks') THEN
      CREATE POLICY "Users can delete own liked tracks" ON public.liked_tracks FOR DELETE USING (auth.uid() = user_id);
    END IF;
  END IF;
END $$;

-- Taste profiles policies (only create if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'taste_profiles') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'taste_profiles' AND policyname = 'Users can view own taste profiles') THEN
      CREATE POLICY "Users can view own taste profiles" ON public.taste_profiles FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'taste_profiles' AND policyname = 'Users can create own taste profiles') THEN
      CREATE POLICY "Users can create own taste profiles" ON public.taste_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'taste_profiles' AND policyname = 'Users can update own taste profiles') THEN
      CREATE POLICY "Users can update own taste profiles" ON public.taste_profiles FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'taste_profiles' AND policyname = 'Users can delete own taste profiles') THEN
      CREATE POLICY "Users can delete own taste profiles" ON public.taste_profiles FOR DELETE USING (auth.uid() = user_id);
    END IF;
  END IF;
END $$;

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

-- Users indexes (only create if columns exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'users' 
             AND column_name = 'username') THEN
    CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username) WHERE username IS NOT NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'users' 
             AND column_name = 'email') THEN
    CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email) WHERE email IS NOT NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'users' 
             AND column_name = 'spotify_id') THEN
    CREATE INDEX IF NOT EXISTS idx_users_spotify_id ON public.users(spotify_id) WHERE spotify_id IS NOT NULL;
  END IF;
END $$;

-- Playlists indexes (only create if columns exist)
DO $$
BEGIN
  CREATE INDEX IF NOT EXISTS idx_playlists_user_id ON public.playlists(user_id);
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'playlists' 
             AND column_name = 'url') THEN
    CREATE INDEX IF NOT EXISTS idx_playlists_url ON public.playlists(url);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'playlists' 
             AND column_name = 'spotify_id') THEN
    CREATE INDEX IF NOT EXISTS idx_playlists_spotify_id ON public.playlists(spotify_id) WHERE spotify_id IS NOT NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'playlists' 
             AND column_name = 'created_at') THEN
    CREATE INDEX IF NOT EXISTS idx_playlists_created_at ON public.playlists(created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_playlists_user_created ON public.playlists(user_id, created_at DESC);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'playlists' 
             AND column_name = 'analyzed_at') THEN
    CREATE INDEX IF NOT EXISTS idx_playlists_analyzed_at ON public.playlists(analyzed_at DESC) WHERE analyzed_at IS NOT NULL;
  END IF;
END $$;

-- Tracks indexes (only create if columns exist)
DO $$
BEGIN
  CREATE INDEX IF NOT EXISTS idx_tracks_playlist_id ON public.tracks(playlist_id);
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'tracks' 
             AND column_name = 'spotify_id') THEN
    CREATE INDEX IF NOT EXISTS idx_tracks_spotify_id ON public.tracks(spotify_id) WHERE spotify_id IS NOT NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'tracks' 
             AND column_name = 'name') THEN
    CREATE INDEX IF NOT EXISTS idx_tracks_name_trgm ON public.tracks USING gin(name gin_trgm_ops);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'tracks' 
             AND column_name = 'artists') THEN
    CREATE INDEX IF NOT EXISTS idx_tracks_artists ON public.tracks USING gin(artists);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'tracks' 
             AND column_name = 'genres') THEN
    CREATE INDEX IF NOT EXISTS idx_tracks_genres ON public.tracks USING gin(genres);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'tracks' 
             AND column_name = 'audio_features') THEN
    CREATE INDEX IF NOT EXISTS idx_tracks_audio_features ON public.tracks USING gin(audio_features);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'tracks' 
             AND column_name = 'popularity') THEN
    CREATE INDEX IF NOT EXISTS idx_tracks_playlist_popularity ON public.tracks(playlist_id, popularity DESC NULLS LAST);
  END IF;
END $$;

-- Analyses indexes (only create if columns exist)
DO $$
BEGIN
  CREATE INDEX IF NOT EXISTS idx_analyses_user_id ON public.analyses(user_id);
  CREATE INDEX IF NOT EXISTS idx_analyses_playlist_id ON public.analyses(playlist_id);
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'analyses' 
             AND column_name = 'created_at') THEN
    CREATE INDEX IF NOT EXISTS idx_analyses_created_at ON public.analyses(created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_analyses_user_created ON public.analyses(user_id, created_at DESC);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'analyses' 
             AND column_name = 'health_score') THEN
    CREATE INDEX IF NOT EXISTS idx_analyses_health_score ON public.analyses(health_score DESC);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'analyses' 
             AND column_name = 'overall_rating') THEN
    CREATE INDEX IF NOT EXISTS idx_analyses_rating ON public.analyses(overall_rating DESC);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'analyses' 
             AND column_name = 'personality_type') THEN
    CREATE INDEX IF NOT EXISTS idx_analyses_personality_type ON public.analyses(personality_type) WHERE personality_type IS NOT NULL;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'analyses' 
             AND column_name = 'genre_distribution') THEN
    CREATE INDEX IF NOT EXISTS idx_analyses_genre_distribution ON public.analyses USING gin(genre_distribution);
  END IF;
END $$;

-- Battles indexes (only create if columns exist)
DO $$
BEGIN
  CREATE INDEX IF NOT EXISTS idx_battles_user_id ON public.battles(user_id);
  CREATE INDEX IF NOT EXISTS idx_battles_playlist1_id ON public.battles(playlist1_id);
  CREATE INDEX IF NOT EXISTS idx_battles_playlist2_id ON public.battles(playlist2_id);
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'battles' 
             AND column_name = 'created_at') THEN
    CREATE INDEX IF NOT EXISTS idx_battles_created_at ON public.battles(created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_battles_user_created ON public.battles(user_id, created_at DESC);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'battles' 
             AND column_name = 'compatibility_score') THEN
    CREATE INDEX IF NOT EXISTS idx_battles_compatibility_score ON public.battles(compatibility_score DESC);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'battles' 
             AND column_name = 'winner') THEN
    CREATE INDEX IF NOT EXISTS idx_battles_winner ON public.battles(winner) WHERE winner IS NOT NULL;
  END IF;
END $$;

-- Recommendations indexes (only create if columns exist)
DO $$
BEGIN
  CREATE INDEX IF NOT EXISTS idx_recommendations_user_id ON public.recommendations(user_id);
  CREATE INDEX IF NOT EXISTS idx_recommendations_playlist_id ON public.recommendations(playlist_id);
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'recommendations' 
             AND column_name = 'strategy') THEN
    CREATE INDEX IF NOT EXISTS idx_recommendations_strategy ON public.recommendations(strategy);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'recommendations' 
             AND column_name = 'created_at') THEN
    CREATE INDEX IF NOT EXISTS idx_recommendations_created_at ON public.recommendations(created_at DESC);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'recommendations' 
             AND column_name = 'strategy')
       AND EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_schema = 'public' 
                   AND table_name = 'recommendations' 
                   AND column_name = 'created_at') THEN
    CREATE INDEX IF NOT EXISTS idx_recommendations_user_strategy_created ON public.recommendations(user_id, strategy, created_at DESC);
  END IF;
END $$;

-- Liked tracks indexes (only create if table and columns exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'liked_tracks') THEN
    CREATE INDEX IF NOT EXISTS idx_liked_tracks_user_id ON public.liked_tracks(user_id);
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_schema = 'public' 
               AND table_name = 'liked_tracks' 
               AND column_name = 'spotify_id') THEN
      CREATE INDEX IF NOT EXISTS idx_liked_tracks_spotify_id ON public.liked_tracks(spotify_id) WHERE spotify_id IS NOT NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_schema = 'public' 
               AND table_name = 'liked_tracks' 
               AND column_name = 'liked_at') THEN
      CREATE INDEX IF NOT EXISTS idx_liked_tracks_liked_at ON public.liked_tracks(liked_at DESC);
      CREATE INDEX IF NOT EXISTS idx_liked_tracks_user_liked ON public.liked_tracks(user_id, liked_at DESC);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_schema = 'public' 
               AND table_name = 'liked_tracks' 
               AND column_name = 'track_name') THEN
      CREATE INDEX IF NOT EXISTS idx_liked_tracks_name_trgm ON public.liked_tracks USING gin(track_name gin_trgm_ops);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_schema = 'public' 
               AND table_name = 'liked_tracks' 
               AND column_name = 'artist_name') THEN
      CREATE INDEX IF NOT EXISTS idx_liked_tracks_artist_trgm ON public.liked_tracks USING gin(artist_name gin_trgm_ops);
    END IF;
  END IF;
END $$;

-- Taste profiles indexes (only create if table and columns exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'taste_profiles') THEN
    CREATE INDEX IF NOT EXISTS idx_taste_profiles_user_id ON public.taste_profiles(user_id);
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_schema = 'public' 
               AND table_name = 'taste_profiles' 
               AND column_name = 'last_updated') THEN
      CREATE INDEX IF NOT EXISTS idx_taste_profiles_last_updated ON public.taste_profiles(last_updated DESC);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_schema = 'public' 
               AND table_name = 'taste_profiles' 
               AND column_name = 'top_genres') THEN
      CREATE INDEX IF NOT EXISTS idx_taste_profiles_top_genres ON public.taste_profiles USING gin(top_genres);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_schema = 'public' 
               AND table_name = 'taste_profiles' 
               AND column_name = 'top_artists') THEN
      CREATE INDEX IF NOT EXISTS idx_taste_profiles_top_artists ON public.taste_profiles USING gin(top_artists);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_schema = 'public' 
               AND table_name = 'taste_profiles' 
               AND column_name = 'audio_features') THEN
      CREATE INDEX IF NOT EXISTS idx_taste_profiles_audio_features ON public.taste_profiles USING gin(audio_features);
    END IF;
  END IF;
END $$;

-- Full text search indexes (only create if columns exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'playlists' 
             AND column_name = 'name') THEN
    CREATE INDEX IF NOT EXISTS idx_playlists_name_search ON public.playlists USING gin(to_tsvector('english', name));
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_schema = 'public' 
             AND table_name = 'tracks' 
             AND column_name = 'name') THEN
    CREATE INDEX IF NOT EXISTS idx_tracks_name_search ON public.tracks USING gin(to_tsvector('english', name));
  END IF;
END $$;

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
  -- Only set spotify_id if url and platform columns exist and platform is spotify
  IF NEW.url IS NOT NULL AND 
     (NEW.platform IS NULL OR NEW.platform = 'spotify') THEN
    NEW.spotify_id = public.extract_spotify_id(NEW.url);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers (only create if tables exist and triggers don't already exist)
DO $$
BEGIN
  -- Users trigger
  IF EXISTS (SELECT 1 FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name = 'users')
     AND NOT EXISTS (SELECT 1 FROM pg_trigger 
                     WHERE tgname = 'set_updated_at_users' 
                     AND tgrelid = 'public.users'::regclass) THEN
    CREATE TRIGGER set_updated_at_users BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
  END IF;
  
  -- Playlists trigger
  IF EXISTS (SELECT 1 FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name = 'playlists')
     AND NOT EXISTS (SELECT 1 FROM pg_trigger 
                     WHERE tgname = 'set_updated_at_playlists' 
                     AND tgrelid = 'public.playlists'::regclass) THEN
    CREATE TRIGGER set_updated_at_playlists BEFORE UPDATE ON public.playlists FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
  END IF;
  
  -- Auth user trigger (auth schema always exists)
  IF NOT EXISTS (SELECT 1 FROM pg_trigger 
                 WHERE tgname = 'on_auth_user_created' 
                 AND tgrelid = 'auth.users'::regclass) THEN
    CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
  END IF;
  
  -- Tracks triggers
  IF EXISTS (SELECT 1 FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name = 'tracks') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger 
                   WHERE tgname = 'update_track_count_on_insert' 
                   AND tgrelid = 'public.tracks'::regclass) THEN
      CREATE TRIGGER update_track_count_on_insert AFTER INSERT ON public.tracks FOR EACH ROW EXECUTE FUNCTION public.update_playlist_track_count();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger 
                   WHERE tgname = 'update_track_count_on_delete' 
                   AND tgrelid = 'public.tracks'::regclass) THEN
      CREATE TRIGGER update_track_count_on_delete AFTER DELETE ON public.tracks FOR EACH ROW EXECUTE FUNCTION public.update_playlist_track_count();
    END IF;
  END IF;
  
  -- Playlists Spotify ID extraction triggers
  IF EXISTS (SELECT 1 FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name = 'playlists') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger 
                   WHERE tgname = 'extract_spotify_id_on_insert' 
                   AND tgrelid = 'public.playlists'::regclass) THEN
      CREATE TRIGGER extract_spotify_id_on_insert BEFORE INSERT ON public.playlists FOR EACH ROW EXECUTE FUNCTION public.set_playlist_spotify_id();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger 
                   WHERE tgname = 'extract_spotify_id_on_update' 
                   AND tgrelid = 'public.playlists'::regclass) THEN
      CREATE TRIGGER extract_spotify_id_on_update BEFORE UPDATE ON public.playlists FOR EACH ROW WHEN (OLD.url IS DISTINCT FROM NEW.url OR OLD.platform IS DISTINCT FROM NEW.platform) EXECUTE FUNCTION public.set_playlist_spotify_id();
    END IF;
  END IF;
END $$;

-- Triggers for new tables (only create if tables exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name = 'liked_tracks')
     AND NOT EXISTS (SELECT 1 FROM pg_trigger 
                     WHERE tgname = 'set_updated_at_liked_tracks' 
                     AND tgrelid = 'public.liked_tracks'::regclass) THEN
    CREATE TRIGGER set_updated_at_liked_tracks BEFORE UPDATE ON public.liked_tracks FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables 
             WHERE table_schema = 'public' 
             AND table_name = 'taste_profiles')
     AND NOT EXISTS (SELECT 1 FROM pg_trigger 
                     WHERE tgname = 'set_updated_at_taste_profiles' 
                     AND tgrelid = 'public.taste_profiles'::regclass) THEN
    CREATE TRIGGER set_updated_at_taste_profiles BEFORE UPDATE ON public.taste_profiles FOR EACH ROW EXECUTE FUNCTION public.handle_taste_profile_updated_at();
  END IF;
END $$;

-- Function for taste profile updated_at (create if it doesn't exist)
CREATE OR REPLACE FUNCTION public.handle_taste_profile_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_updated = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- SETUP COMPLETE!
-- ============================================================================
-- Your database is now ready to use.
-- Verify by running: SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
-- ============================================================================

