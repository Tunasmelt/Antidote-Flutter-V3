import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client_provider.dart';

final enhancedTasteProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final profile = await apiClient.getEnhancedTasteProfile();
    return profile;
  } catch (e) {
    // Return null on error - UI will handle gracefully
    return null;
  }
});

