import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analysis.dart';
import 'api_client_provider.dart';

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
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

