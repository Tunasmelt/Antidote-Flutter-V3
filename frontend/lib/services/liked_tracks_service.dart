import 'package:hive_flutter/hive_flutter.dart';
import '../models/liked_track.dart';
import 'api_client.dart';

class LikedTracksService {
  static const String _boxName = 'liked_tracks';
  static Box? _box;
  static const Duration _guestExpiration = Duration(days: 7);

  static Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
      // Cleanup expired tracks on init
      await clearExpiredTracks();
    } catch (e) {
      // Box might already be open
      _box = Hive.box(_boxName);
    }
  }

  static Future<void> saveLikedTrack(LikedTrack track, {bool isGuest = false}) async {
    if (_box == null) await init();

    // For guest users, add expiration date
    final trackToSave = isGuest
        ? track.copyWith(
            expiresAt: DateTime.now().add(_guestExpiration),
          )
        : track;

    await _box!.put(track.id, trackToSave.toJson());

    // For authenticated users, also save to Supabase
    if (!isGuest) {
      try {
        // This will be called from provider with API client
        // For now, just save locally
      } catch (e) {
        // If API call fails, track is still saved locally
      }
    }
  }

  static Future<void> saveLikedTrackToApi(LikedTrack track, ApiClient apiClient) async {
    try {
      await apiClient.saveLikedTrack(
        trackId: track.spotifyId ?? track.id,
        trackName: track.name,
        artistName: track.artist,
        albumArtUrl: track.albumArt,
        previewUrl: track.previewUrl,
      );
    } catch (e) {
      // API call failed, but track is saved locally
      rethrow;
    }
  }

  static Future<void> removeLikedTrack(String id, {bool isGuest = false}) async {
    if (_box == null) await init();

    await _box!.delete(id);

    // For authenticated users, also remove from Supabase
    if (!isGuest) {
      try {
        // This will be called from provider with API client
      } catch (e) {
        // If API call fails, track is still removed locally
      }
    }
  }

  static Future<void> removeLikedTrackFromApi(String id, ApiClient apiClient) async {
    try {
      await apiClient.deleteLikedTrack(id);
    } catch (e) {
      // API call failed, but track is removed locally
      rethrow;
    }
  }

  static Future<List<LikedTrack>> getAllLikedTracks({bool isGuest = false}) async {
    if (_box == null) await init();

    final tracks = <LikedTrack>[];
    for (var key in _box!.keys) {
      try {
        final json = _box!.get(key);
        if (json != null) {
          final track = LikedTrack.fromJson(Map<String, dynamic>.from(json));
          if (!track.isExpired) {
            tracks.add(track);
          } else {
            // Remove expired track
            await _box!.delete(key);
          }
        }
      } catch (e) {
        // Skip invalid entries
        continue;
      }
    }

    // Sort by likedAt (newest first)
    tracks.sort((a, b) => b.likedAt.compareTo(a.likedAt));

    return tracks;
  }

  static Future<List<LikedTrack>> getLikedTracksFromApi(ApiClient apiClient) async {
    try {
      final tracks = await apiClient.getLikedTracks();
      return tracks.map((json) => LikedTrack.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> clearExpiredTracks() async {
    if (_box == null) await init();

    final keysToDelete = <dynamic>[];
    for (var key in _box!.keys) {
      try {
        final json = _box!.get(key);
        if (json != null) {
          final track = LikedTrack.fromJson(Map<String, dynamic>.from(json));
          if (track.isExpired) {
            keysToDelete.add(key);
          }
        }
      } catch (e) {
        // Remove invalid entries
        keysToDelete.add(key);
      }
    }

    for (var key in keysToDelete) {
      await _box!.delete(key);
    }
  }

  static Future<void> clearAllTracks() async {
    if (_box == null) await init();
    await _box!.clear();
  }

  static Future<List<LikedTrack>> mergeLocalAndRemote({
    required List<LikedTrack> localTracks,
    required List<LikedTrack> remoteTracks,
  }) async {
    // Create a map of remote tracks by spotifyId or id
    final remoteMap = <String, LikedTrack>{};
    for (var track in remoteTracks) {
      final key = track.spotifyId ?? track.id;
      remoteMap[key] = track;
    }

    // Merge: prefer remote tracks, add local-only tracks
    final merged = <LikedTrack>[];
    final seenIds = <String>{};

    // Add remote tracks first
    for (var track in remoteTracks) {
      final key = track.spotifyId ?? track.id;
      if (!seenIds.contains(key)) {
        merged.add(track);
        seenIds.add(key);
      }
    }

    // Add local tracks that aren't in remote
    for (var track in localTracks) {
      final key = track.spotifyId ?? track.id;
      if (!seenIds.contains(key)) {
        merged.add(track);
        seenIds.add(key);
      }
    }

    // Save merged list back to local storage
    if (_box == null) await init();
    await _box!.clear();
    for (var track in merged) {
      await _box!.put(track.id, track.toJson());
    }

    return merged;
  }

  static int get count {
    if (_box == null) return 0;
    return _box!.length;
  }
}

