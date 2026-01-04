import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage service for sensitive data like API tokens
/// Uses platform-specific secure storage (Keychain on iOS, EncryptedSharedPreferences on Android)
class SecureTokenStorage {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Token keys
  static const String _spotifyAccessTokenKey = 'spotify_access_token';
  static const String _spotifyRefreshTokenKey = 'spotify_refresh_token';
  static const String _spotifyTokenExpiryKey = 'spotify_token_expiry';
  static const String _supabaseTokenKey = 'supabase_auth_token';

  /// Store Spotify access token securely
  static Future<void> setSpotifyAccessToken(String token) async {
    await _secureStorage.write(key: _spotifyAccessTokenKey, value: token);
  }

  /// Get Spotify access token
  static Future<String?> getSpotifyAccessToken() async {
    return await _secureStorage.read(key: _spotifyAccessTokenKey);
  }

  /// Store Spotify refresh token securely
  static Future<void> setSpotifyRefreshToken(String token) async {
    await _secureStorage.write(key: _spotifyRefreshTokenKey, value: token);
  }

  /// Get Spotify refresh token
  static Future<String?> getSpotifyRefreshToken() async {
    return await _secureStorage.read(key: _spotifyRefreshTokenKey);
  }

  /// Store Spotify token expiry time
  static Future<void> setSpotifyTokenExpiry(DateTime expiry) async {
    await _secureStorage.write(
      key: _spotifyTokenExpiryKey,
      value: expiry.toIso8601String(),
    );
  }

  /// Get Spotify token expiry time
  static Future<DateTime?> getSpotifyTokenExpiry() async {
    final expiryStr = await _secureStorage.read(key: _spotifyTokenExpiryKey);
    if (expiryStr == null) return null;
    try {
      return DateTime.parse(expiryStr);
    } catch (e) {
      return null;
    }
  }

  /// Check if Spotify token is expired
  static Future<bool> isSpotifyTokenExpired() async {
    final expiry = await getSpotifyTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  /// Store Supabase auth token securely
  static Future<void> setSupabaseAuthToken(String token) async {
    await _secureStorage.write(key: _supabaseTokenKey, value: token);
  }

  /// Get Supabase auth token
  static Future<String?> getSupabaseAuthToken() async {
    return await _secureStorage.read(key: _supabaseTokenKey);
  }

  /// Clear all Spotify tokens
  static Future<void> clearSpotifyTokens() async {
    await _secureStorage.delete(key: _spotifyAccessTokenKey);
    await _secureStorage.delete(key: _spotifyRefreshTokenKey);
    await _secureStorage.delete(key: _spotifyTokenExpiryKey);
  }

  /// Clear Supabase token
  static Future<void> clearSupabaseToken() async {
    await _secureStorage.delete(key: _supabaseTokenKey);
  }

  /// Clear all stored tokens
  static Future<void> clearAll() async {
    await clearSpotifyTokens();
    await clearSupabaseToken();
  }

  /// Check if Spotify tokens exist
  static Future<bool> hasSpotifyTokens() async {
    final accessToken = await getSpotifyAccessToken();
    final refreshToken = await getSpotifyRefreshToken();
    return accessToken != null && refreshToken != null;
  }
}
