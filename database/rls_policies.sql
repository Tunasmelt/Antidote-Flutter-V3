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
-- Drop policies for all tables (only if tables exist)
DO $$
BEGIN
  -- Taste profiles
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'taste_profiles') THEN
    DROP POLICY IF EXISTS "Users can delete own taste profiles" ON public.taste_profiles;
    DROP POLICY IF EXISTS "Users can update own taste profiles" ON public.taste_profiles;
    DROP POLICY IF EXISTS "Users can create own taste profiles" ON public.taste_profiles;
    DROP POLICY IF EXISTS "Users can view own taste profiles" ON public.taste_profiles;
  END IF;
  -- Liked tracks
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'liked_tracks') THEN
    DROP POLICY IF EXISTS "Users can delete own liked tracks" ON public.liked_tracks;
    DROP POLICY IF EXISTS "Users can update own liked tracks" ON public.liked_tracks;
    DROP POLICY IF EXISTS "Users can create own liked tracks" ON public.liked_tracks;
    DROP POLICY IF EXISTS "Users can view own liked tracks" ON public.liked_tracks;
  END IF;
  -- Recommendations
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'recommendations') THEN
    DROP POLICY IF EXISTS "Users can delete own recommendations" ON public.recommendations;
    DROP POLICY IF EXISTS "Users can update own recommendations" ON public.recommendations;
    DROP POLICY IF EXISTS "Users can create own recommendations" ON public.recommendations;
    DROP POLICY IF EXISTS "Users can view own recommendations" ON public.recommendations;
  END IF;
  -- Battles
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'battles') THEN
    DROP POLICY IF EXISTS "Users can delete own battles" ON public.battles;
    DROP POLICY IF EXISTS "Users can update own battles" ON public.battles;
    DROP POLICY IF EXISTS "Users can create own battles" ON public.battles;
    DROP POLICY IF EXISTS "Users can view own battles" ON public.battles;
  END IF;
  -- Analyses
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'analyses') THEN
    DROP POLICY IF EXISTS "Users can delete own analyses" ON public.analyses;
    DROP POLICY IF EXISTS "Users can update own analyses" ON public.analyses;
    DROP POLICY IF EXISTS "Users can create own analyses" ON public.analyses;
    DROP POLICY IF EXISTS "Users can view own analyses" ON public.analyses;
  END IF;
  -- Tracks
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tracks') THEN
    DROP POLICY IF EXISTS "Users can delete tracks from own playlists" ON public.tracks;
    DROP POLICY IF EXISTS "Users can update tracks in own playlists" ON public.tracks;
    DROP POLICY IF EXISTS "Users can insert tracks to own playlists" ON public.tracks;
    DROP POLICY IF EXISTS "Users can view tracks from own playlists" ON public.tracks;
  END IF;
  -- Playlists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'playlists') THEN
    DROP POLICY IF EXISTS "Users can delete own playlists" ON public.playlists;
    DROP POLICY IF EXISTS "Users can update own playlists" ON public.playlists;
    DROP POLICY IF EXISTS "Users can create own playlists" ON public.playlists;
    DROP POLICY IF EXISTS "Users can view own playlists" ON public.playlists;
  END IF;
  -- Users
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
    DROP POLICY IF EXISTS "Users can delete own profile" ON public.users;
    DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
    DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
    DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
  END IF;
END $$;

-- ============================================================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================================================
-- Note: Tables should be created first (via schema.sql), so these are safe
-- IMPORTANT: RLS can ONLY be enabled on TABLES, not on VIEWS
-- Views inherit security from their underlying tables and don't need RLS enabled
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

-- Note: Views (history, user_stats) do NOT need RLS enabled
-- Policies can be created directly on views without enabling RLS first

-- ============================================================================
-- USERS TABLE POLICIES
-- ============================================================================

-- Users policies (only create if table exists and policies don't exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'Users can view own profile') THEN
      CREATE POLICY "Users can view own profile"
        ON public.users FOR SELECT
        USING (auth.uid() = id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'Users can insert own profile') THEN
      CREATE POLICY "Users can insert own profile"
        ON public.users FOR INSERT
        WITH CHECK (auth.uid() = id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'Users can update own profile') THEN
      CREATE POLICY "Users can update own profile"
        ON public.users FOR UPDATE
        USING (auth.uid() = id)
        WITH CHECK (auth.uid() = id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users' AND policyname = 'Users can delete own profile') THEN
      CREATE POLICY "Users can delete own profile"
        ON public.users FOR DELETE
        USING (auth.uid() = id);
    END IF;
  END IF;
END $$;

-- ============================================================================
-- PLAYLISTS TABLE POLICIES
-- ============================================================================

-- Playlists policies (only create if table exists and policies don't exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'playlists') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'playlists' AND policyname = 'Users can view own playlists') THEN
      CREATE POLICY "Users can view own playlists"
        ON public.playlists FOR SELECT
        USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'playlists' AND policyname = 'Users can create own playlists') THEN
      CREATE POLICY "Users can create own playlists"
        ON public.playlists FOR INSERT
        WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'playlists' AND policyname = 'Users can update own playlists') THEN
      CREATE POLICY "Users can update own playlists"
        ON public.playlists FOR UPDATE
        USING (auth.uid() = user_id)
        WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'playlists' AND policyname = 'Users can delete own playlists') THEN
      CREATE POLICY "Users can delete own playlists"
        ON public.playlists FOR DELETE
        USING (auth.uid() = user_id);
    END IF;
  END IF;
END $$;

-- ============================================================================
-- TRACKS TABLE POLICIES
-- ============================================================================

-- Tracks policies (only create if table exists and policies don't exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tracks') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'tracks' AND policyname = 'Users can view tracks from own playlists') THEN
      CREATE POLICY "Users can view tracks from own playlists"
        ON public.tracks FOR SELECT
        USING (
          EXISTS (
            SELECT 1 FROM public.playlists p
            WHERE p.id = tracks.playlist_id
            AND p.user_id = auth.uid()
          )
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'tracks' AND policyname = 'Users can insert tracks to own playlists') THEN
      CREATE POLICY "Users can insert tracks to own playlists"
        ON public.tracks FOR INSERT
        WITH CHECK (
          EXISTS (
            SELECT 1 FROM public.playlists p
            WHERE p.id = tracks.playlist_id
            AND p.user_id = auth.uid()
          )
        );
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'tracks' AND policyname = 'Users can update tracks in own playlists') THEN
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
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'tracks' AND policyname = 'Users can delete tracks from own playlists') THEN
      CREATE POLICY "Users can delete tracks from own playlists"
        ON public.tracks FOR DELETE
        USING (
          EXISTS (
            SELECT 1 FROM public.playlists p
            WHERE p.id = tracks.playlist_id
            AND p.user_id = auth.uid()
          )
        );
    END IF;
  END IF;
END $$;

-- ============================================================================
-- ANALYSES TABLE POLICIES
-- ============================================================================

-- Analyses policies (only create if table exists and policies don't exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'analyses') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'analyses' AND policyname = 'Users can view own analyses') THEN
      CREATE POLICY "Users can view own analyses"
        ON public.analyses FOR SELECT
        USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'analyses' AND policyname = 'Users can create own analyses') THEN
      CREATE POLICY "Users can create own analyses"
        ON public.analyses FOR INSERT
        WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'analyses' AND policyname = 'Users can update own analyses') THEN
      CREATE POLICY "Users can update own analyses"
        ON public.analyses FOR UPDATE
        USING (auth.uid() = user_id)
        WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'analyses' AND policyname = 'Users can delete own analyses') THEN
      CREATE POLICY "Users can delete own analyses"
        ON public.analyses FOR DELETE
        USING (auth.uid() = user_id);
    END IF;
  END IF;
END $$;

-- ============================================================================
-- BATTLES TABLE POLICIES
-- ============================================================================

-- Battles policies (only create if table exists and policies don't exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'battles') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'battles' AND policyname = 'Users can view own battles') THEN
      CREATE POLICY "Users can view own battles"
        ON public.battles FOR SELECT
        USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'battles' AND policyname = 'Users can create own battles') THEN
      CREATE POLICY "Users can create own battles"
        ON public.battles FOR INSERT
        WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'battles' AND policyname = 'Users can update own battles') THEN
      CREATE POLICY "Users can update own battles"
        ON public.battles FOR UPDATE
        USING (auth.uid() = user_id)
        WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'battles' AND policyname = 'Users can delete own battles') THEN
      CREATE POLICY "Users can delete own battles"
        ON public.battles FOR DELETE
        USING (auth.uid() = user_id);
    END IF;
  END IF;
END $$;

-- ============================================================================
-- RECOMMENDATIONS TABLE POLICIES
-- ============================================================================

-- Recommendations policies (only create if table exists and policies don't exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'recommendations') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'recommendations' AND policyname = 'Users can view own recommendations') THEN
      CREATE POLICY "Users can view own recommendations"
        ON public.recommendations FOR SELECT
        USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'recommendations' AND policyname = 'Users can create own recommendations') THEN
      CREATE POLICY "Users can create own recommendations"
        ON public.recommendations FOR INSERT
        WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'recommendations' AND policyname = 'Users can update own recommendations') THEN
      CREATE POLICY "Users can update own recommendations"
        ON public.recommendations FOR UPDATE
        USING (auth.uid() = user_id)
        WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'recommendations' AND policyname = 'Users can delete own recommendations') THEN
      CREATE POLICY "Users can delete own recommendations"
        ON public.recommendations FOR DELETE
        USING (auth.uid() = user_id);
    END IF;
  END IF;
END $$;

-- ============================================================================
-- LIKED TRACKS TABLE POLICIES
-- ============================================================================

-- Liked tracks policies (only create if table exists and policies don't exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'liked_tracks') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'liked_tracks' AND policyname = 'Users can view own liked tracks') THEN
      CREATE POLICY "Users can view own liked tracks"
        ON public.liked_tracks FOR SELECT
        USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'liked_tracks' AND policyname = 'Users can create own liked tracks') THEN
      CREATE POLICY "Users can create own liked tracks"
        ON public.liked_tracks FOR INSERT
        WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'liked_tracks' AND policyname = 'Users can update own liked tracks') THEN
      CREATE POLICY "Users can update own liked tracks"
        ON public.liked_tracks FOR UPDATE
        USING (auth.uid() = user_id)
        WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'liked_tracks' AND policyname = 'Users can delete own liked tracks') THEN
      CREATE POLICY "Users can delete own liked tracks"
        ON public.liked_tracks FOR DELETE
        USING (auth.uid() = user_id);
    END IF;
  END IF;
END $$;

-- ============================================================================
-- TASTE PROFILES TABLE POLICIES
-- ============================================================================

-- Taste profiles policies (only create if table exists and policies don't exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'taste_profiles') THEN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'taste_profiles' AND policyname = 'Users can view own taste profiles') THEN
      CREATE POLICY "Users can view own taste profiles"
        ON public.taste_profiles FOR SELECT
        USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'taste_profiles' AND policyname = 'Users can create own taste profiles') THEN
      CREATE POLICY "Users can create own taste profiles"
        ON public.taste_profiles FOR INSERT
        WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'taste_profiles' AND policyname = 'Users can update own taste profiles') THEN
      CREATE POLICY "Users can update own taste profiles"
        ON public.taste_profiles FOR UPDATE
        USING (auth.uid() = user_id)
        WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public' AND tablename = 'taste_profiles' AND policyname = 'Users can delete own taste profiles') THEN
      CREATE POLICY "Users can delete own taste profiles"
        ON public.taste_profiles FOR DELETE
        USING (auth.uid() = user_id);
    END IF;
  END IF;
END $$;

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

