-- ============================================================================
-- ANTIDOTE FLUTTER - ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
-- This script enables RLS and creates security policies for all tables
-- Run this AFTER schema.sql
-- ============================================================================

-- ============================================================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.battles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- USERS TABLE POLICIES
-- ============================================================================

-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

-- Users can insert their own profile (on signup)
CREATE POLICY "Users can insert own profile"
  ON public.users FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Users can delete their own profile
CREATE POLICY "Users can delete own profile"
  ON public.users FOR DELETE
  USING (auth.uid() = id);

-- ============================================================================
-- PLAYLISTS TABLE POLICIES
-- ============================================================================

-- Users can view their own playlists
CREATE POLICY "Users can view own playlists"
  ON public.playlists FOR SELECT
  USING (auth.uid() = user_id);

-- Users can create their own playlists
CREATE POLICY "Users can create own playlists"
  ON public.playlists FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own playlists
CREATE POLICY "Users can update own playlists"
  ON public.playlists FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own playlists
CREATE POLICY "Users can delete own playlists"
  ON public.playlists FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- TRACKS TABLE POLICIES
-- ============================================================================

-- Users can view tracks from their own playlists
CREATE POLICY "Users can view tracks from own playlists"
  ON public.tracks FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.playlists p
      WHERE p.id = tracks.playlist_id
      AND p.user_id = auth.uid()
    )
  );

-- Users can insert tracks to their own playlists
CREATE POLICY "Users can insert tracks to own playlists"
  ON public.tracks FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.playlists p
      WHERE p.id = tracks.playlist_id
      AND p.user_id = auth.uid()
    )
  );

-- Users can update tracks in their own playlists
CREATE POLICY "Users can update tracks in own playlists"
  ON public.tracks FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.playlists p
      WHERE p.id = tracks.playlist_id
      AND p.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.playlists p
      WHERE p.id = tracks.playlist_id
      AND p.user_id = auth.uid()
    )
  );

-- Users can delete tracks from their own playlists
CREATE POLICY "Users can delete tracks from own playlists"
  ON public.tracks FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.playlists p
      WHERE p.id = tracks.playlist_id
      AND p.user_id = auth.uid()
    )
  );

-- ============================================================================
-- ANALYSES TABLE POLICIES
-- ============================================================================

-- Users can view their own analyses
CREATE POLICY "Users can view own analyses"
  ON public.analyses FOR SELECT
  USING (auth.uid() = user_id);

-- Users can create their own analyses
CREATE POLICY "Users can create own analyses"
  ON public.analyses FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own analyses
CREATE POLICY "Users can update own analyses"
  ON public.analyses FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own analyses
CREATE POLICY "Users can delete own analyses"
  ON public.analyses FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- BATTLES TABLE POLICIES
-- ============================================================================

-- Users can view their own battles
CREATE POLICY "Users can view own battles"
  ON public.battles FOR SELECT
  USING (auth.uid() = user_id);

-- Users can create their own battles
CREATE POLICY "Users can create own battles"
  ON public.battles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own battles
CREATE POLICY "Users can update own battles"
  ON public.battles FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own battles
CREATE POLICY "Users can delete own battles"
  ON public.battles FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- RECOMMENDATIONS TABLE POLICIES
-- ============================================================================

-- Users can view their own recommendations
CREATE POLICY "Users can view own recommendations"
  ON public.recommendations FOR SELECT
  USING (auth.uid() = user_id);

-- Users can create their own recommendations
CREATE POLICY "Users can create own recommendations"
  ON public.recommendations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own recommendations
CREATE POLICY "Users can update own recommendations"
  ON public.recommendations FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own recommendations
CREATE POLICY "Users can delete own recommendations"
  ON public.recommendations FOR DELETE
  USING (auth.uid() = user_id);

-- ============================================================================
-- VIEW POLICIES
-- ============================================================================

-- History view: Users can only see their own history
CREATE POLICY "Users can view own history"
  ON public.history FOR SELECT
  USING (auth.uid() = user_id);

-- User stats view: Users can only see their own stats
CREATE POLICY "Users can view own stats"
  ON public.user_stats FOR SELECT
  USING (auth.uid() = user_id);

-- ============================================================================
-- NOTES
-- ============================================================================
-- All policies use auth.uid() which is provided by Supabase Auth
-- This ensures users can only access their own data
-- Policies are automatically enforced by PostgreSQL RLS engine

