import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/env_config.dart';
import 'services/cache_service.dart';
import 'services/liked_tracks_service.dart';
import 'services/taste_profile_service.dart';
import 'services/guest_storage_service.dart';
import 'services/spotify_auth_service.dart';
import 'services/auth_service.dart';
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
import 'screens/liked_tracks_screen.dart';
import 'screens/mood_discovery_screen.dart';
import 'screens/playlist_generator_screen.dart';
import 'screens/discovery_timeline_screen.dart';
import 'screens/top_tracks_screen.dart';
import 'screens/top_artists_screen.dart';
import 'screens/recently_played_screen.dart';
import 'screens/saved_tracks_screen.dart';
import 'screens/saved_albums_screen.dart';
import 'screens/not_found_screen.dart';
import 'widgets/mobile_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent status bar
      statusBarIconBrightness: Brightness.light, // Light icons for dark background
      statusBarBrightness: Brightness.dark, // Dark for iOS
      systemNavigationBarColor: Colors.transparent, // Transparent navigation bar
      systemNavigationBarIconBrightness: Brightness.light, // Light icons
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  
  // Set preferred orientations (optional - allow all orientations)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Load environment configuration
  await EnvConfig.load();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: EnvConfig.supabaseUrl,
    anonKey: EnvConfig.supabaseAnonKey,
  );
  
  // Initialize cache service
  await CacheService.init();
  
  // Initialize liked tracks service
  await LikedTracksService.init();
  
  // Initialize taste profile service
  await TasteProfileService.init();
  
  // Initialize guest storage service
  await GuestStorageService.init();
  
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
        return MobileLayout(showBottomNavigation: false, child: AnalysisScreen(playlistUrl: url));
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
      builder: (context, state) => const MobileLayout(showBottomNavigation: false, child: MusicAssistantScreen()),
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
              showBottomNavigation: false,
              child: RecommendationsScreen(
                strategyId: strategyId,
                strategyTitle: strategyTitle,
                strategyColor: strategyColor,
              ),
            );
          },
        ),
        GoRoute(
          path: '/mood-discovery',
          builder: (context, state) => const MobileLayout(showBottomNavigation: false, child: MoodDiscoveryScreen()),
        ),
        GoRoute(
          path: '/playlist-generator',
          builder: (context, state) => const MobileLayout(showBottomNavigation: false, child: PlaylistGeneratorScreen()),
        ),
        GoRoute(
          path: '/discovery-timeline',
          builder: (context, state) => const MobileLayout(showBottomNavigation: false, child: DiscoveryTimelineScreen()),
        ),
        GoRoute(
          path: '/top-tracks',
          builder: (context, state) => const MobileLayout(showBottomNavigation: false, child: TopTracksScreen()),
        ),
        GoRoute(
          path: '/top-artists',
          builder: (context, state) => const MobileLayout(showBottomNavigation: false, child: TopArtistsScreen()),
        ),
        GoRoute(
          path: '/recently-played',
          builder: (context, state) => const MobileLayout(showBottomNavigation: false, child: RecentlyPlayedScreen()),
        ),
        GoRoute(
          path: '/saved-tracks',
          builder: (context, state) => const MobileLayout(showBottomNavigation: false, child: SavedTracksScreen()),
        ),
        GoRoute(
          path: '/saved-albums',
          builder: (context, state) => const MobileLayout(showBottomNavigation: false, child: SavedAlbumsScreen()),
        ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const MobileLayout(showBottomNavigation: false, child: AuthScreen()),
    ),
    GoRoute(
      path: '/auth/callback',
      builder: (context, state) {
        // Handle OAuth callback
        final code = state.uri.queryParameters['code'];
        final error = state.uri.queryParameters['error'];
        
        if (error != null) {
          // OAuth error - redirect to auth screen with error
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Spotify authentication failed: $error'),
                backgroundColor: Colors.redAccent,
              ),
            );
            context.go('/auth');
          });
          return const MobileLayout(showBottomNavigation: false, child: AuthScreen());
        }
        
        if (code != null) {
          // Exchange code for tokens and get user info
          final spotifyAuth = SpotifyAuthService();
          final authService = AuthService();
          
          spotifyAuth.handleOAuthCallback(code).then((result) async {
            try {
              // Extract tokens and user info
              final accessToken = result['access_token'] as String;
              final refreshToken = result['refresh_token'] as String?;
              final spotifyUser = result['user'] as Map<String, dynamic>;
              
              // Check if user is already authenticated (Supabase session exists)
              final isAuthenticated = _isAuthenticated();
              
              if (isAuthenticated) {
                // Scenario A: User is authenticated - just connect Spotify tokens
                // Tokens are already stored by handleOAuthCallback
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Spotify connected successfully!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                  context.go('/');
                }
              } else {
                // Scenario B: User is not authenticated - create Supabase user
                await authService.signInWithSpotifyUser(
                  spotifyUser: spotifyUser,
                  accessToken: accessToken,
                  refreshToken: refreshToken,
                );
                
                // Success - show message and navigate to home
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Successfully signed in with Spotify!'),
                      backgroundColor: AppTheme.success,
                    ),
                  );
                  context.go('/');
                }
              }
            } catch (e) {
              // Error creating Supabase session or connecting Spotify
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to complete sign in: ${e.toString()}'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                context.go('/auth');
              }
            }
          }).catchError((e) {
            // Error during OAuth callback
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Spotify authentication failed: ${e.toString()}'),
                  backgroundColor: Colors.redAccent,
                ),
              );
              context.go('/auth');
            }
          });
        }
        
        // Show loading screen while processing
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const MobileLayout(showBottomNavigation: false, child: HistoryScreen()),
    ),
    GoRoute(
      path: '/saved-playlists',
      builder: (context, state) => const MobileLayout(showBottomNavigation: false, child: SavedPlaylistsScreen()),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const MobileLayout(showBottomNavigation: false, child: SettingsScreen()),
    ),
    GoRoute(
      path: '/liked-tracks',
      builder: (context, state) => const MobileLayout(showBottomNavigation: false, child: LikedTracksScreen()),
    ),
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
);

// Check if route requires Supabase authentication
// Note: /music-assistant and /recommendations require Spotify token, not Supabase auth
bool _isProtectedRoute(String path) {
  const protectedRoutes = [
    '/profile',
    '/history',
    '/saved-playlists',
    '/settings',
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
