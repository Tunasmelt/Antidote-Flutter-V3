-- ============================================================================
-- ANTIDOTE FLUTTER - DATABASE SETUP VERIFICATION
-- ============================================================================
-- This script verifies that your database is properly set up
-- Run this after running schema.sql, rls_policies.sql, indexes.sql, and functions.sql
-- OR after running setup_complete.sql
-- ============================================================================

-- ============================================================================
-- 1. VERIFY TABLES EXIST
-- ============================================================================
SELECT 
  'TABLES CHECK' as check_type,
  COUNT(*) as count,
  CASE 
    WHEN COUNT(*) = 8 THEN '✓ PASS - All 8 tables exist'
    ELSE '✗ FAIL - Missing tables (expected 8)'
  END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
  AND table_name IN ('users', 'playlists', 'tracks', 'analyses', 'battles', 'recommendations', 'liked_tracks', 'taste_profiles');

-- List all tables
SELECT 
  'Table: ' || table_name as item,
  'EXISTS' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
  AND table_name IN ('users', 'playlists', 'tracks', 'analyses', 'battles', 'recommendations', 'liked_tracks', 'taste_profiles')
ORDER BY table_name;

-- ============================================================================
-- 2. VERIFY VIEWS EXIST
-- ============================================================================
SELECT 
  'VIEWS CHECK' as check_type,
  COUNT(*) as count,
  CASE 
    WHEN COUNT(*) = 2 THEN '✓ PASS - All 2 views exist'
    ELSE '✗ FAIL - Missing views (expected 2)'
  END as status
FROM information_schema.views 
WHERE table_schema = 'public' 
  AND table_name IN ('history', 'user_stats');

-- List all views
SELECT 
  'View: ' || table_name as item,
  'EXISTS' as status
FROM information_schema.views 
WHERE table_schema = 'public' 
  AND table_name IN ('history', 'user_stats')
ORDER BY table_name;

-- ============================================================================
-- 3. VERIFY ROW LEVEL SECURITY IS ENABLED
-- ============================================================================
SELECT 
  'RLS CHECK' as check_type,
  COUNT(*) as tables_with_rls,
  CASE 
    WHEN COUNT(*) = 8 THEN '✓ PASS - RLS enabled on all 8 tables'
    ELSE '✗ FAIL - RLS not enabled on all tables'
  END as status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND rowsecurity = true
  AND tablename IN ('users', 'playlists', 'tracks', 'analyses', 'battles', 'recommendations', 'liked_tracks', 'taste_profiles');

-- List RLS status for each table
SELECT 
  tablename,
  CASE 
    WHEN rowsecurity THEN '✓ ENABLED'
    ELSE '✗ DISABLED'
  END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('users', 'playlists', 'tracks', 'analyses', 'battles', 'recommendations', 'liked_tracks', 'taste_profiles')
ORDER BY tablename;

-- Check RLS on Supabase internal source tables (if they exist)
SELECT 
  'SOURCE TABLES RLS CHECK' as check_type,
  COUNT(*) as source_tables_with_rls,
  CASE 
    WHEN COUNT(*) = 0 THEN '⚠ INFO - No source tables found (this is OK)'
    WHEN COUNT(*) = (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE '%_source' AND rowsecurity = true) THEN '✓ PASS - All source tables have RLS enabled'
    ELSE '✗ FAIL - Some source tables missing RLS'
  END as status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename LIKE '%_source'
  AND rowsecurity = true;

-- List source tables RLS status
SELECT 
  tablename,
  CASE 
    WHEN rowsecurity THEN '✓ ENABLED'
    ELSE '✗ DISABLED - Run enable_rls_source_tables.sql'
  END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename LIKE '%_source'
ORDER BY tablename;

-- ============================================================================
-- 4. VERIFY POLICIES EXIST
-- ============================================================================
-- Count policies per table
SELECT 
  schemaname,
  tablename,
  COUNT(*) as policy_count,
  CASE 
    WHEN tablename = 'users' AND COUNT(*) >= 4 THEN '✓ PASS'
    WHEN tablename = 'playlists' AND COUNT(*) >= 4 THEN '✓ PASS'
    WHEN tablename = 'tracks' AND COUNT(*) >= 4 THEN '✓ PASS'
    WHEN tablename = 'analyses' AND COUNT(*) >= 4 THEN '✓ PASS'
    WHEN tablename = 'battles' AND COUNT(*) >= 4 THEN '✓ PASS'
    WHEN tablename = 'recommendations' AND COUNT(*) >= 4 THEN '✓ PASS'
    WHEN tablename = 'liked_tracks' AND COUNT(*) >= 4 THEN '✓ PASS'
    WHEN tablename = 'taste_profiles' AND COUNT(*) >= 4 THEN '✓ PASS'
    ELSE '✗ FAIL - Missing policies'
  END as status
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename IN ('users', 'playlists', 'tracks', 'analyses', 'battles', 'recommendations', 'liked_tracks', 'taste_profiles')
GROUP BY schemaname, tablename
ORDER BY tablename;

-- Total policy count
SELECT 
  'POLICIES CHECK' as check_type,
  COUNT(*) as total_policies,
  CASE 
    WHEN COUNT(*) >= 32 THEN '✓ PASS - Sufficient policies created'
    ELSE '✗ FAIL - Missing policies (expected at least 32)'
  END as status
FROM pg_policies 
WHERE schemaname = 'public'
  AND tablename IN ('users', 'playlists', 'tracks', 'analyses', 'battles', 'recommendations', 'liked_tracks', 'taste_profiles');

-- ============================================================================
-- 5. VERIFY INDEXES EXIST
-- ============================================================================
SELECT 
  'INDEXES CHECK' as check_type,
  COUNT(*) as index_count,
  CASE 
    WHEN COUNT(*) >= 30 THEN '✓ PASS - Sufficient indexes created'
    ELSE '⚠ WARNING - Some indexes may be missing'
  END as status
FROM pg_indexes 
WHERE schemaname = 'public'
  AND tablename IN ('users', 'playlists', 'tracks', 'analyses', 'battles', 'recommendations', 'liked_tracks', 'taste_profiles');

-- List indexes by table
SELECT 
  tablename,
  COUNT(*) as index_count
FROM pg_indexes 
WHERE schemaname = 'public'
  AND tablename IN ('users', 'playlists', 'tracks', 'analyses', 'battles', 'recommendations', 'liked_tracks', 'taste_profiles')
GROUP BY tablename
ORDER BY tablename;

-- ============================================================================
-- 6. VERIFY FUNCTIONS EXIST
-- ============================================================================
SELECT 
  'FUNCTIONS CHECK' as check_type,
  COUNT(*) as function_count,
  CASE 
    WHEN COUNT(*) >= 4 THEN '✓ PASS - Key functions exist'
    ELSE '⚠ WARNING - Some functions may be missing'
  END as status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN ('handle_updated_at', 'handle_new_user', 'update_playlist_track_count', 'extract_spotify_id');

-- List functions
SELECT 
  'Function: ' || proname as item,
  'EXISTS' as status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
  AND p.proname IN ('handle_updated_at', 'handle_new_user', 'update_playlist_track_count', 'extract_spotify_id')
ORDER BY proname;

-- ============================================================================
-- 7. VERIFY TRIGGERS EXIST
-- ============================================================================
SELECT 
  'TRIGGERS CHECK' as check_type,
  COUNT(*) as trigger_count,
  CASE 
    WHEN COUNT(*) >= 6 THEN '✓ PASS - Key triggers exist'
    ELSE '⚠ WARNING - Some triggers may be missing'
  END as status
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
  AND t.tgname NOT LIKE 'RI_%'  -- Exclude foreign key triggers
  AND t.tgisinternal = false;

-- List triggers
SELECT 
  c.relname as table_name,
  t.tgname as trigger_name,
  'EXISTS' as status
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
  AND t.tgname NOT LIKE 'RI_%'
  AND t.tgisinternal = false
ORDER BY c.relname, t.tgname;

-- ============================================================================
-- 8. VERIFY EXTENSIONS ARE ENABLED
-- ============================================================================
SELECT 
  'EXTENSIONS CHECK' as check_type,
  COUNT(*) as extension_count,
  CASE 
    WHEN COUNT(*) >= 2 THEN '✓ PASS - Required extensions enabled'
    ELSE '✗ FAIL - Missing extensions'
  END as status
FROM pg_extension 
WHERE extname IN ('uuid-ossp', 'pg_trgm');

-- List extensions
SELECT 
  extname as extension_name,
  'ENABLED' as status
FROM pg_extension 
WHERE extname IN ('uuid-ossp', 'pg_trgm')
ORDER BY extname;

-- ============================================================================
-- 9. SUMMARY REPORT
-- ============================================================================
SELECT 
  '=== DATABASE SETUP VERIFICATION SUMMARY ===' as summary
UNION ALL
SELECT 
  'Tables: ' || 
  (SELECT COUNT(*)::text FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' AND table_name IN ('users', 'playlists', 'tracks', 'analyses', 'battles', 'recommendations', 'liked_tracks', 'taste_profiles')) ||
  ' / 8' as summary
UNION ALL
SELECT 
  'Views: ' || 
  (SELECT COUNT(*)::text FROM information_schema.views WHERE table_schema = 'public' AND table_name IN ('history', 'user_stats')) ||
  ' / 2' as summary
UNION ALL
SELECT 
  'RLS Enabled: ' || 
  (SELECT COUNT(*)::text FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true AND tablename IN ('users', 'playlists', 'tracks', 'analyses', 'battles', 'recommendations', 'liked_tracks', 'taste_profiles')) ||
  ' / 8' as summary
UNION ALL
SELECT 
  'Policies: ' || 
  (SELECT COUNT(*)::text FROM pg_policies WHERE schemaname = 'public' AND tablename IN ('users', 'playlists', 'tracks', 'analyses', 'battles', 'recommendations', 'liked_tracks', 'taste_profiles')) ||
  ' (expected: 32+)' as summary
UNION ALL
SELECT 
  'Indexes: ' || 
  (SELECT COUNT(*)::text FROM pg_indexes WHERE schemaname = 'public' AND tablename IN ('users', 'playlists', 'tracks', 'analyses', 'battles', 'recommendations', 'liked_tracks', 'taste_profiles')) ||
  ' (expected: 30+)' as summary
UNION ALL
SELECT 
  'Functions: ' || 
  (SELECT COUNT(*)::text FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname IN ('handle_updated_at', 'handle_new_user', 'update_playlist_track_count', 'extract_spotify_id')) ||
  ' / 4' as summary
UNION ALL
SELECT 
  'Triggers: ' || 
  (SELECT COUNT(*)::text FROM pg_trigger t JOIN pg_class c ON t.tgrelid = c.oid JOIN pg_namespace n ON c.relnamespace = n.oid WHERE n.nspname = 'public' AND c.relkind = 'r' AND t.tgname NOT LIKE 'RI_%' AND t.tgisinternal = false) ||
  ' (expected: 6+)' as summary
UNION ALL
SELECT 
  'Extensions: ' || 
  (SELECT COUNT(*)::text FROM pg_extension WHERE extname IN ('uuid-ossp', 'pg_trgm')) ||
  ' / 2' as summary
UNION ALL
SELECT 
  'Source Tables RLS: ' || 
  COALESCE((SELECT COUNT(*)::text FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE '%_source' AND rowsecurity = true), '0') ||
  ' / ' || 
  COALESCE((SELECT COUNT(*)::text FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE '%_source'), '0') ||
  ' (if any exist)' as summary;

-- ============================================================================
-- 10. QUICK HEALTH CHECK
-- ============================================================================
-- This query returns a simple pass/fail for the entire setup
SELECT 
  CASE 
    WHEN 
      (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE' AND table_name IN ('users', 'playlists', 'tracks', 'analyses', 'battles', 'recommendations', 'liked_tracks', 'taste_profiles')) = 8
      AND (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'public' AND table_name IN ('history', 'user_stats')) = 2
      AND (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true AND tablename IN ('users', 'playlists', 'tracks', 'analyses', 'battles', 'recommendations', 'liked_tracks', 'taste_profiles')) = 8
      AND (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename IN ('users', 'playlists', 'tracks', 'analyses', 'battles', 'recommendations', 'liked_tracks', 'taste_profiles')) >= 32
      AND (
        -- Source tables either don't exist OR all have RLS enabled
        (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE '%_source') = 0
        OR (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE '%_source' AND rowsecurity = true) = 
           (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE '%_source')
      )
    THEN '✓✓✓ DATABASE SETUP COMPLETE - All checks passed! ✓✓✓'
    ELSE '✗✗✗ DATABASE SETUP INCOMPLETE - Review individual checks above ✗✗✗'
  END as overall_status;

