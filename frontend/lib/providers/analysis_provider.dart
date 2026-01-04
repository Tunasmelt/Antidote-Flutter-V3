import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis.dart';
import 'api_client_provider.dart';
import 'taste_profile_provider.dart';

final analysisNotifierProvider = StateNotifierProvider<AnalysisNotifier, AsyncValue<PlaylistAnalysis?>>((ref) {
  return AnalysisNotifier(ref);
});

class AnalysisNotifier extends StateNotifier<AsyncValue<PlaylistAnalysis?>> {
  final Ref _ref;

  AnalysisNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> analyzePlaylist(String url) async {
    if (url.isEmpty) {
      state = AsyncValue.error('No URL provided', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final apiClient = _ref.read(apiClientProvider);
      final result = await apiClient.analyzePlaylist(url);
      state = AsyncValue.data(result);
      
      // Update taste profile automatically
      try {
        await _ref.read(tasteProfileProvider.notifier).updateFromAnalysis(result);
      } catch (e) {
        // Silently fail - taste profile update is not critical
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

