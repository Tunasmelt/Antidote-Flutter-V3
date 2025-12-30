import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';
import 'auth_service.dart';

class SpotifyAuthException implements Exception {
  final String message;
  SpotifyAuthException(this.message);
  
  @override
  String toString() => message;
}

class SpotifyAuthService {
  static const String _storageKeyAccessToken = 'spotify_access_token';
  static const String _storageKeyRefreshToken = 'spotify_refresh_token';
  static const String _storageKeyExpiresAt = 'spotify_token_expires_at';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // Spotify OAuth scopes needed for the app
  // Note: Scopes are configured in Supabase OAuth settings
  // These are listed here for reference:
  // 'user-read-private', 'user-read-email', 'playlist-read-private',
  // 'playlist-read-collaborative', 'user-library-read', 'user-top-read',
  // 'user-read-recently-played'

  /// Check if user has connected Spotify
  Future<bool> isSpotifyConnected() async {
    try {
      final token = await getSpotifyAccessToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get current Spotify access token (from Supabase OAuth or secure storage)
  Future<String?> getSpotifyAccessToken() async {
    try {
      // Option 1: Try to get from Supabase OAuth session
      final supabaseToken = await _getTokenFromSupabase();
      if (supabaseToken != null && await _isTokenValid(supabaseToken)) {
        return supabaseToken;
      }

      // Option 2: Get from secure storage
      final storedToken = await _secureStorage.read(key: _storageKeyAccessToken);
      if (storedToken != null && await _isTokenValid(storedToken)) {
        return storedToken;
      }

      // Token expired or doesn't exist, try to refresh
      final refreshedToken = await refreshSpotifyToken();
      return refreshedToken;
    } catch (e) {
      return null;
    }
  }

  /// Get Spotify access token from Supabase OAuth session
  Future<String?> _getTokenFromSupabase() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return null;

      // Try to get access token from provider token (Supabase OAuth provides this)
      final providerToken = session.providerToken;
      if (providerToken != null && providerToken.isNotEmpty) {
        // Store it for future use
        await _storeTokens(
          accessToken: providerToken,
          refreshToken: session.providerRefreshToken ?? '',
          expiresIn: 3600, // Default 1 hour
        );
        return providerToken;
      }

      // Try to get from user metadata (if stored there)
      final metadata = session.user.userMetadata;
      if (metadata != null && metadata.containsKey('spotify_access_token')) {
        final token = metadata['spotify_access_token'] as String?;
        if (token != null && token.isNotEmpty) {
          return token;
        }
      }

      // If user authenticated with Spotify but token not available,
      // we may need to use a different approach (direct Spotify OAuth)
      // For now, return null and let the caller handle it
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if token is still valid (not expired)
  Future<bool> _isTokenValid(String token) async {
    try {
      final expiresAtStr = await _secureStorage.read(key: _storageKeyExpiresAt);
      if (expiresAtStr == null) return false;

      final expiresAt = DateTime.parse(expiresAtStr);
      final now = DateTime.now();
      
      // Consider token expired if it expires in less than 5 minutes
      return now.isBefore(expiresAt.subtract(const Duration(minutes: 5)));
    } catch (e) {
      return false;
    }
  }

  /// Refresh Spotify access token
  Future<String?> refreshSpotifyToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _storageKeyRefreshToken);
      if (refreshToken == null) {
        // No refresh token, user needs to reconnect
        return null;
      }

      // Try to refresh using Supabase if available
      final session = _supabase.auth.currentSession;
      if (session != null && session.providerRefreshToken != null) {
        try {
          // Supabase handles token refresh automatically
          await _supabase.auth.refreshSession();
          final newToken = await _getTokenFromSupabase();
          if (newToken != null) return newToken;
        } catch (e) {
          // Fall through to manual refresh
        }
      }

      // Manual refresh using Spotify API
      final newToken = await _refreshTokenManually(refreshToken);
      return newToken;
    } catch (e) {
      return null;
    }
  }

  /// Manually refresh token using Spotify API
  Future<String?> _refreshTokenManually(String refreshToken) async {
    try {
      final clientId = EnvConfig.spotifyClientId;
      if (clientId.isEmpty) {
        throw SpotifyAuthException('Spotify Client ID not configured');
      }

      final response = await _supabase.functions.invoke(
        'refresh-spotify-token',
        body: {
          'refresh_token': refreshToken,
        },
      );

      if (response.data != null && response.data['access_token'] != null) {
        final accessToken = response.data['access_token'] as String;
        final expiresIn = response.data['expires_in'] as int? ?? 3600;
        
        await _storeTokens(
          accessToken: accessToken,
          refreshToken: response.data['refresh_token'] as String? ?? refreshToken,
          expiresIn: expiresIn,
        );

        return accessToken;
      }

      return null;
    } catch (e) {
      // If Supabase function doesn't exist, we'll need user to reconnect
      return null;
    }
  }

  /// Connect Spotify via Supabase OAuth
  Future<void> connectSpotify() async {
    try {
      await _authService.signInWithSpotify();
      // After OAuth completes, tokens will be available in Supabase session
    } catch (e) {
      throw SpotifyAuthException('Failed to connect Spotify: ${e.toString()}');
    }
  }

  /// Store Spotify tokens securely
  Future<void> _storeTokens({
    required String accessToken,
    String? refreshToken,
    required int expiresIn,
  }) async {
    try {
      await _secureStorage.write(key: _storageKeyAccessToken, value: accessToken);
      
      if (refreshToken != null) {
        await _secureStorage.write(key: _storageKeyRefreshToken, value: refreshToken);
      }

      final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
      await _secureStorage.write(
        key: _storageKeyExpiresAt,
        value: expiresAt.toIso8601String(),
      );
    } catch (e) {
      // Storage might fail, but don't throw - token refresh will handle it
    }
  }

  /// Disconnect Spotify (clear tokens)
  Future<void> disconnectSpotify() async {
    try {
      await _secureStorage.delete(key: _storageKeyAccessToken);
      await _secureStorage.delete(key: _storageKeyRefreshToken);
      await _secureStorage.delete(key: _storageKeyExpiresAt);
    } catch (e) {
      // Ignore errors
    }
  }

  /// Get Spotify user info (optional - for verification)
  Future<Map<String, dynamic>?> getSpotifyUserInfo() async {
    try {
      final token = await getSpotifyAccessToken();
      if (token == null) return null;

      // This would require a backend endpoint or direct Spotify API call
      // For now, return null - can be implemented later if needed
      return null;
    } catch (e) {
      return null;
    }
  }
}

