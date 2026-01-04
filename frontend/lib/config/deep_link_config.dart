import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home_screen.dart';
import '../screens/analysis_screen.dart';
import '../screens/battle_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/history_screen.dart';
import '../screens/liked_tracks_screen.dart';
import '../screens/recommendations_screen.dart';

/// Deep linking configuration for the app
/// Supports URLs like:
/// - antidote://analysis?url=<playlist_url>
/// - antidote://battle?url1=<url1>&url2=<url2>
/// - antidote://share/<analysis_id>
class DeepLinkConfig {
  static const String scheme = 'antidote';
  static const String host = 'app';

  /// Create GoRouter with deep linking support
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/auth',
          builder: (context, state) => const AuthScreen(),
        ),
        GoRoute(
          path: '/analysis',
          builder: (context, state) {
            final url = state.uri.queryParameters['url'];
            return AnalysisScreen(playlistUrl: url);
          },
        ),
        GoRoute(
          path: '/battle',
          builder: (context, state) => const BattleScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/liked-tracks',
          builder: (context, state) => const LikedTracksScreen(),
        ),
        GoRoute(
          path: '/recommendations',
          builder: (context, state) {
            final strategyId =
                state.uri.queryParameters['strategyId'] ?? 'best_next';
            final strategyTitle =
                state.uri.queryParameters['strategyTitle'] ?? 'Recommendations';
            final strategyColorValue =
                int.tryParse(state.uri.queryParameters['strategyColor'] ?? '0');
            final strategyColor = strategyColorValue != null
                ? Color(strategyColorValue)
                : const Color(0xFFE91E63);
            return RecommendationsScreen(
              strategyId: strategyId,
              strategyTitle: strategyTitle,
              strategyColor: strategyColor,
            );
          },
        ),
        // Deep link routes
        GoRoute(
          path: '/share/:id',
          builder: (context, state) {
            final analysisId = state.pathParameters['id'];
            // Navigate to analysis view with shared ID
            return AnalysisScreen(playlistUrl: 'shared:$analysisId');
          },
        ),
      ],
      // Handle unknown routes
      errorBuilder: (context, state) => const HomeScreen(),
    );
  }

  /// Generate shareable deep link for analysis
  static String generateAnalysisLink(String analysisId) {
    return '$scheme://$host/share/$analysisId';
  }

  /// Generate shareable deep link for battle
  static String generateBattleLink(String battleId) {
    return '$scheme://$host/battle/$battleId';
  }

  /// Parse deep link URL
  static Map<String, dynamic>? parseDeepLink(Uri uri) {
    if (uri.scheme != scheme) return null;

    final pathSegments = uri.pathSegments;
    if (pathSegments.isEmpty) return null;

    final action = pathSegments[0];
    final params = Map<String, dynamic>.from(uri.queryParameters);

    return {
      'action': action,
      'params': params,
      'pathSegments': pathSegments,
    };
  }
}
