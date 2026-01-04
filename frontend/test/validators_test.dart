import 'package:flutter_test/flutter_test.dart';
import 'package:antidote_flutter/utils/validators.dart';

void main() {
  group('InputValidators', () {
    group('Email Validation', () {
      test('validates correct email addresses', () {
        expect(InputValidators.validateEmail('test@example.com'), isNull);
        expect(InputValidators.validateEmail('user.name@domain.co.uk'), isNull);
        expect(InputValidators.validateEmail('test+tag@example.com'), isNull);
      });

      test('rejects invalid email addresses', () {
        expect(InputValidators.validateEmail(''), isNotNull);
        expect(InputValidators.validateEmail('notanemail'), isNotNull);
        expect(InputValidators.validateEmail('missing@domain'), isNotNull);
        expect(InputValidators.validateEmail('@nodomain.com'), isNotNull);
        expect(InputValidators.validateEmail('spaces in@email.com'), isNotNull);
      });

      test('handles null input', () {
        expect(InputValidators.validateEmail(null), isNotNull);
      });
    });

    group('Password Validation', () {
      test('validates strong passwords', () {
        expect(InputValidators.validatePassword('Test123!@#'), isNull);
        expect(InputValidators.validatePassword('MyP@ssw0rd'), isNull);
        expect(InputValidators.validatePassword('Secure123!Pass'), isNull);
      });

      test('rejects weak passwords', () {
        expect(InputValidators.validatePassword(''), isNotNull);
        expect(InputValidators.validatePassword('short'), isNotNull);
        expect(InputValidators.validatePassword('nouppercase123!'), isNotNull);
        expect(InputValidators.validatePassword('NOLOWERCASE123!'), isNotNull);
        expect(InputValidators.validatePassword('NoNumbers!'), isNotNull);
        expect(InputValidators.validatePassword('NoSpecial123'), isNotNull);
      });

      test('enforces minimum length', () {
        expect(InputValidators.validatePassword('Test1!'), isNotNull);
        expect(InputValidators.validatePassword('Test12!'), isNotNull);
        expect(InputValidators.validatePassword('Test123!'), isNull);
      });
    });

    group('Password Strength', () {
      test('calculates password strength correctly', () {
        expect(InputValidators.getPasswordStrength(''), equals(0));
        expect(InputValidators.getPasswordStrength('weak'), lessThan(3));
        expect(
            InputValidators.getPasswordStrength('Better123'), greaterThan(2));
        expect(
            InputValidators.getPasswordStrength('Str0ng!Pass'), greaterThan(4));
      });
    });

    group('Playlist URL Validation', () {
      test('validates Spotify playlist URLs', () {
        expect(
          InputValidators.validateSpotifyPlaylistUrl(
              'https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M'),
          isNull,
        );
        expect(
          InputValidators.validateSpotifyPlaylistUrl(
              'open.spotify.com/playlist/abc123'),
          isNull,
        );
        expect(
          InputValidators.validateSpotifyPlaylistUrl('spotify:playlist:abc123'),
          isNull,
        );
      });

      test('validates Apple Music playlist URLs', () {
        expect(
          InputValidators.validateAppleMusicPlaylistUrl(
              'https://music.apple.com/us/playlist/test/pl.abc123'),
          isNull,
        );
      });

      test('rejects invalid URLs', () {
        expect(InputValidators.validatePlaylistUrl(''), isNotNull);
        expect(InputValidators.validatePlaylistUrl('not-a-url'), isNotNull);
        expect(InputValidators.validatePlaylistUrl('https://google.com'),
            isNotNull);
      });
    });

    group('URL Detection', () {
      test('detects Spotify URLs', () {
        expect(
          InputValidators.isSpotifyPlaylistUrl(
              'https://open.spotify.com/playlist/abc'),
          isTrue,
        );
        expect(
          InputValidators.isSpotifyPlaylistUrl('spotify:playlist:abc'),
          isTrue,
        );
        expect(
          InputValidators.isSpotifyPlaylistUrl(
              'https://music.apple.com/playlist'),
          isFalse,
        );
      });

      test('detects Apple Music URLs', () {
        expect(
          InputValidators.isAppleMusicPlaylistUrl(
              'https://music.apple.com/us/playlist/test/pl.abc'),
          isTrue,
        );
        expect(
          InputValidators.isAppleMusicPlaylistUrl(
              'https://open.spotify.com/playlist/abc'),
          isFalse,
        );
      });
    });

    group('Input Sanitization', () {
      test('removes control characters', () {
        expect(
            InputValidators.sanitizeInput('clean text'), equals('clean text'));
        expect(
          InputValidators.sanitizeInput('text\x00with\x1Fnull'),
          equals('textwithnull'),
        );
      });
    });

    group('Numeric Validation', () {
      test('validates numbers', () {
        expect(InputValidators.validateNumeric('123', 'age'), isNull);
        expect(InputValidators.validateNumeric('45.67', 'price'), isNull);
      });

      test('rejects non-numeric input', () {
        expect(InputValidators.validateNumeric('abc', 'age'), isNotNull);
        expect(InputValidators.validateNumeric('12ab', 'count'), isNotNull);
      });
    });

    group('Required Field Validation', () {
      test('validates non-empty fields', () {
        expect(InputValidators.validateRequired('value', 'name'), isNull);
      });

      test('rejects empty fields', () {
        expect(InputValidators.validateRequired('', 'name'), isNotNull);
        expect(InputValidators.validateRequired(null, 'name'), isNotNull);
      });
    });

    group('Length Validation', () {
      test('validates minimum length', () {
        expect(
          InputValidators.validateMinLength('12345', 5, 'code'),
          isNull,
        );
        expect(
          InputValidators.validateMinLength('123456', 5, 'code'),
          isNull,
        );
      });

      test('rejects too short input', () {
        expect(
          InputValidators.validateMinLength('123', 5, 'code'),
          isNotNull,
        );
      });

      test('validates maximum length', () {
        expect(
          InputValidators.validateMaxLength('12345', 5, 'code'),
          isNull,
        );
        expect(
          InputValidators.validateMaxLength('1234', 5, 'code'),
          isNull,
        );
      });

      test('rejects too long input', () {
        expect(
          InputValidators.validateMaxLength('123456', 5, 'code'),
          isNotNull,
        );
      });
    });
  });
}
