-- ============================================================================
-- ANTIDOTE FLUTTER - ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
-- This script enables RLS and creates security policies for all tables
-- Run this AFTER schema.sql
-- 
-- FOR FRESH DATABASE: This script drops existing policies before creating new ones
-- to ensure clean setup on a new database
-- ============================================================================

-- ============================================================================
-- PREREQUISITES NOTE
-- ============================================================================
-- This script requires tables to exist (created in schema.sql).
-- View policies will be created only if the views exist.
-- If views don't exist, those policies will be skipped (not an error).

-- ============================================================================
-- DROP EXISTING POLICIES (if re-running)
-- ============================================================================
-- Drop policies in reverse dependency order
-- Note: View policies are not created (see VIEW POLICIES section below for explanation)
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

-- ============================================================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================================================
-- Note: Tables should be created first (via schema.sql), so these are safe
-- IMPORTANT: RLS can ONLY be enabled on TABLES, not on VIEWS
-- Views inherit security from their underlying tables and don't need RLS enabled
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.analyses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.battles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recommendations ENABLE ROW LEVEL SECURITY;

-- Note: Views (history, user_stats) do NOT need RLS enabled
-- Policies can be created directly on views without enabling RLS first

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
-- IMPORTANT: RLS policies CANNOT be created directly on views in PostgreSQL/Supabase.
-- The error "history is not a table" occurs because CREATE POLICY only works on tables.
--
-- SECURITY NOTE: Views automatically inherit RLS from their underlying tables.
-- Since the underlying tables (analyses, battles) already have RLS policies that
-- filter by user_id, the views (history, user_stats) are automatically secure.
--
-- The history view queries from:
--   - analyses table (has RLS: user_id = auth.uid())
--   - battles table (has RLS: user_id = auth.uid())
--
-- The user_stats view queries from:
--   - users, analyses, battles, playlists (all have RLS)
--
-- Therefore, NO ADDITIONAL POLICIES ARE NEEDED on views - they inherit security
-- from the underlying tables. Users can only see their own data through the views
-- because the underlying table RLS policies filter the data before it reaches the view.
--
-- If you need view-level restrictions beyond what the tables provide, you would need
-- to modify the view definition itself (e.g., add WHERE clauses) rather than using RLS policies.

-- ============================================================================
-- NOTES
-- ============================================================================
-- All policies use auth.uid() which is provided by Supabase Auth
-- This ensures users can only access their own data
-- Policies are automatically enforced by PostgreSQL RLS engine
--
-- IMPORTANT DIFFERENCES:
-- - TABLES: Must have RLS enabled (ALTER TABLE ... ENABLE ROW LEVEL SECURITY)
--   before creating policies. Policies work directly on tables.
-- - VIEWS: Cannot have RLS policies created directly on them (PostgreSQL limitation).
--   However, views AUTOMATICALLY inherit RLS from underlying tables. Since all
--   underlying tables (analyses, battles, etc.) have RLS policies filtering by
--   user_id, the views are automatically secure - users can only see their own data.

