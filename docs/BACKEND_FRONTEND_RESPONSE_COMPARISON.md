# Backend Response Structure vs Frontend Expectations

## Summary
This document compares backend API response structures with frontend model expectations and actual usage.

---

## ✅ POST /api/analyze

### Backend Returns (camelCase):
```typescript
{
  playlistName: string,
  owner: string,
  coverUrl: string | null,
  trackCount: number,
  audioDna: {
    energy: number,
    danceability: number,
    valence: number,
    acousticness: number,
    instrumentalness: number,
    tempo: number
  },
  personalityType: string,
  personalityDescription: string,
  genreDistribution: Array<{name: string, value: number}>,
  subgenres: string[],
  healthScore: number,
  healthStatus: string,
  overallRating: number,
  ratingDescription: string,
  topTracks: Array<{
    name: string,
    artist: string,
    albumArt: string | null
  }>
}
```

### Frontend Expects (PlaylistAnalysis model):
- ✅ Matches perfectly - model handles both camelCase and snake_case
- ✅ All fields have proper fallbacks
- ✅ Type conversions are safe

**Status: ✅ MATCHES**

---

## ✅ POST /api/battle

### Backend Returns (camelCase):
```typescript
{
  compatibilityScore: number,
  winner: string,
  playlist1: {
    name: string,
    owner: string,
    image: string | null,
    score: number,
    tracks: number
  },
  playlist2: {
    name: string,
    owner: string,
    image: string | null,
    score: number,
    tracks: number
  },
  sharedArtists: string[],
  sharedGenres: string[],
  sharedTracks: Array<{
    title: string,
    artist: string
  }>,
  audioData: Array<{
    playlist: 'playlist1' | 'playlist2',
    energy: number,
    danceability: number,
    valence: number,
    acousticness: number,
    tempo: number
  }>
}
```

### Frontend Expects (BattleResult model):
- ✅ Model handles both camelCase and snake_case
- ✅ audioData transformation handled in battle_screen.dart
- ✅ All fields have proper fallbacks

**Status: ✅ MATCHES**

---

## ✅ GET /api/recommendations

### Backend Returns:
```typescript
// Direct Spotify API response: Array of track objects
Array<SpotifyTrackObject>
```

### Frontend Expects:
- ✅ Handles Spotify track format with artists array
- ✅ Extracts name, artist, albumArt, previewUrl properly
- ✅ Safe type checking in recommendations_screen.dart

**Status: ✅ MATCHES**

---

## ⚠️ GET /api/playlists

### Backend Returns (snake_case from database):
```typescript
Array<{
  id: UUID (string),
  user_id: UUID (string),
  spotify_id: string | null,
  url: string,
  name: string,
  description: string | null,
  owner: string | null,
  cover_url: string | null,
  track_count: number,
  platform: string,
  created_at: ISO timestamp string,
  updated_at: ISO timestamp string,
  analyzed_at: ISO timestamp string | null
}>
```

### Frontend Expects (saved_playlists_screen.dart):
```dart
{
  'id': string,
  'name': string,
  'trackCount': number,  // from track_count
  'coverUrl': string | null,  // from cover_url
  'createdAt': ISO string,  // from created_at
  'url': string
}
```

### Frontend Transformation:
```dart
return playlists.map((p) {
  return {
    'id': p['id']?.toString(),
    'name': p['name'] ?? 'Untitled Playlist',
    'trackCount': p['track_count'] ?? p['trackCount'] ?? 0,
    'coverUrl': p['cover_url'] ?? p['coverUrl'],
    'createdAt': p['created_at'] ?? p['createdAt'],
    'url': p['url'] ?? '',
  };
}).toList();
```

**Status: ✅ MATCHES (with transformation)**

---

## ⚠️ GET /api/history

### Backend Returns (snake_case from database view):
```typescript
Array<{
  type: 'analysis' | 'battle',
  id: UUID (string),
  user_id: UUID (string),
  created_at: ISO timestamp string,
  playlist_name: string,
  cover_url: string | null,
  playlist_url: string | null,
  score: number | null,  // for analysis only
  rating: number | null,  // for analysis only
  winner: string | null,  // for battle only
  compatibility_score: number | null  // for battle only
}>
```

### Frontend Expects (history_screen.dart):
```dart
{
  'type': string,
  'created_at': string,  // ✅ Fixed to check both created_at and date
  'playlist_name': string,  // ✅ Fixed to check both playlist_name and title
  'playlist_url': string | null,  // ✅ Fixed to check both playlist_url and url
  'cover_url': string | null,
  'score': number | null,
  'rating': number | null,
  'winner': string | null,
  'compatibility_score': number | null
}
```

**Status: ✅ MATCHES (already fixed)**

---

## ✅ GET /api/stats

### Backend Returns (camelCase):
```typescript
{
  analysesCount: number,
  battlesCount: number,
  savedPlaylistsCount: number,
  averageRating: number,
  averageHealthScore: number,
  lastAnalysisAt: ISO string | null,
  lastBattleAt: ISO string | null
}
```

### Frontend Expects (profile_screen.dart):
```dart
{
  'analysesCount': number,
  'battlesCount': number,
  'averageRating': number,  // ✅ Fixed to check both averageRating and averageScore
  // averageHealthScore not used
  // lastAnalysisAt not used
  // lastBattleAt not used
}
```

**Status: ✅ MATCHES (already fixed)**

---

## ✅ POST /api/playlists (create)

### Backend Returns (camelCase):
```typescript
{
  id: string,
  name: string,
  url: string,
  trackCount: number
}
```

### Frontend Expects:
- ✅ Returns Map<String, dynamic> - no model needed
- ✅ All fields match

**Status: ✅ MATCHES**

---

## ✅ DELETE /api/playlists/:id

### Backend Returns:
```typescript
{
  success: true,
  message: 'Playlist deleted successfully'
}
```

### Frontend Expects:
- ✅ No response parsing needed - just checks for success
- ✅ Error handling in place

**Status: ✅ MATCHES**

---

## Summary

All endpoints are properly aligned:
- ✅ Analysis endpoint: Perfect match
- ✅ Battle endpoint: Perfect match (with frontend transformation)
- ✅ Recommendations endpoint: Handles Spotify format correctly
- ✅ Playlists endpoint: Proper snake_case to camelCase transformation
- ✅ History endpoint: Proper field mapping (already fixed)
- ✅ Stats endpoint: Proper field mapping (already fixed)
- ✅ Create playlist: Perfect match
- ✅ Delete playlist: Perfect match

**All endpoints are correctly structured and match frontend expectations!**

