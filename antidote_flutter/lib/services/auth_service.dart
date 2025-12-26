import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;
import '../config/env_config.dart';
import 'spotify_auth_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => message;
}

class AuthService {
  final SupabaseClient _supabase;
  final SpotifyAuthService _spotifyAuth = SpotifyAuthService();

  AuthService() : _supabase = Supabase.instance.client;

  // Email/Password Authentication
  Future<app_models.User?> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return await _createOrUpdateUserProfile(response.user!);
      }
      return null;
    } on AuthException catch (e) {
      throw AuthException('Sign in failed: ${e.message}');
    } catch (e) {
      throw AuthException('Sign in failed: ${e.toString()}');
    }
  }

  Future<app_models.User?> signUpWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return await _createOrUpdateUserProfile(response.user!);
      }
      return null;
    } on AuthException catch (e) {
      throw AuthException('Sign up failed: ${e.message}');
    } catch (e) {
      throw AuthException('Sign up failed: ${e.toString()}');
    }
  }

  // Spotify OAuth
  Future<void> signInWithSpotify() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.spotify,
        redirectTo: EnvConfig.spotifyRedirectUri,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // After OAuth completes, tokens will be available via SpotifyAuthService
    } catch (e) {
      throw AuthException('Spotify authentication failed: ${e.toString()}');
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
        redirectTo: '${EnvConfig.spotifyRedirectUri.split('://')[0]}://reset-password',
      );
    } catch (e) {
      throw AuthException('Password reset failed: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Disconnect Spotify before signing out
      await _spotifyAuth.disconnectSpotify();
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
      if (event.event == AuthChangeEvent.signedIn && event.session?.user != null) {
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
        'avatar_url': metadata['avatar_url'] ?? supabaseUser.userMetadata?['avatar_url'],
        'spotify_id': metadata['provider_id'] ?? metadata['spotify_id'],
      };

      // Note: This assumes you have a users table in Supabase
      // You may need to adjust this based on your schema
      await _supabase.from('users').upsert(userData);

      return app_models.User(
        id: supabaseUser.id,
        username: username,
        email: supabaseUser.email,
        avatarUrl: metadata['avatar_url'] ?? supabaseUser.userMetadata?['avatar_url'],
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
