-- ============================================================================
-- ANTIDOTE FLUTTER - DATABASE INDEXES FOR PERFORMANCE
-- ============================================================================
-- This script creates indexes to optimize query performance
-- Run this AFTER schema.sql
-- ============================================================================

-- ============================================================================
-- USERS TABLE INDEXES
-- ============================================================================

-- Index for username lookups (already unique, but explicit index for performance)
CREATE INDEX IF NOT EXISTS idx_users_username ON public.users(username) WHERE username IS NOT NULL;

-- Index for email lookups
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email) WHERE email IS NOT NULL;

-- Index for Spotify ID lookups
CREATE INDEX IF NOT EXISTS idx_users_spotify_id ON public.users(spotify_id) WHERE spotify_id IS NOT NULL;

-- ============================================================================
-- PLAYLISTS TABLE INDEXES
-- ============================================================================

-- Index for user playlists (most common query)
CREATE INDEX IF NOT EXISTS idx_playlists_user_id ON public.playlists(user_id);

-- Index for playlist URL lookups
CREATE INDEX IF NOT EXISTS idx_playlists_url ON public.playlists(url);

-- Index for Spotify ID lookups
CREATE INDEX IF NOT EXISTS idx_playlists_spotify_id ON public.playlists(spotify_id) WHERE spotify_id IS NOT NULL;

-- Index for created_at (for sorting)
CREATE INDEX IF NOT EXISTS idx_playlists_created_at ON public.playlists(created_at DESC);

-- Index for analyzed_at (for filtering analyzed playlists)
CREATE INDEX IF NOT EXISTS idx_playlists_analyzed_at ON public.playlists(analyzed_at DESC) WHERE analyzed_at IS NOT NULL;

-- Composite index for user + created_at (common query pattern)
CREATE INDEX IF NOT EXISTS idx_playlists_user_created ON public.playlists(user_id, created_at DESC);

-- ============================================================================
-- TRACKS TABLE INDEXES
-- ============================================================================

-- Index for playlist tracks (most common query)
CREATE INDEX IF NOT EXISTS idx_tracks_playlist_id ON public.tracks(playlist_id);

-- Index for Spotify track ID lookups
CREATE INDEX IF NOT EXISTS idx_tracks_spotify_id ON public.tracks(spotify_id) WHERE spotify_id IS NOT NULL;

-- Index for track name search (using GIN for text search)
CREATE INDEX IF NOT EXISTS idx_tracks_name_trgm ON public.tracks USING gin(name gin_trgm_ops);

-- Index for artist array searches
CREATE INDEX IF NOT EXISTS idx_tracks_artists ON public.tracks USING gin(artists);

-- Index for genre array searches
CREATE INDEX IF NOT EXISTS idx_tracks_genres ON public.tracks USING gin(genres);

-- Index for audio features JSONB queries
CREATE INDEX IF NOT EXISTS idx_tracks_audio_features ON public.tracks USING gin(audio_features);

-- Composite index for playlist + popularity (for top tracks)
CREATE INDEX IF NOT EXISTS idx_tracks_playlist_popularity ON public.tracks(playlist_id, popularity DESC NULLS LAST);

-- ============================================================================
-- ANALYSES TABLE INDEXES
-- ============================================================================

-- Index for user analyses
CREATE INDEX IF NOT EXISTS idx_analyses_user_id ON public.analyses(user_id);

-- Index for playlist analyses
CREATE INDEX IF NOT EXISTS idx_analyses_playlist_id ON public.analyses(playlist_id);

-- Index for created_at (for history sorting)
CREATE INDEX IF NOT EXISTS idx_analyses_created_at ON public.analyses(created_at DESC);

-- Composite index for user + created_at (common query pattern)
CREATE INDEX IF NOT EXISTS idx_analyses_user_created ON public.analyses(user_id, created_at DESC);

-- Index for health score queries
CREATE INDEX IF NOT EXISTS idx_analyses_health_score ON public.analyses(health_score DESC);

-- Index for overall rating queries
CREATE INDEX IF NOT EXISTS idx_analyses_rating ON public.analyses(overall_rating DESC);

-- Index for personality type queries
CREATE INDEX IF NOT EXISTS idx_analyses_personality_type ON public.analyses(personality_type) WHERE personality_type IS NOT NULL;

-- Index for genre distribution JSONB queries
CREATE INDEX IF NOT EXISTS idx_analyses_genre_distribution ON public.analyses USING gin(genre_distribution);

-- ============================================================================
-- BATTLES TABLE INDEXES
-- ============================================================================

-- Index for user battles
CREATE INDEX IF NOT EXISTS idx_battles_user_id ON public.battles(user_id);

-- Index for playlist1 lookups
CREATE INDEX IF NOT EXISTS idx_battles_playlist1_id ON public.battles(playlist1_id);

-- Index for playlist2 lookups
CREATE INDEX IF NOT EXISTS idx_battles_playlist2_id ON public.battles(playlist2_id);

-- Index for created_at (for history sorting)
CREATE INDEX IF NOT EXISTS idx_battles_created_at ON public.battles(created_at DESC);

-- Composite index for user + created_at (common query pattern)
CREATE INDEX IF NOT EXISTS idx_battles_user_created ON public.battles(user_id, created_at DESC);

-- Index for compatibility score queries
CREATE INDEX IF NOT EXISTS idx_battles_compatibility_score ON public.battles(compatibility_score DESC);

-- Index for winner queries
CREATE INDEX IF NOT EXISTS idx_battles_winner ON public.battles(winner) WHERE winner IS NOT NULL;

-- ============================================================================
-- RECOMMENDATIONS TABLE INDEXES
-- ============================================================================

-- Index for user recommendations
CREATE INDEX IF NOT EXISTS idx_recommendations_user_id ON public.recommendations(user_id);

-- Index for playlist recommendations
CREATE INDEX IF NOT EXISTS idx_recommendations_playlist_id ON public.recommendations(playlist_id);

-- Index for strategy type queries
CREATE INDEX IF NOT EXISTS idx_recommendations_strategy ON public.recommendations(strategy);

-- Index for created_at (for sorting)
CREATE INDEX IF NOT EXISTS idx_recommendations_created_at ON public.recommendations(created_at DESC);

-- Composite index for user + strategy + created_at
CREATE INDEX IF NOT EXISTS idx_recommendations_user_strategy_created ON public.recommendations(user_id, strategy, created_at DESC);

-- ============================================================================
-- FULL TEXT SEARCH INDEXES
-- ============================================================================

-- Full text search on playlist names
CREATE INDEX IF NOT EXISTS idx_playlists_name_search ON public.playlists USING gin(to_tsvector('english', name));

-- Full text search on track names
CREATE INDEX IF NOT EXISTS idx_tracks_name_search ON public.tracks USING gin(to_tsvector('english', name));

-- ============================================================================
-- NOTES
-- ============================================================================
-- Indexes are automatically maintained by PostgreSQL
-- GIN indexes are used for array and JSONB columns for efficient searches
-- Composite indexes support common query patterns (user_id + created_at)
-- DESC indexes optimize ORDER BY DESC queries

