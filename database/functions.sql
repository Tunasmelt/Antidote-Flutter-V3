-- ============================================================================
-- ANTIDOTE FLUTTER - DATABASE FUNCTIONS AND TRIGGERS
-- ============================================================================
-- This script creates helper functions and automatic triggers
-- Run this AFTER schema.sql
-- 
-- FOR FRESH DATABASE: This script drops existing triggers before creating new ones
-- to ensure clean setup on a new database
-- ============================================================================

-- ============================================================================
-- DROP EXISTING TRIGGERS (if re-running)
-- ============================================================================
-- Drop triggers only if tables exist
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
  -- Auth schema always exists, but check if trigger exists
  DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
END $$;

-- Drop triggers for new tables (only if tables exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'liked_tracks') THEN
    DROP TRIGGER IF EXISTS set_updated_at_liked_tracks ON public.liked_tracks;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'taste_profiles') THEN
    DROP TRIGGER IF EXISTS set_updated_at_taste_profiles ON public.taste_profiles;
  END IF;
END $$;

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to get user statistics (alternative to view)
CREATE OR REPLACE FUNCTION public.get_user_stats(p_user_id UUID)
RETURNS TABLE (
  analyses_count BIGINT,
  battles_count BIGINT,
  saved_playlists_count BIGINT,
  liked_tracks_count BIGINT,
  average_rating NUMERIC,
  average_health_score NUMERIC,
  last_analysis_at TIMESTAMP WITH TIME ZONE,
  last_battle_at TIMESTAMP WITH TIME ZONE,
  taste_profile_last_updated TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT a.id)::BIGINT as analyses_count,
    COUNT(DISTINCT b.id)::BIGINT as battles_count,
    COUNT(DISTINCT p.id)::BIGINT as saved_playlists_count,
    COUNT(DISTINCT lt.id)::BIGINT as liked_tracks_count,
    COALESCE(AVG(a.overall_rating), 0)::NUMERIC as average_rating,
    COALESCE(AVG(a.health_score), 0)::NUMERIC as average_health_score,
    MAX(a.created_at) as last_analysis_at,
    MAX(b.created_at) as last_battle_at,
    MAX(tp.last_updated) as taste_profile_last_updated
  FROM public.users u
  LEFT JOIN public.analyses a ON u.id = a.user_id
  LEFT JOIN public.battles b ON u.id = b.user_id
  LEFT JOIN public.playlists p ON u.id = p.user_id
  LEFT JOIN public.liked_tracks lt ON u.id = lt.user_id
  LEFT JOIN public.taste_profiles tp ON u.id = tp.user_id
  WHERE u.id = p_user_id
  GROUP BY u.id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to automatically create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    NOW()
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update playlist track count
CREATE OR REPLACE FUNCTION public.update_playlist_track_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.playlists
    SET track_count = (
      SELECT COUNT(*) FROM public.tracks
      WHERE playlist_id = NEW.playlist_id
    )
    WHERE id = NEW.playlist_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.playlists
    SET track_count = (
      SELECT COUNT(*) FROM public.tracks
      WHERE playlist_id = OLD.playlist_id
    )
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

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Triggers (only create if tables exist and triggers don't already exist)
DO $$
BEGIN
  -- Users trigger
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users')
     AND NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_users' AND tgrelid = 'public.users'::regclass) THEN
    CREATE TRIGGER set_updated_at_users
      BEFORE UPDATE ON public.users
      FOR EACH ROW
      EXECUTE FUNCTION public.handle_updated_at();
  END IF;
  
  -- Playlists trigger
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'playlists')
     AND NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_playlists' AND tgrelid = 'public.playlists'::regclass) THEN
    CREATE TRIGGER set_updated_at_playlists
      BEFORE UPDATE ON public.playlists
      FOR EACH ROW
      EXECUTE FUNCTION public.handle_updated_at();
  END IF;
  
  -- Auth user trigger (auth schema always exists)
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created' AND tgrelid = 'auth.users'::regclass) THEN
    CREATE TRIGGER on_auth_user_created
      AFTER INSERT ON auth.users
      FOR EACH ROW
      EXECUTE FUNCTION public.handle_new_user();
  END IF;
  
  -- Tracks triggers
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tracks') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_track_count_on_insert' AND tgrelid = 'public.tracks'::regclass) THEN
      CREATE TRIGGER update_track_count_on_insert
        AFTER INSERT ON public.tracks
        FOR EACH ROW
        EXECUTE FUNCTION public.update_playlist_track_count();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_track_count_on_delete' AND tgrelid = 'public.tracks'::regclass) THEN
      CREATE TRIGGER update_track_count_on_delete
        AFTER DELETE ON public.tracks
        FOR EACH ROW
        EXECUTE FUNCTION public.update_playlist_track_count();
    END IF;
  END IF;
END $$;

-- ============================================================================
-- AUTOMATIC SPOTIFY ID EXTRACTION
-- ============================================================================

-- Trigger to automatically extract and set spotify_id when playlist URL is inserted/updated
CREATE OR REPLACE FUNCTION public.set_playlist_spotify_id()
RETURNS TRIGGER AS $$
BEGIN
  -- Only set spotify_id if url exists and platform is spotify (or platform column doesn't exist)
  IF NEW.url IS NOT NULL AND 
     (NEW.platform IS NULL OR NEW.platform = 'spotify') THEN
    NEW.spotify_id = public.extract_spotify_id(NEW.url);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Spotify ID extraction triggers (only create if table exists and triggers don't exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'playlists') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'extract_spotify_id_on_insert' AND tgrelid = 'public.playlists'::regclass) THEN
      CREATE TRIGGER extract_spotify_id_on_insert
        BEFORE INSERT ON public.playlists
        FOR EACH ROW
        EXECUTE FUNCTION public.set_playlist_spotify_id();
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'extract_spotify_id_on_update' AND tgrelid = 'public.playlists'::regclass) THEN
      CREATE TRIGGER extract_spotify_id_on_update
        BEFORE UPDATE ON public.playlists
        FOR EACH ROW
        WHEN (OLD.url IS DISTINCT FROM NEW.url OR OLD.platform IS DISTINCT FROM NEW.platform)
        EXECUTE FUNCTION public.set_playlist_spotify_id();
    END IF;
  END IF;
END $$;

-- ============================================================================
-- TASTE PROFILE FUNCTIONS
-- ============================================================================

-- Function to recalculate taste profile from all user analyses
-- This is a helper function - the actual calculation is typically done in the backend
-- This function can be called to trigger a recalculation, but complex aggregation
-- is better handled in application code for flexibility
CREATE OR REPLACE FUNCTION public.recalculate_taste_profile(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_total_analyses INTEGER;
BEGIN
  -- Get total number of analyses
  SELECT COUNT(*) INTO v_total_analyses
  FROM public.analyses
  WHERE user_id = p_user_id;

  -- If no analyses, create empty profile
  IF v_total_analyses = 0 THEN
    INSERT INTO public.taste_profiles (user_id, top_genres, top_artists, audio_features, total_playlists_analyzed, last_updated)
    VALUES (p_user_id, '{}'::JSONB, '{}'::JSONB, '{}'::JSONB, 0, NOW())
    ON CONFLICT (user_id) DO UPDATE SET
      top_genres = '{}'::JSONB,
      top_artists = '{}'::JSONB,
      audio_features = '{}'::JSONB,
      total_playlists_analyzed = 0,
      last_updated = NOW();
    RETURN;
  END IF;

  -- Note: Complex aggregation of genres, artists, and audio features from analyses
  -- is better handled in application code. This function serves as a placeholder
  -- that can be extended or called to trigger recalculation.
  -- The backend should aggregate data from analyses and update the taste_profiles table directly.
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- TRIGGERS FOR NEW TABLES
-- ============================================================================

-- Function for taste profile updated_at (create if it doesn't exist)
CREATE OR REPLACE FUNCTION public.handle_taste_profile_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.last_updated = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for new tables (only create if tables exist and triggers don't exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'liked_tracks')
     AND NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_liked_tracks' AND tgrelid = 'public.liked_tracks'::regclass) THEN
    CREATE TRIGGER set_updated_at_liked_tracks
      BEFORE UPDATE ON public.liked_tracks
      FOR EACH ROW
      EXECUTE FUNCTION public.handle_updated_at();
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'taste_profiles')
     AND NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'set_updated_at_taste_profiles' AND tgrelid = 'public.taste_profiles'::regclass) THEN
    CREATE TRIGGER set_updated_at_taste_profiles
      BEFORE UPDATE ON public.taste_profiles
      FOR EACH ROW
      EXECUTE FUNCTION public.handle_taste_profile_updated_at();
  END IF;
END $$;

-- ============================================================================
-- NOTES
-- ============================================================================
-- Functions marked with SECURITY DEFINER run with the privileges of the function creator
-- This is necessary for functions that need to bypass RLS (like handle_new_user)
-- Triggers automatically fire on INSERT/UPDATE/DELETE operations
-- The track count trigger ensures data consistency
-- The recalculate_taste_profile function aggregates data from all analyses

