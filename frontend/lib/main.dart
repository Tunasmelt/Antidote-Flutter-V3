import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env_config.dart';
import 'services/cache_service.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/battle_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/music_assistant_screen.dart';
import 'screens/recommendations_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/history_screen.dart';
import 'screens/saved_playlists_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/not_found_screen.dart';
import 'widgets/mobile_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment configuration
  await EnvConfig.load();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );
  
  // Initialize cache service
  await CacheService.init();
  
  // Validate environment
  EnvConfig.validate();
  
  runApp(const ProviderScope(child: AntidoteApp()));
}

class AntidoteApp extends StatelessWidget {
  const AntidoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Antidote v3',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: _router,
    );
  }
}

// Helper function to check authentication
bool _isAuthenticated() {
  return Supabase.instance.client.auth.currentSession != null;
}

final GoRouter _router = GoRouter(
  redirect: (context, state) {
    final isAuth = _isAuthenticated();
    final isAuthRoute = state.matchedLocation == '/auth';
    
    // If not authenticated and trying to access protected route, redirect to auth
    if (!isAuth && !isAuthRoute && _isProtectedRoute(state.matchedLocation)) {
      return '/auth';
    }
    
    // If authenticated and on auth page, redirect to home
    if (isAuth && isAuthRoute) {
      return '/';
    }
    
    return null; // No redirect needed
  },
  refreshListenable: _AuthStateNotifier(),
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MobileLayout(child: HomeScreen()),
    ),
    GoRoute(
      path: '/analysis',
      builder: (context, state) {
        final url = state.uri.queryParameters['url'];
        return MobileLayout(child: AnalysisScreen(playlistUrl: url));
      },
    ),
    GoRoute(
      path: '/battle',
      builder: (context, state) => const MobileLayout(child: BattleScreen()),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const MobileLayout(child: ProfileScreen()),
    ),
    GoRoute(
      path: '/music-assistant',
      builder: (context, state) => const MobileLayout(child: MusicAssistantScreen()),
    ),
    GoRoute(
      path: '/recommendations',
      builder: (context, state) {
        final strategyId = state.uri.queryParameters['strategyId'] ?? '';
        final strategyTitle = state.uri.queryParameters['strategyTitle'] ?? 'Recommendations';
        final strategyColorValue = int.tryParse(state.uri.queryParameters['strategyColor'] ?? '0');
        final strategyColor = strategyColorValue != null 
            ? Color(strategyColorValue) 
            : AppTheme.primary;
        return MobileLayout(
          child: RecommendationsScreen(
            strategyId: strategyId,
            strategyTitle: strategyTitle,
            strategyColor: strategyColor,
          ),
        );
      },
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const MobileLayout(child: AuthScreen()),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const MobileLayout(child: HistoryScreen()),
    ),
    GoRoute(
      path: '/saved-playlists',
      builder: (context, state) => const MobileLayout(child: SavedPlaylistsScreen()),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const MobileLayout(child: SettingsScreen()),
    ),
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
);

// Check if route requires authentication
bool _isProtectedRoute(String path) {
  const protectedRoutes = [
    '/profile',
    '/history',
    '/saved-playlists',
    '/settings',
    '/music-assistant', // Requires Spotify for recommendations
    '/recommendations', // Requires Spotify for recommendations
  ];
  return protectedRoutes.contains(path);
}

// Auth state notifier for router refresh
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
}
