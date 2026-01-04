import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/taste_profile.dart';
import '../models/analysis.dart';
import '../services/taste_profile_service.dart';

final tasteProfileProvider = StateNotifierProvider<TasteProfileNotifier, AsyncValue<TasteProfile>>((ref) {
  return TasteProfileNotifier(ref);
});

class TasteProfileNotifier extends StateNotifier<AsyncValue<TasteProfile>> {
  TasteProfileNotifier(Ref ref) : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await TasteProfileService.getProfile();
      state = AsyncValue.data(profile);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateFromAnalysis(PlaylistAnalysis analysis) async {
    try {
      await TasteProfileService.updateProfileFromAnalysis(analysis);
      await _loadProfile();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> recalculate(List<PlaylistAnalysis> analyses) async {
    try {
      await TasteProfileService.recalculateProfile(analyses);
      await _loadProfile();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> clear() async {
    try {
      await TasteProfileService.clearProfile();
      await _loadProfile();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadProfile();
  }
}

