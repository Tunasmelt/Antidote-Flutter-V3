import 'package:hive_flutter/hive_flutter.dart';
import 'liked_tracks_service.dart';
import '../models/liked_track.dart';
import '../models/taste_profile.dart';

class GuestStorageService {
  static const Duration _guestExpiration = Duration(days: 7);
  static const String _guestDataKey = 'guest_data';
  static Box? _box;

  static Future<void> init() async {
    try {
      _box = await Hive.openBox('guest_storage');
      // Cleanup expired guest data on init
      await _cleanupExpiredData();
    } catch (e) {
      // Box might already be open
      _box = Hive.box('guest_storage');
    }
  }

  static Future<void> _cleanupExpiredData() async {
    if (_box == null) await init();

    try {
      final guestData = _box!.get(_guestDataKey);
      if (guestData != null) {
        final data = Map<String, dynamic>.from(guestData);
        final createdAt = data['createdAt'] != null
            ? DateTime.parse(data['createdAt'])
            : null;

        if (createdAt != null) {
          final age = DateTime.now().difference(createdAt);
          if (age > _guestExpiration) {
            // Expired - clear all guest data
            await clearAllGuestData();
          }
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  static Future<void> saveGuestData({
    List<LikedTrack>? likedTracks,
    TasteProfile? tasteProfile,
  }) async {
    if (_box == null) await init();

    final data = {
      'createdAt': DateTime.now().toIso8601String(),
      if (likedTracks != null)
        'likedTracks': likedTracks.map((t) => t.toJson()).toList(),
      if (tasteProfile != null) 'tasteProfile': tasteProfile.toJson(),
    };

    await _box!.put(_guestDataKey, data);
  }

  static Future<Map<String, dynamic>> getGuestData() async {
    if (_box == null) await init();

    try {
      final data = _box!.get(_guestDataKey);
      if (data != null) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      // Return empty data
    }

    return {
      'createdAt': DateTime.now().toIso8601String(),
      'likedTracks': <Map<String, dynamic>>[],
      'tasteProfile': null,
    };
  }

  static Future<bool> hasGuestData() async {
    if (_box == null) await init();

    try {
      final data = await getGuestData();
      final likedTracks = data['likedTracks'] as List?;
      return likedTracks != null && likedTracks.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<List<LikedTrack>> getLikedTracks() async {
    if (_box == null) await init();

    try {
      final data = await getGuestData();
      final likedTracksJson = data['likedTracks'] as List?;
      if (likedTracksJson != null) {
        return likedTracksJson
            .map((json) => LikedTrack.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
    } catch (e) {
      // Return empty list
    }

    return [];
  }

  static Future<Map<String, dynamic>> migrateGuestDataToUser() async {
    if (_box == null) await init();

    try {
      final guestData = await getGuestData();
      int itemsMigrated = 0;

      // Migrate liked tracks
      if (guestData['likedTracks'] != null) {
        final likedTracks = (guestData['likedTracks'] as List)
            .map((json) => LikedTrack.fromJson(Map<String, dynamic>.from(json)))
            .toList();

        // Save each track (will be synced to Supabase via provider)
        for (var track in likedTracks) {
          await LikedTracksService.saveLikedTrack(track, isGuest: false);
          itemsMigrated++;
        }
      }

      // Migrate taste profile
      // Taste profile is already stored locally, no migration needed
      // Just ensure it's not expired

      // Clear guest data after migration
      await clearAllGuestData();

      return {
        'success': true,
        'itemsMigrated': itemsMigrated,
      };
    } catch (e) {
      // Migration failed
      return {
        'success': false,
        'error': e.toString(),
        'itemsMigrated': 0,
      };
    }
  }

  static Future<void> clearAllGuestData() async {
    if (_box == null) await init();

    await _box!.clear();

    // Also clear liked tracks and taste profile boxes if they're guest-only
    // (This is handled by the individual services)
  }

  static bool isGuestDataExpired() {
    if (_box == null) return false;

    try {
      final guestData = _box!.get(_guestDataKey);
      if (guestData != null) {
        final data = Map<String, dynamic>.from(guestData);
        final createdAt = data['createdAt'] != null
            ? DateTime.parse(data['createdAt'])
            : null;

        if (createdAt != null) {
          final age = DateTime.now().difference(createdAt);
          return age > _guestExpiration;
        }
      }
    } catch (e) {
      // Return false on error
    }

    return false;
  }
}
