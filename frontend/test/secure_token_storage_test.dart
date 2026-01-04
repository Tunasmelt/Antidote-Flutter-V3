import 'package:flutter_test/flutter_test.dart';
import 'package:antidote_flutter/services/secure_token_storage.dart';

void main() {
  group('SecureTokenStorage', () {
    setUp(() async {
      // Clear all tokens before each test
      await SecureTokenStorage.clearAll();
    });

    tearDown(() async {
      // Clean up after tests
      await SecureTokenStorage.clearAll();
    });

    group('Spotify Token Management', () {
      test('stores and retrieves Spotify access token', () async {
        const testToken = 'test_access_token_123';

        await SecureTokenStorage.setSpotifyAccessToken(testToken);
        final retrieved = await SecureTokenStorage.getSpotifyAccessToken();

        expect(retrieved, equals(testToken));
      });

      test('stores and retrieves Spotify refresh token', () async {
        const testToken = 'test_refresh_token_456';

        await SecureTokenStorage.setSpotifyRefreshToken(testToken);
        final retrieved = await SecureTokenStorage.getSpotifyRefreshToken();

        expect(retrieved, equals(testToken));
      });

      test('stores and retrieves token expiry', () async {
        final expiry = DateTime.now().add(const Duration(hours: 1));

        await SecureTokenStorage.setSpotifyTokenExpiry(expiry);
        final retrieved = await SecureTokenStorage.getSpotifyTokenExpiry();

        expect(retrieved, isNotNull);
        expect(retrieved!.difference(expiry).inSeconds, lessThan(2));
      });

      test('detects expired tokens', () async {
        final pastExpiry = DateTime.now().subtract(const Duration(hours: 1));

        await SecureTokenStorage.setSpotifyTokenExpiry(pastExpiry);
        final isExpired = await SecureTokenStorage.isSpotifyTokenExpired();

        expect(isExpired, isTrue);
      });

      test('detects valid tokens', () async {
        final futureExpiry = DateTime.now().add(const Duration(hours: 1));

        await SecureTokenStorage.setSpotifyTokenExpiry(futureExpiry);
        final isExpired = await SecureTokenStorage.isSpotifyTokenExpired();

        expect(isExpired, isFalse);
      });

      test('checks if tokens exist', () async {
        expect(await SecureTokenStorage.hasSpotifyTokens(), isFalse);

        await SecureTokenStorage.setSpotifyAccessToken('access');
        await SecureTokenStorage.setSpotifyRefreshToken('refresh');

        expect(await SecureTokenStorage.hasSpotifyTokens(), isTrue);
      });

      test('clears Spotify tokens', () async {
        await SecureTokenStorage.setSpotifyAccessToken('access');
        await SecureTokenStorage.setSpotifyRefreshToken('refresh');

        await SecureTokenStorage.clearSpotifyTokens();

        expect(await SecureTokenStorage.getSpotifyAccessToken(), isNull);
        expect(await SecureTokenStorage.getSpotifyRefreshToken(), isNull);
      });
    });

    group('Supabase Token Management', () {
      test('stores and retrieves Supabase auth token', () async {
        const testToken = 'supabase_token_789';

        await SecureTokenStorage.setSupabaseAuthToken(testToken);
        final retrieved = await SecureTokenStorage.getSupabaseAuthToken();

        expect(retrieved, equals(testToken));
      });

      test('clears Supabase token', () async {
        await SecureTokenStorage.setSupabaseAuthToken('token');
        await SecureTokenStorage.clearSupabaseToken();

        final retrieved = await SecureTokenStorage.getSupabaseAuthToken();
        expect(retrieved, isNull);
      });
    });

    group('Clear All', () {
      test('clears all stored tokens', () async {
        await SecureTokenStorage.setSpotifyAccessToken('spotify_access');
        await SecureTokenStorage.setSpotifyRefreshToken('spotify_refresh');
        await SecureTokenStorage.setSupabaseAuthToken('supabase_token');

        await SecureTokenStorage.clearAll();

        expect(await SecureTokenStorage.getSpotifyAccessToken(), isNull);
        expect(await SecureTokenStorage.getSpotifyRefreshToken(), isNull);
        expect(await SecureTokenStorage.getSupabaseAuthToken(), isNull);
      });
    });
  });
}
