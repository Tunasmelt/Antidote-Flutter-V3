# Database to Flutter Model Mapping

This document maps the Supabase database schema to the Flutter app models and API endpoints.

## 📊 Table to Model Mapping

### Users Table → User Model

**Database Table:** `public.users`
**Flutter Model:** `lib/models/user.dart`

| Database Column | Flutter Field | Type | Notes |
|----------------|---------------|------|-------|
| `id` | `id` | String (UUID) | References `auth.users.id` |
| `username` | `username` | String | Unique username |
| `email` | `email` | String? | User email |
| `spotify_id` | `spotifyId` | String? | Spotify account ID |
| `avatar_url` | `avatarUrl` | String? | Profile picture URL |
| `display_name` | - | - | Not in model, can be added |
| `created_at` | `createdAt` | DateTime? | Account creation time |

**API Endpoints:**
- Profile data: Retrieved via Supabase Auth
- Stats: `GET /api/stats` → Uses `user_stats` view

---

### Playlists Table → Playlist Model

**Database Table:** `public.playlists`
**Flutter Model:** `lib/models/playlist.dart`

| Database Column | Flutter Field | Type | Notes |
|----------------|---------------|------|-------|
| `id` | `id` | int? → UUID | Primary key (UUID in DB) |
| `user_id` | `userId` | int? → UUID | Foreign key to users |
| `spotify_id` | `spotifyId` | String | Extracted from URL |
| `url` | `url` | String | Full playlist URL |
| `name` | `name` | String | Playlist name |
| `description` | `description` | String? | Optional description |
| `owner` | `owner` | String? | Playlist creator |
| `cover_url` | `coverUrl` | String? | Cover image URL |
| `track_count` | `trackCount` | int? | Auto-updated count |
| `created_at` | `createdAt` | DateTime | Creation timestamp |
| `analyzed_at` | `analyzedAt` | DateTime? | Last analysis time |

**API Endpoints:**
- `GET /api/playlists` → Returns all user playlists
- `POST /api/playlists` → Creates new playlist
- `DELETE /api/playlists/:id` → Deletes playlist

**Note:** Flutter model uses `int?` for IDs, but database uses UUID. Backend should handle conversion.

---

### Tracks Table → (No Direct Model)

**Database Table:** `public.tracks`
**Flutter Usage:** Embedded in `PlaylistAnalysis.topTracks`

Tracks are stored per playlist and include:
- Basic info: `name`, `artists[]`, `album`, `album_art_url`
- Spotify data: `spotify_id`, `popularity`, `release_date`
- Audio features: `audio_features` (JSONB)
- Genres: `genres[]` (array)

**API Endpoints:**
- Tracks are typically returned as part of playlist analysis
- Stored when playlist is analyzed

---

### Analyses Table → PlaylistAnalysis Model

**Database Table:** `public.analyses`
**Flutter Model:** `lib/models/analysis.dart` → `PlaylistAnalysis`

| Database Column | Flutter Field | Type | Notes |
|----------------|---------------|------|-------|
| `id` | - | UUID | Not in model |
| `user_id` | - | UUID | Not in model |
| `playlist_id` | - | UUID | Not in model |
| `personality_type` | `personalityType` | String | e.g., "The Explorer" |
| `personality_description` | `personalityDescription` | String | Detailed description |
| `health_score` | `healthScore` | int | 0-100 |
| `health_status` | `healthStatus` | String | Status text |
| `overall_rating` | `overallRating` | double | 0-10 |
| `rating_description` | `ratingDescription` | String | Rating explanation |
| `audio_dna` | `audioDna` | AudioDna | JSONB → Object |
| `genre_distribution` | `genreDistribution` | List<GenreDistribution> | JSONB → Array |
| `subgenres` | `subgenres` | List<String> | Array |
| `top_tracks` | `topTracks` | List<TopTrack> | JSONB → Array |

**Audio DNA Mapping:**
```json
{
  "energy": int,
  "danceability": int,
  "valence": int,
  "acousticness": int,
  "instrumentalness": int,
  "tempo": int
}
```

**Genre Distribution Mapping:**
```json
[
  {"name": "Pop", "value": 45},
  {"name": "Rock", "value": 30}
]
```

**Top Tracks Mapping:**
```json
[
  {"name": "Song Name", "artist": "Artist", "albumArt": "url"}
]
```

**API Endpoints:**
- `POST /api/analyze` → Creates analysis, returns `PlaylistAnalysis`
- `GET /api/history` → Returns analyses (via `history` view)

---

### Battles Table → BattleResult Model

**Database Table:** `public.battles`
**Flutter Model:** `lib/models/battle.dart` → `BattleResult`

| Database Column | Flutter Field | Type | Notes |
|----------------|---------------|------|-------|
| `id` | - | UUID | Not in model |
| `user_id` | - | UUID | Not in model |
| `playlist1_id` | - | UUID | Not in model |
| `playlist2_id` | - | UUID | Not in model |
| `compatibility_score` | `compatibilityScore` | int | 0-100 |
| `winner` | `winner` | String | 'playlist1', 'playlist2', 'tie' |
| `playlist1_data` | `playlist1` | BattlePlaylist | JSONB → Object |
| `playlist2_data` | `playlist2` | BattlePlaylist | JSONB → Object |
| `shared_artists` | `sharedArtists` | List<String> | Array |
| `shared_genres` | `sharedGenres` | List<String> | Array |
| `shared_tracks` | `sharedTracks` | List<SharedTrack> | JSONB → Array |
| `audio_data` | `audioData` | List<Map> | JSONB → Array |

**Playlist Data Mapping:**
```json
{
  "name": "Playlist Name",
  "owner": "Owner Name",
  "image": "cover_url",
  "score": 85,
  "tracks": 50
}
```

**Shared Tracks Mapping:**
```json
[
  {"title": "Song", "artist": "Artist"}
]
```

**API Endpoints:**
- `POST /api/battle` → Creates battle, returns `BattleResult`
- `GET /api/history` → Returns battles (via `history` view)

---

### Recommendations Table → (No Direct Model)

**Database Table:** `public.recommendations`
**Flutter Usage:** Returned as `List<Map<String, dynamic>>`

| Database Column | Flutter Field | Type | Notes |
|----------------|---------------|------|-------|
| `id` | - | UUID | Not in model |
| `user_id` | - | UUID | Not in model |
| `playlist_id` | - | UUID | Not in model |
| `strategy` | `type` | String | Recommendation type |
| `recommended_tracks` | - | List<Map> | JSONB → Array of track objects |
| `created_at` | - | DateTime | Not in model |

**Strategy Types:**
- `similar_audio` → "Similar Audio Features"
- `genre_exploration` → "Genre Exploration"
- `artist_collaborations` → "Artist Collaborations"
- `mood_match` → "Mood Match"
- `flavor_profile` → "Flavor Profile"
- `discovery` → "Discovery"

**API Endpoints:**
- `GET /api/recommendations?type=...` → Returns recommendations

---

## 🔄 Views Mapping

### History View → History Screen

**Database View:** `public.history`
**Flutter Screen:** `lib/screens/history_screen.dart`

Combines `analyses` and `battles` into a unified history:

| View Column | Flutter Usage | Type |
|-------------|---------------|------|
| `type` | Filter by 'analysis' or 'battle' | String |
| `id` | Item ID | UUID |
| `user_id` | Filter user's history | UUID |
| `created_at` | Sort by date | DateTime |
| `playlist_name` | Display name | String |
| `cover_url` | Display image | String? |
| `playlist_url` | Navigate to analysis | String? |
| `score` | Display (analyses only) | int? |
| `rating` | Display (analyses only) | decimal? |
| `winner` | Display (battles only) | String? |
| `compatibility_score` | Display (battles only) | int? |

**API Endpoints:**
- `GET /api/history` → Returns history items

---

### User Stats View → Profile Screen

**Database View:** `public.user_stats`
**Flutter Screen:** `lib/screens/profile_screen.dart`

| View Column | Flutter Usage | Type |
|-------------|---------------|------|
| `user_id` | Filter by user | UUID |
| `analyses_count` | Display count | BIGINT |
| `battles_count` | Display count | BIGINT |
| `saved_playlists_count` | Display count | BIGINT |
| `average_rating` | Display average | NUMERIC |
| `average_health_score` | Display average | NUMERIC |
| `last_analysis_at` | Display date | DateTime? |
| `last_battle_at` | Display date | DateTime? |

**API Endpoints:**
- `GET /api/stats` → Returns user statistics

---

## 🔐 Security Mapping

### Row Level Security (RLS)

All tables have RLS enabled with policies that ensure:
- Users can only **SELECT** their own data
- Users can only **INSERT** with their own `user_id`
- Users can only **UPDATE** their own data
- Users can only **DELETE** their own data

**Flutter Implementation:**
- Supabase client automatically includes `auth.uid()` in queries
- RLS policies are enforced at database level
- No additional security checks needed in Flutter code

---

## 📝 Data Flow Examples

### Example 1: Analyze Playlist

1. **Flutter:** User enters playlist URL
2. **API:** `POST /api/analyze` with `{url: "..."}`
3. **Backend:** 
   - Fetches playlist from Spotify
   - Analyzes tracks
   - Creates `playlist` record (if not exists)
   - Creates `tracks` records
   - Creates `analysis` record
4. **Database:** Inserts into `analyses` table
5. **API:** Returns `PlaylistAnalysis` JSON
6. **Flutter:** Displays analysis results

### Example 2: Save Playlist

1. **Flutter:** User clicks "Save Playlist"
2. **API:** `POST /api/playlists` with playlist data
3. **Backend:** 
   - Extracts Spotify ID from URL (trigger)
   - Creates `playlist` record
4. **Database:** Inserts into `playlists` table
5. **API:** Returns saved playlist
6. **Flutter:** Updates saved playlists list

### Example 3: View History

1. **Flutter:** User navigates to History screen
2. **API:** `GET /api/history`
3. **Backend:** 
   - Queries `history` view
   - Filters by `user_id` (RLS enforces)
4. **Database:** Returns combined analyses + battles
5. **API:** Returns history items
6. **Flutter:** Displays history list

---

## 🎯 Key Differences

### ID Types
- **Database:** Uses UUID for all IDs
- **Flutter Models:** Some use `int?` (legacy)
- **Solution:** Backend should handle UUID ↔ int conversion if needed

### Timestamps
- **Database:** `TIMESTAMP WITH TIME ZONE`
- **Flutter:** `DateTime`
- **Solution:** ISO 8601 strings in JSON, automatic conversion

### JSONB Fields
- **Database:** JSONB for complex objects
- **Flutter:** Dart objects/classes
- **Solution:** JSON serialization/deserialization

---

## ✅ Verification Checklist

- [ ] All tables created successfully
- [ ] RLS policies enabled and working
- [ ] Indexes created for performance
- [ ] Triggers working (track count, Spotify ID extraction)
- [ ] Views returning correct data
- [ ] API endpoints match database schema
- [ ] Flutter models can deserialize database JSON
- [ ] User authentication working with RLS

---

This mapping ensures the database schema perfectly supports the Flutter app's data needs! 🎉

