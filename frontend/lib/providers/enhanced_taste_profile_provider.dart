import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_client_provider.dart';
import '../services/logger_service.dart';

final enhancedTasteProfileProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final profile = await apiClient.getEnhancedTasteProfile();
    return profile;
  } catch (e, stackTrace) {
    // Log the error for debugging
    LoggerService.error('Failed to fetch enhanced taste profile',
        error: e, stackTrace: stackTrace);
    // Return null on error - UI will handle gracefully
    return null;
  }
});
