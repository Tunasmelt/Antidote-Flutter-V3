-- ============================================================================
-- ANTIDOTE FLUTTER - DATABASE INDEXES FOR PERFORMANCE
-- ============================================================================
-- This script creates indexes to optimize query performance
-- Run this AFTER schema.sql
-- 
-- FOR FRESH DATABASE: All indexes use IF NOT EXISTS, so this script is safe
-- to run on a new database or re-run on an existing database
-- ============================================================================

-- ============================================================================
-- USERS TABLE INDEXES
-- ============================================================================

-- Users indexes (only create if table and columns exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'username') THEN
      CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username) WHERE username IS NOT NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'email') THEN
      CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email) WHERE email IS NOT NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'spotify_id') THEN
      CREATE INDEX IF NOT EXISTS idx_users_spotify_id ON public.users(spotify_id) WHERE spotify_id IS NOT NULL;
    END IF;
  END IF;
END $$;

-- ============================================================================
-- PLAYLISTS TABLE INDEXES
-- ============================================================================

-- Playlists indexes (only create if table and columns exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'playlists') THEN
    CREATE INDEX IF NOT EXISTS idx_playlists_user_id ON public.playlists(user_id);
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'playlists' AND column_name = 'url') THEN
      CREATE INDEX IF NOT EXISTS idx_playlists_url ON public.playlists(url);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'playlists' AND column_name = 'spotify_id') THEN
      CREATE INDEX IF NOT EXISTS idx_playlists_spotify_id ON public.playlists(spotify_id) WHERE spotify_id IS NOT NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'playlists' AND column_name = 'created_at') THEN
      CREATE INDEX IF NOT EXISTS idx_playlists_created_at ON public.playlists(created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_playlists_user_created ON public.playlists(user_id, created_at DESC);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'playlists' AND column_name = 'analyzed_at') THEN
      CREATE INDEX IF NOT EXISTS idx_playlists_analyzed_at ON public.playlists(analyzed_at DESC) WHERE analyzed_at IS NOT NULL;
    END IF;
  END IF;
END $$;

-- ============================================================================
-- TRACKS TABLE INDEXES
-- ============================================================================

-- Tracks indexes (only create if table and columns exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tracks') THEN
    CREATE INDEX IF NOT EXISTS idx_tracks_playlist_id ON public.tracks(playlist_id);
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'tracks' AND column_name = 'spotify_id') THEN
      CREATE INDEX IF NOT EXISTS idx_tracks_spotify_id ON public.tracks(spotify_id) WHERE spotify_id IS NOT NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'tracks' AND column_name = 'name') THEN
      CREATE INDEX IF NOT EXISTS idx_tracks_name_trgm ON public.tracks USING gin(name gin_trgm_ops);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'tracks' AND column_name = 'artists') THEN
      CREATE INDEX IF NOT EXISTS idx_tracks_artists ON public.tracks USING gin(artists);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'tracks' AND column_name = 'genres') THEN
      CREATE INDEX IF NOT EXISTS idx_tracks_genres ON public.tracks USING gin(genres);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'tracks' AND column_name = 'audio_features') THEN
      CREATE INDEX IF NOT EXISTS idx_tracks_audio_features ON public.tracks USING gin(audio_features);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'tracks' AND column_name = 'popularity') THEN
      CREATE INDEX IF NOT EXISTS idx_tracks_playlist_popularity ON public.tracks(playlist_id, popularity DESC NULLS LAST);
    END IF;
  END IF;
END $$;

-- ============================================================================
-- ANALYSES TABLE INDEXES
-- ============================================================================

-- Analyses indexes (only create if table and columns exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'analyses') THEN
    CREATE INDEX IF NOT EXISTS idx_analyses_user_id ON public.analyses(user_id);
    CREATE INDEX IF NOT EXISTS idx_analyses_playlist_id ON public.analyses(playlist_id);
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'analyses' AND column_name = 'created_at') THEN
      CREATE INDEX IF NOT EXISTS idx_analyses_created_at ON public.analyses(created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_analyses_user_created ON public.analyses(user_id, created_at DESC);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'analyses' AND column_name = 'health_score') THEN
      CREATE INDEX IF NOT EXISTS idx_analyses_health_score ON public.analyses(health_score DESC);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'analyses' AND column_name = 'overall_rating') THEN
      CREATE INDEX IF NOT EXISTS idx_analyses_rating ON public.analyses(overall_rating DESC);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'analyses' AND column_name = 'personality_type') THEN
      CREATE INDEX IF NOT EXISTS idx_analyses_personality_type ON public.analyses(personality_type) WHERE personality_type IS NOT NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'analyses' AND column_name = 'genre_distribution') THEN
      CREATE INDEX IF NOT EXISTS idx_analyses_genre_distribution ON public.analyses USING gin(genre_distribution);
    END IF;
  END IF;
END $$;

-- ============================================================================
-- BATTLES TABLE INDEXES
-- ============================================================================

-- Battles indexes (only create if table and columns exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'battles') THEN
    CREATE INDEX IF NOT EXISTS idx_battles_user_id ON public.battles(user_id);
    CREATE INDEX IF NOT EXISTS idx_battles_playlist1_id ON public.battles(playlist1_id);
    CREATE INDEX IF NOT EXISTS idx_battles_playlist2_id ON public.battles(playlist2_id);
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'battles' AND column_name = 'created_at') THEN
      CREATE INDEX IF NOT EXISTS idx_battles_created_at ON public.battles(created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_battles_user_created ON public.battles(user_id, created_at DESC);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'battles' AND column_name = 'compatibility_score') THEN
      CREATE INDEX IF NOT EXISTS idx_battles_compatibility_score ON public.battles(compatibility_score DESC);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'battles' AND column_name = 'winner') THEN
      CREATE INDEX IF NOT EXISTS idx_battles_winner ON public.battles(winner) WHERE winner IS NOT NULL;
    END IF;
  END IF;
END $$;

-- ============================================================================
-- RECOMMENDATIONS TABLE INDEXES
-- ============================================================================

-- Recommendations indexes (only create if table and columns exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'recommendations') THEN
    CREATE INDEX IF NOT EXISTS idx_recommendations_user_id ON public.recommendations(user_id);
    CREATE INDEX IF NOT EXISTS idx_recommendations_playlist_id ON public.recommendations(playlist_id);
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'recommendations' AND column_name = 'strategy') THEN
      CREATE INDEX IF NOT EXISTS idx_recommendations_strategy ON public.recommendations(strategy);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'recommendations' AND column_name = 'created_at') THEN
      CREATE INDEX IF NOT EXISTS idx_recommendations_created_at ON public.recommendations(created_at DESC);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'recommendations' AND column_name = 'strategy')
         AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'recommendations' AND column_name = 'created_at') THEN
      CREATE INDEX IF NOT EXISTS idx_recommendations_user_strategy_created ON public.recommendations(user_id, strategy, created_at DESC);
    END IF;
  END IF;
END $$;

-- ============================================================================
-- LIKED TRACKS TABLE INDEXES
-- ============================================================================

-- Liked tracks indexes (only create if table and columns exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'liked_tracks') THEN
    CREATE INDEX IF NOT EXISTS idx_liked_tracks_user_id ON public.liked_tracks(user_id);
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'liked_tracks' AND column_name = 'spotify_id') THEN
      CREATE INDEX IF NOT EXISTS idx_liked_tracks_spotify_id ON public.liked_tracks(spotify_id) WHERE spotify_id IS NOT NULL;
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'liked_tracks' AND column_name = 'liked_at') THEN
      CREATE INDEX IF NOT EXISTS idx_liked_tracks_liked_at ON public.liked_tracks(liked_at DESC);
      CREATE INDEX IF NOT EXISTS idx_liked_tracks_user_liked ON public.liked_tracks(user_id, liked_at DESC);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'liked_tracks' AND column_name = 'track_name') THEN
      CREATE INDEX IF NOT EXISTS idx_liked_tracks_name_trgm ON public.liked_tracks USING gin(track_name gin_trgm_ops);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'liked_tracks' AND column_name = 'artist_name') THEN
      CREATE INDEX IF NOT EXISTS idx_liked_tracks_artist_trgm ON public.liked_tracks USING gin(artist_name gin_trgm_ops);
    END IF;
  END IF;
END $$;

-- ============================================================================
-- TASTE PROFILES TABLE INDEXES
-- ============================================================================

-- Taste profiles indexes (only create if table and columns exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'taste_profiles') THEN
    CREATE INDEX IF NOT EXISTS idx_taste_profiles_user_id ON public.taste_profiles(user_id);
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'taste_profiles' AND column_name = 'last_updated') THEN
      CREATE INDEX IF NOT EXISTS idx_taste_profiles_last_updated ON public.taste_profiles(last_updated DESC);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'taste_profiles' AND column_name = 'top_genres') THEN
      CREATE INDEX IF NOT EXISTS idx_taste_profiles_top_genres ON public.taste_profiles USING gin(top_genres);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'taste_profiles' AND column_name = 'top_artists') THEN
      CREATE INDEX IF NOT EXISTS idx_taste_profiles_top_artists ON public.taste_profiles USING gin(top_artists);
    END IF;
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'taste_profiles' AND column_name = 'audio_features') THEN
      CREATE INDEX IF NOT EXISTS idx_taste_profiles_audio_features ON public.taste_profiles USING gin(audio_features);
    END IF;
  END IF;
END $$;

-- ============================================================================
-- FULL TEXT SEARCH INDEXES
-- ============================================================================

-- Full text search indexes (only create if table and columns exist)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'playlists')
     AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'playlists' AND column_name = 'name') THEN
    CREATE INDEX IF NOT EXISTS idx_playlists_name_search ON public.playlists USING gin(to_tsvector('english', name));
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tracks')
     AND EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'tracks' AND column_name = 'name') THEN
    CREATE INDEX IF NOT EXISTS idx_tracks_name_search ON public.tracks USING gin(to_tsvector('english', name));
  END IF;
END $$;

-- ============================================================================
-- NOTES
-- ============================================================================
-- Indexes are automatically maintained by PostgreSQL
-- GIN indexes are used for array and JSONB columns for efficient searches
-- Composite indexes support common query patterns (user_id + created_at)
-- DESC indexes optimize ORDER BY DESC queries

