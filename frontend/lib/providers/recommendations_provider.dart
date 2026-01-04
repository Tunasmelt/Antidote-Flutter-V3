import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/liked_track.dart';
import 'api_client_provider.dart';
import 'liked_tracks_provider.dart';

final recommendationsProvider = StateNotifierProvider.family<RecommendationsNotifier, AsyncValue<List<Map<String, dynamic>>>, String>((ref, strategyId) {
  return RecommendationsNotifier(ref, strategyId);
});

class RecommendationsNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref _ref;
  final String strategyId;
  int _currentIndex = 0;

  RecommendationsNotifier(this._ref, this.strategyId) : super(const AsyncValue.loading()) {
    _loadRecommendations();
  }

  int get currentIndex => _currentIndex;
  int get totalCount => state.value?.length ?? 0;
  bool get hasMore => _currentIndex < totalCount - 1;
  bool get hasPrevious => _currentIndex > 0;

  Map<String, dynamic>? get currentTrack {
    if (state.value == null || _currentIndex >= state.value!.length) {
      return null;
    }
    return state.value![_currentIndex];
  }

  /// Map frontend strategy ID to backend strategy type
  String _mapStrategyIdToType(String id) {
    final mapping = {
      'best_next_track': 'best_next',
      'mood_safe_pick': 'mood_safe',
      'rare_match': 'rare_match',
      'return_to_familiar': 'return_familiar',
      'short_session': 'short_session',
      'energy_adjustment': 'energy_adjust',
      'best_5_tracks': 'best_next', // Fallback to best_next
      'professional_discovery': 'professional_discovery',
      'taste_expansion': 'taste_expansion',
      'deep_cuts': 'deep_cuts',
      'continue_session': 'continue_session',
      'from_library': 'from_library',
    };
    return mapping[id] ?? id; // Return mapped value or original if not found
  }

  Future<void> _loadRecommendations() async {
    state = const AsyncValue.loading();
    try {
      final apiClient = _ref.read(apiClientProvider);
      final backendType = _mapStrategyIdToType(strategyId);
      final recommendations = await apiClient.getRecommendations(
        type: backendType,
      );
      state = AsyncValue.data(recommendations);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> likeTrack() async {
    final track = currentTrack;
    if (track == null) return;

    try {
      // Create LikedTrack from recommendation
      final likedTrack = LikedTrack(
        id: track['id'] ?? track['spotify_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: track['name'] ?? track['title'] ?? 'Unknown',
        artist: _extractArtist(track),
        albumArt: track['albumArt'] ?? 
            track['album_art'] ?? 
            _extractAlbumArt(track),
        previewUrl: track['preview_url'] ?? track['previewUrl'],
        spotifyId: track['id'] ?? track['spotify_id'],
        likedAt: DateTime.now(),
      );

      // Save to liked tracks
      await _ref.read(likedTracksProvider.notifier).addLikedTrack(likedTrack);

      // Move to next track
      nextTrack();
    } catch (e) {
      // Error saving, but continue anyway
      nextTrack();
    }
  }

  void dislikeTrack() {
    // Just move to next track
    nextTrack();
  }

  void nextTrack() {
    if (hasMore) {
      _currentIndex++;
    }
  }

  void previousTrack() {
    if (hasPrevious) {
      _currentIndex--;
    }
  }

  void goToTrack(int index) {
    if (index >= 0 && index < totalCount) {
      _currentIndex = index;
    }
  }

  String _extractArtist(Map<String, dynamic> track) {
    if (track['artist'] != null) {
      return track['artist'].toString();
    }
    if (track['artists'] is List && (track['artists'] as List).isNotEmpty) {
      final artistsList = track['artists'] as List;
      if (artistsList[0] is Map && artistsList[0]['name'] != null) {
        return artistsList[0]['name'].toString();
      }
      return artistsList[0].toString();
    }
    return 'Unknown Artist';
  }

  String? _extractAlbumArt(Map<String, dynamic> track) {
    if (track['albumArt'] != null) return track['albumArt'].toString();
    if (track['album_art'] != null) return track['album_art'].toString();
    if (track['album'] is Map && track['album']['images'] is List && (track['album']['images'] as List).isNotEmpty) {
      return (track['album']['images'] as List)[0]['url'];
    }
    if (track['images'] is List && (track['images'] as List).isNotEmpty) {
      return (track['images'] as List)[0]['url'];
    }
    return track['image']?.toString();
  }

  Future<void> refresh() async {
    _currentIndex = 0;
    await _loadRecommendations();
  }
}

