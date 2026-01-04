import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import '../models/user.dart' as app_models;
import '../config/env_config.dart';
import 'spotify_auth_service.dart';
import 'guest_storage_service.dart';
import 'logger_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final SupabaseClient _supabase;

  // Lazy getter to avoid circular dependency
  SpotifyAuthService? _spotifyAuthInstance;
  SpotifyAuthService get _spotifyAuth {
    _spotifyAuthInstance ??= SpotifyAuthService();
    return _spotifyAuthInstance!;
  }

  AuthService() : _supabase = Supabase.instance.client;

  // Email/Password Authentication using backend proxy
  Future<app_models.User?> signInWithEmail(
      String email, String password) async {
    try {
      // Use backend proxy instead of direct Supabase call
      final dio = Dio();
      final response = await dio.post(
        '${EnvConfig.apiBaseUrl}/api/auth/signin',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final sessionData = data['session'] as Map<String, dynamic>;

        // Set the session in Supabase client using the token from backend
        await _supabase.auth.setSession(sessionData['access_token'] as String);

        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null) {
          final user = await _createOrUpdateUserProfile(currentUser);
          // Migrate guest data to user account
          try {
            final migrationResult =
                await GuestStorageService.migrateGuestDataToUser();
            // Store migration success in user metadata for UI to show notification
            if (migrationResult['success'] == true &&
                migrationResult['itemsMigrated'] > 0) {
              // Successfully migrated guest data
              LoggerService.logMigration(
                itemsMigrated: migrationResult['itemsMigrated'] as int,
              );
            }
          } catch (e) {
            // Migration failed silently - user can still sign in
            LoggerService.logMigrationError(e);
          }
          return user;
        }
      }
      return null;
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['error'] ?? 'Sign in failed';
      throw AuthException('Sign in failed: $errorMessage');
    } catch (e) {
      throw AuthException('Sign in failed: ${e.toString()}');
    }
  }

  Future<app_models.User?> signUpWithEmail(
      String email, String password) async {
    try {
      // Use backend proxy instead of direct Supabase call
      final dio = Dio();
      final response = await dio.post(
        '${EnvConfig.apiBaseUrl}/api/auth/signup',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final sessionData = data['session'] as Map<String, dynamic>;

        // Set the session in Supabase client using the token from backend
        await _supabase.auth.setSession(sessionData['access_token'] as String);

        final currentUser = _supabase.auth.currentUser;
        if (currentUser != null) {
          final user = await _createOrUpdateUserProfile(currentUser);
          // Migrate guest data to user account
          try {
            final migrationResult =
                await GuestStorageService.migrateGuestDataToUser();
            // Successfully migrated guest data if any
            if (migrationResult['success'] == true &&
                migrationResult['itemsMigrated'] > 0) {
              // Successfully migrated guest data
              LoggerService.logMigration(
                itemsMigrated: migrationResult['itemsMigrated'] as int,
              );
            }
          } catch (e) {
            // Migration failed silently - user can still sign up
            LoggerService.logMigrationError(e);
          }
          return user;
        }
      }
      return null;
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['error'] ?? 'Sign up failed';
      throw AuthException('Sign up failed: $errorMessage');
    } catch (e) {
      throw AuthException('Sign up failed: ${e.toString()}');
    }
  }

  // Spotify OAuth
  Future<void> signInWithSpotify({bool useDirectOAuth = true}) async {
    try {
      if (useDirectOAuth) {
        // Use direct Spotify OAuth flow (recommended for local dev)
        await _spotifyAuth.connectSpotify(useDirectOAuth: true);
      } else {
        // Fallback to Supabase OAuth
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.spotify,
          redirectTo: EnvConfig.spotifyRedirectUri,
          authScreenLaunchMode: LaunchMode.externalApplication,
          scopes:
              'user-read-private user-read-email playlist-read-private playlist-read-collaborative user-library-read user-top-read user-read-recently-played',
        );
        // After OAuth completes, tokens will be available via SpotifyAuthService
        // The SpotifyAuthService will extract tokens from the Supabase session
      }
    } catch (e) {
      throw AuthException('Spotify authentication failed: ${e.toString()}');
    }
  }

  /// Sign in/create Supabase user from Spotify OAuth
  /// This is called after Spotify OAuth completes
  Future<app_models.User?> signInWithSpotifyUser({
    required Map<String, dynamic> spotifyUser,
    required String accessToken,
    String? refreshToken,
  }) async {
    try {
      // Call backend to create/sign in Supabase user
      final dio = Dio();
      dio.options.baseUrl = EnvConfig.apiBaseUrl;
      final response = await dio.post(
        '/api/auth/spotify-signin',
        data: {
          'spotifyUser': spotifyUser,
          'accessToken': accessToken,
          'refreshToken': refreshToken,
        },
      );

      final userId = response.data['userId'] as String;
      final email = response.data['email'] as String;
      final displayName = response.data['displayName'] as String;
      final magicLink = response.data['magicLink'] as String?;

      // Use magic link to sign in to Supabase
      // Extract token from magic link if available
      if (magicLink != null) {
        try {
          // Parse the magic link to extract the token
          final uri = Uri.parse(magicLink);
          final token = uri.queryParameters['token'] ??
              (uri.fragment.contains('access_token=')
                  ? uri.fragment.split('access_token=')[1].split('&')[0]
                  : null);

          if (token != null && token.isNotEmpty) {
            // Set session using the token
            await _supabase.auth.setSession(token);
          }
        } catch (e) {
          // If magic link parsing fails, try to sign in with email
          // Since backend created user with random password, we need a different approach
          // For now, we'll use the user ID to verify the session was created
        }
      }

      // Verify session was created
      final session = _supabase.auth.currentSession;
      if (session == null) {
        // If no session, try to get user by ID
        // This is a fallback - ideally the magic link should work
        return app_models.User(
          id: userId,
          username: displayName,
          email: email,
          avatarUrl: null,
          spotifyId: spotifyUser['id'] as String?,
        );
      }

      // Create or update user profile
      final user = await _createOrUpdateUserProfile(session.user);
      // Migrate guest data to user account
      try {
        final migrationResult =
            await GuestStorageService.migrateGuestDataToUser();
        if (migrationResult['success'] == true &&
            migrationResult['itemsMigrated'] > 0) {
          // Successfully migrated guest data
          LoggerService.logMigration(
            itemsMigrated: migrationResult['itemsMigrated'] as int,
          );
        }
      } catch (e) {
        // Migration failed silently - user can still sign in
        LoggerService.logMigrationError(e);
      }
      return user;
    } catch (e) {
      throw AuthException(
          'Failed to sign in with Spotify user: ${e.toString()}');
    }
  }

  // Get Spotify access token for API requests
  Future<String?> getSpotifyAccessToken() async {
    try {
      return await _spotifyAuth.getSpotifyAccessToken();
    } catch (e) {
      return null;
    }
  }

  // Check if Spotify is connected
  Future<bool> isSpotifyConnected() async {
    try {
      return await _spotifyAuth.isSpotifyConnected();
    } catch (e) {
      return false;
    }
  }

  // Refresh Spotify token
  Future<String?> refreshSpotifyToken() async {
    try {
      return await _spotifyAuth.refreshSpotifyToken();
    } catch (e) {
      return null;
    }
  }

  // Connect Spotify (alias for signInWithSpotify)
  Future<void> connectSpotify() async {
    await signInWithSpotify();
  }

  // Disconnect Spotify
  Future<void> disconnectSpotify() async {
    try {
      await _spotifyAuth.disconnectSpotify();
    } catch (e) {
      // Ignore errors
    }
  }

  // Reset password (forgot password)
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo:
            '${EnvConfig.spotifyRedirectUri.split('://')[0]}://reset-password',
      );
    } catch (e) {
      throw AuthException('Password reset failed: ${e.toString()}');
    }
  }

  // Sign out
  // Note: Spotify tokens are NOT cleared on sign out to allow token persistence
  // When user logs back in, tokens will be automatically restored if valid
  Future<void> signOut() async {
    try {
      // Only sign out from Supabase - do NOT clear Spotify tokens
      // This allows users to avoid re-authenticating with Spotify when logging back in
      await _supabase.auth.signOut();
    } catch (e) {
      throw AuthException('Sign out failed: ${e.toString()}');
    }
  }

  // Get current user
  Future<app_models.User?> getCurrentUser() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session?.user != null) {
        return await _createOrUpdateUserProfile(session!.user);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Stream authentication state changes
  Stream<app_models.User?> authStateChanges() {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      if (event.event == AuthChangeEvent.signedIn &&
          event.session?.user != null) {
        return await _createOrUpdateUserProfile(event.session!.user);
      } else if (event.event == AuthChangeEvent.signedOut) {
        return null;
      }
      return null;
    });
  }

  // Create or update user profile in database
  Future<app_models.User> _createOrUpdateUserProfile(User supabaseUser) async {
    try {
      // Get user metadata
      final metadata = supabaseUser.userMetadata ?? {};
      final username = metadata['username'] ??
          metadata['name'] ??
          supabaseUser.email?.split('@')[0] ??
          'User';

      // Upsert user profile
      final userData = {
        'id': supabaseUser.id,
        'username': username,
        'avatar_url':
            metadata['avatar_url'] ?? supabaseUser.userMetadata?['avatar_url'],
        'spotify_id': metadata['provider_id'] ?? metadata['spotify_id'],
      };

      // Note: This assumes you have a users table in Supabase
      // You may need to adjust this based on your schema
      await _supabase.from('users').upsert(userData);

      return app_models.User(
        id: supabaseUser.id,
        username: username,
        email: supabaseUser.email,
        avatarUrl:
            metadata['avatar_url'] ?? supabaseUser.userMetadata?['avatar_url'],
        spotifyId: metadata['provider_id'] ?? metadata['spotify_id'],
      );
    } catch (e) {
      // If database update fails, still return user with basic info
      return app_models.User(
        id: supabaseUser.id,
        username: supabaseUser.email?.split('@')[0] ?? 'User',
        email: supabaseUser.email,
        avatarUrl: null,
        spotifyId: null,
      );
    }
  }

  // Get auth token for API requests
  String? getAuthToken() {
    return _supabase.auth.currentSession?.accessToken;
  }

  // Check if user is authenticated
  bool get isAuthenticated => _supabase.auth.currentSession != null;
}
