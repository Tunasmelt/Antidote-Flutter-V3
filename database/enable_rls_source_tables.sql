-- ============================================================================
-- ENABLE RLS ON SUPABASE INTERNAL SOURCE TABLES
-- ============================================================================
-- These tables (_history_source, _user_stats_source) are created automatically
-- by Supabase for internal view management. If they contain user data, they
-- should have RLS enabled for security.
-- ============================================================================

-- Enable RLS on _history_source if it exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = '_history_source'
  ) THEN
    ALTER TABLE public._history_source ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE 'RLS enabled on _history_source';
  ELSE
    RAISE NOTICE '_history_source table does not exist - skipping';
  END IF;
END $$;

-- Enable RLS on _user_stats_source if it exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = '_user_stats_source'
  ) THEN
    ALTER TABLE public._user_stats_source ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE 'RLS enabled on _user_stats_source';
  ELSE
    RAISE NOTICE '_user_stats_source table does not exist - skipping';
  END IF;
END $$;

-- ============================================================================
-- CREATE RLS POLICIES FOR SOURCE TABLES
-- ============================================================================
-- These policies ensure users can only access their own data from source tables
-- The policies match the underlying table structure (user_id filtering)

-- Policy for _history_source (if it has user_id column)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = '_history_source'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = '_history_source' 
    AND column_name = 'user_id'
  ) THEN
    -- Drop existing policy if it exists
    DROP POLICY IF EXISTS "Users can view own history source" ON public._history_source;
    
    -- Create policy
    CREATE POLICY "Users can view own history source"
      ON public._history_source FOR SELECT
      USING (auth.uid() = user_id);
    
    RAISE NOTICE 'Policy created for _history_source';
  ELSE
    RAISE NOTICE '_history_source does not exist or lacks user_id column - skipping policy';
  END IF;
END $$;

-- Policy for _user_stats_source (if it has user_id column)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = '_user_stats_source'
  ) AND EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = '_user_stats_source' 
    AND column_name = 'user_id'
  ) THEN
    -- Drop existing policy if it exists
    DROP POLICY IF EXISTS "Users can view own user stats source" ON public._user_stats_source;
    
    -- Create policy
    CREATE POLICY "Users can view own user stats source"
      ON public._user_stats_source FOR SELECT
      USING (auth.uid() = user_id);
    
    RAISE NOTICE 'Policy created for _user_stats_source';
  ELSE
    RAISE NOTICE '_user_stats_source does not exist or lacks user_id column - skipping policy';
  END IF;
END $$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================
-- Check RLS status on source tables
SELECT 
  tablename,
  CASE 
    WHEN rowsecurity THEN '✓ RLS ENABLED'
    ELSE '✗ RLS DISABLED'
  END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('_history_source', '_user_stats_source')
ORDER BY tablename;

-- Check policies on source tables
SELECT 
  schemaname,
  tablename,
  policyname,
  'EXISTS' as status
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename IN ('_history_source', '_user_stats_source')
ORDER BY tablename, policyname;

