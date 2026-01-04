import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/liked_track.dart';
import '../services/liked_tracks_service.dart';
import 'api_client_provider.dart';
import 'auth_provider.dart';

final likedTracksServiceProvider = Provider<LikedTracksService>((ref) {
  return LikedTracksService();
});

final likedTracksProvider = StateNotifierProvider<LikedTracksNotifier, AsyncValue<List<LikedTrack>>>((ref) {
  return LikedTracksNotifier(ref);
});

class LikedTracksNotifier extends StateNotifier<AsyncValue<List<LikedTrack>>> {
  final Ref _ref;

  LikedTracksNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    try {
      final isAuthenticated = _ref.read(isAuthenticatedProvider);
      final apiClient = _ref.read(apiClientProvider);

      // Get local tracks
      final localTracks = await LikedTracksService.getAllLikedTracks(
        isGuest: !isAuthenticated,
      );

      if (isAuthenticated) {
        // Get remote tracks and merge
        try {
          final remoteTracks = await LikedTracksService.getLikedTracksFromApi(apiClient);
          final mergedTracks = await LikedTracksService.mergeLocalAndRemote(
            localTracks: localTracks,
            remoteTracks: remoteTracks,
          );
          state = AsyncValue.data(mergedTracks);
        } catch (e) {
          // If API fails, use local tracks
          state = AsyncValue.data(localTracks);
        }
      } else {
        // Guest user - only local tracks
        state = AsyncValue.data(localTracks);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addLikedTrack(LikedTrack track) async {
    try {
      final isAuthenticated = _ref.read(isAuthenticatedProvider);
      final apiClient = _ref.read(apiClientProvider);

      // Save locally
      await LikedTracksService.saveLikedTrack(
        track,
        isGuest: !isAuthenticated,
      );

      // Save to API if authenticated
      if (isAuthenticated) {
        try {
          await LikedTracksService.saveLikedTrackToApi(track, apiClient);
        } catch (e) {
          // Track is saved locally even if API fails
        }
      }

      // Reload tracks
      await _loadTracks();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> removeLikedTrack(String id) async {
    try {
      final isAuthenticated = _ref.read(isAuthenticatedProvider);
      final apiClient = _ref.read(apiClientProvider);

      // Remove locally
      await LikedTracksService.removeLikedTrack(
        id,
        isGuest: !isAuthenticated,
      );

      // Remove from API if authenticated
      if (isAuthenticated) {
        try {
          await LikedTracksService.removeLikedTrackFromApi(id, apiClient);
        } catch (e) {
          // Track is removed locally even if API fails
        }
      }

      // Reload tracks
      await _loadTracks();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadTracks();
  }

  Future<void> clearAll() async {
    await LikedTracksService.clearAllTracks();
    state = const AsyncValue.data([]);
  }
}

