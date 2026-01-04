import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import '../config/env_config.dart';

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

  // Token refresh lock to prevent concurrent refresh attempts
  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

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
      final storedToken =
          await _secureStorage.read(key: _storageKeyAccessToken);
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
    // If already refreshing, wait for the ongoing refresh to complete
    if (_isRefreshing && _refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    // Start refreshing
    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken =
          await _secureStorage.read(key: _storageKeyRefreshToken);
      if (refreshToken == null) {
        // No refresh token, user needs to reconnect
        _refreshCompleter!.complete(null);
        return null;
      }

      // Try to refresh using Supabase if available
      final session = _supabase.auth.currentSession;
      if (session != null && session.providerRefreshToken != null) {
        try {
          // Supabase handles token refresh automatically
          await _supabase.auth.refreshSession();
          final newToken = await _getTokenFromSupabase();
          if (newToken != null) {
            _refreshCompleter!.complete(newToken);
            return newToken;
          }
        } catch (e) {
          // Fall through to manual refresh
        }
      }

      // Manual refresh using Spotify API
      final newToken = await _refreshTokenManually(refreshToken);
      _refreshCompleter!.complete(newToken);
      return newToken;
    } catch (e) {
      _refreshCompleter!.complete(null);
      return null;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  /// Manually refresh token using backend API
  Future<String?> _refreshTokenManually(String refreshToken) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: EnvConfig.apiBaseUrl));

      final response = await dio.post(
        '/api/spotify/refresh',
        data: {
          'refresh_token': refreshToken,
        },
      );

      if (response.data != null && response.data['access_token'] != null) {
        final accessToken = response.data['access_token'] as String;
        final expiresIn = response.data['expires_in'] as int? ?? 3600;
        final newRefreshToken =
            response.data['refresh_token'] as String? ?? refreshToken;

        await _storeTokens(
          accessToken: accessToken,
          refreshToken: newRefreshToken,
          expiresIn: expiresIn,
        );

        return accessToken;
      }

      return null;
    } catch (e) {
      // If refresh fails, user needs to reconnect
      return null;
    }
  }

  /// Connect Spotify via direct OAuth flow
  Future<void> connectSpotify({bool useDirectOAuth = true}) async {
    // Always use direct OAuth to avoid circular dependencies
    await _connectSpotifyDirect();
  }

  /// Direct Spotify OAuth flow
  Future<void> _connectSpotifyDirect() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: EnvConfig.apiBaseUrl));

      // Get authorization URL from backend
      final authResponse = await dio.get(
        '/api/spotify/authorize',
        queryParameters: {
          'redirect_uri': EnvConfig.spotifyRedirectUri,
        },
      );

      if (authResponse.data == null || authResponse.data['authUrl'] == null) {
        throw SpotifyAuthException('Failed to get authorization URL');
      }

      final authUrl = authResponse.data['authUrl'] as String;

      // Open authorization URL in browser
      final uri = Uri.parse(authUrl);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw SpotifyAuthException('Failed to open authorization URL');
      }

      // Wait for callback - this will be handled by deep link handler
      // The deep link handler will call _handleOAuthCallback
    } catch (e) {
      throw SpotifyAuthException('Failed to connect Spotify: ${e.toString()}');
    }
  }

  /// Handle OAuth callback with authorization code
  /// This is called by the deep link handler when user returns from Spotify
  /// Returns both tokens and user info
  Future<Map<String, dynamic>> handleOAuthCallback(String code,
      {String? redirectUri}) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: EnvConfig.apiBaseUrl));

      // Exchange code for tokens
      final tokenResponse = await dio.post(
        '/api/spotify/callback',
        data: {
          'code': code,
          'redirect_uri': redirectUri ?? EnvConfig.spotifyRedirectUri,
        },
      );

      if (tokenResponse.data == null ||
          tokenResponse.data['access_token'] == null) {
        throw SpotifyAuthException('Failed to exchange code for tokens');
      }

      final accessToken = tokenResponse.data['access_token'] as String;
      final refreshToken = tokenResponse.data['refresh_token'] as String?;
      final expiresIn = tokenResponse.data['expires_in'] as int? ?? 3600;

      // Store tokens securely
      await _storeTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresIn: expiresIn,
      );

      // Fetch Spotify user info using the access token
      final userResponse = await dio.get(
        '/api/spotify/me',
        options: Options(
          headers: {
            'X-Spotify-Token': accessToken,
          },
        ),
      );

      if (userResponse.data == null) {
        throw SpotifyAuthException('Failed to fetch Spotify user info');
      }

      // Return both tokens and user info
      return {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_in': expiresIn,
        'user': userResponse.data,
      };
    } catch (e) {
      throw SpotifyAuthException('Failed to complete OAuth: ${e.toString()}');
    }
  }

  /// Store Spotify tokens securely
  Future<void> _storeTokens({
    required String accessToken,
    String? refreshToken,
    required int expiresIn,
  }) async {
    try {
      await _secureStorage.write(
          key: _storageKeyAccessToken, value: accessToken);

      if (refreshToken != null) {
        await _secureStorage.write(
            key: _storageKeyRefreshToken, value: refreshToken);
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

  /// Get Spotify user info using current access token
  Future<Map<String, dynamic>?> getSpotifyUserInfo() async {
    try {
      final token = await getSpotifyAccessToken();
      if (token == null) return null;

      final dio = Dio(BaseOptions(baseUrl: EnvConfig.apiBaseUrl));
      final response = await dio.get(
        '/api/spotify/me',
        options: Options(
          headers: {
            'X-Spotify-Token': token,
          },
        ),
      );

      return response.data as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Validate and restore tokens from secure storage
  /// Returns valid token if available, null if tokens need to be refreshed or re-authenticated
  Future<String?> validateAndRestoreTokens() async {
    try {
      // Check if tokens exist in secure storage
      final accessToken =
          await _secureStorage.read(key: _storageKeyAccessToken);
      final refreshToken =
          await _secureStorage.read(key: _storageKeyRefreshToken);

      if (accessToken == null) {
        // No tokens stored
        return null;
      }

      // Check if token is valid (not expired)
      if (await _isTokenValid(accessToken)) {
        // Token is valid, return it
        return accessToken;
      }

      // Token expired, try to refresh
      if (refreshToken != null) {
        final newToken = await refreshSpotifyToken();
        if (newToken != null) {
          return newToken;
        }
      }

      // Refresh failed or no refresh token, user needs to reconnect
      return null;
    } catch (e) {
      // Error validating tokens, user needs to reconnect
      return null;
    }
  }
}
