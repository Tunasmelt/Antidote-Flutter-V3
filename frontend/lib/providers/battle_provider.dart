import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/battle.dart';
import 'api_client_provider.dart';

final battleNotifierProvider = StateNotifierProvider<BattleNotifier, AsyncValue<BattleResult?>>((ref) {
  return BattleNotifier(ref);
});

class BattleNotifier extends StateNotifier<AsyncValue<BattleResult?>> {
  final Ref _ref;

  BattleNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> battlePlaylists(String url1, String url2) async {
    if (url1.isEmpty || url2.isEmpty) {
      state = AsyncValue.error('Both playlist URLs are required', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final apiClient = _ref.read(apiClientProvider);
      final result = await apiClient.battlePlaylists(url1, url2);
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

