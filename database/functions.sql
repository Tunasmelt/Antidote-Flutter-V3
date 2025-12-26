-- ============================================================================
-- ANTIDOTE FLUTTER - DATABASE FUNCTIONS AND TRIGGERS
-- ============================================================================
-- This script creates helper functions and automatic triggers
-- Run this AFTER schema.sql
-- ============================================================================

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
  average_rating NUMERIC,
  average_health_score NUMERIC,
  last_analysis_at TIMESTAMP WITH TIME ZONE,
  last_battle_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(DISTINCT a.id)::BIGINT as analyses_count,
    COUNT(DISTINCT b.id)::BIGINT as battles_count,
    COUNT(DISTINCT p.id)::BIGINT as saved_playlists_count,
    COALESCE(AVG(a.overall_rating), 0)::NUMERIC as average_rating,
    COALESCE(AVG(a.health_score), 0)::NUMERIC as average_health_score,
    MAX(a.created_at) as last_analysis_at,
    MAX(b.created_at) as last_battle_at
  FROM public.users u
  LEFT JOIN public.analyses a ON u.id = a.user_id
  LEFT JOIN public.battles b ON u.id = b.user_id
  LEFT JOIN public.playlists p ON u.id = p.user_id
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
CREATE OR REPLACE FUNCTION public.extract_spotify_id(url TEXT)
RETURNS TEXT AS $$
DECLARE
  spotify_id TEXT;
BEGIN
  -- Extract Spotify playlist/track ID from URL
  -- Pattern: https://open.spotify.com/playlist/37i9dQZF1DX0XUsuxWHRQd
  SELECT (regexp_match(url, '/(?:playlist|track|album)/([a-zA-Z0-9]+)'))[1] INTO spotify_id;
  RETURN spotify_id;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger to automatically update updated_at on users table
CREATE TRIGGER set_updated_at_users
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Trigger to automatically update updated_at on playlists table
CREATE TRIGGER set_updated_at_playlists
  BEFORE UPDATE ON public.playlists
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- Trigger to automatically create user profile when auth user is created
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Trigger to update playlist track count when tracks are added
CREATE TRIGGER update_track_count_on_insert
  AFTER INSERT ON public.tracks
  FOR EACH ROW
  EXECUTE FUNCTION public.update_playlist_track_count();

-- Trigger to update playlist track count when tracks are deleted
CREATE TRIGGER update_track_count_on_delete
  AFTER DELETE ON public.tracks
  FOR EACH ROW
  EXECUTE FUNCTION public.update_playlist_track_count();

-- ============================================================================
-- AUTOMATIC SPOTIFY ID EXTRACTION
-- ============================================================================

-- Trigger to automatically extract and set spotify_id when playlist URL is inserted/updated
CREATE OR REPLACE FUNCTION public.set_playlist_spotify_id()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.url IS NOT NULL AND NEW.platform = 'spotify' THEN
    NEW.spotify_id = public.extract_spotify_id(NEW.url);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER extract_spotify_id_on_insert
  BEFORE INSERT ON public.playlists
  FOR EACH ROW
  EXECUTE FUNCTION public.set_playlist_spotify_id();

CREATE TRIGGER extract_spotify_id_on_update
  BEFORE UPDATE ON public.playlists
  FOR EACH ROW
  WHEN (OLD.url IS DISTINCT FROM NEW.url OR OLD.platform IS DISTINCT FROM NEW.platform)
  EXECUTE FUNCTION public.set_playlist_spotify_id();

-- ============================================================================
-- NOTES
-- ============================================================================
-- Functions marked with SECURITY DEFINER run with the privileges of the function creator
-- This is necessary for functions that need to bypass RLS (like handle_new_user)
-- Triggers automatically fire on INSERT/UPDATE/DELETE operations
-- The track count trigger ensures data consistency

