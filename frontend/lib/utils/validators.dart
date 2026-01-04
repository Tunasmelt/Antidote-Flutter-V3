/// Input validation utilities for forms and user input
/// Provides reusable validators for common input types
class InputValidators {
  // Email validation regex
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Password strength regex patterns
  static final _uppercaseRegex = RegExp(r'[A-Z]');
  static final _lowercaseRegex = RegExp(r'[a-z]');
  static final _digitRegex = RegExp(r'[0-9]');
  static final _specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  // URL validation regex patterns
  static final _spotifyPlaylistRegex = RegExp(
    r'^(https?://)?open\.spotify\.com/(playlist|user/[^/]+/playlist)/[a-zA-Z0-9]+',
  );
  static final _spotifyUriRegex = RegExp(
    r'^spotify:(playlist|user:[^:]+:playlist):[a-zA-Z0-9]+$',
  );
  static final _appleMusicPlaylistRegex = RegExp(
    r'^(https?://)?music\.apple\.com/[a-z]{2}/playlist/[^/]+/pl\.[a-z0-9]+',
  );

  /// Validate email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate password with strength requirements
  /// Requires: 8+ chars, uppercase, lowercase, number, special char
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!_uppercaseRegex.hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!_lowercaseRegex.hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!_digitRegex.hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!_specialCharRegex.hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  /// Validate password with custom minimum length
  static String? validatePasswordWithLength(String? value, int minLength) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Check password strength (0-5)
  /// 0: Empty, 1: Very weak, 2: Weak, 3: Fair, 4: Strong, 5: Very strong
  static int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;

    // Length check
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // Character type checks
    if (_uppercaseRegex.hasMatch(password)) strength++;
    if (_lowercaseRegex.hasMatch(password)) strength++;
    if (_digitRegex.hasMatch(password)) strength++;
    if (_specialCharRegex.hasMatch(password)) strength++;

    // Cap at 5
    return strength > 5 ? 5 : strength;
  }

  /// Validate required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  /// Validate Spotify playlist URL
  static String? validateSpotifyPlaylistUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a Spotify playlist URL';
    }
    if (!_spotifyPlaylistRegex.hasMatch(value) &&
        !_spotifyUriRegex.hasMatch(value)) {
      return 'Please enter a valid Spotify playlist URL or URI';
    }
    return null;
  }

  /// Validate Apple Music playlist URL
  static String? validateAppleMusicPlaylistUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an Apple Music playlist URL';
    }
    if (!_appleMusicPlaylistRegex.hasMatch(value)) {
      return 'Please enter a valid Apple Music playlist URL';
    }
    return null;
  }

  /// Validate any supported playlist URL (Spotify or Apple Music)
  static String? validatePlaylistUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a playlist URL';
    }
    if (!_spotifyPlaylistRegex.hasMatch(value) &&
        !_spotifyUriRegex.hasMatch(value) &&
        !_appleMusicPlaylistRegex.hasMatch(value)) {
      return 'Please enter a valid Spotify or Apple Music playlist URL';
    }
    return null;
  }

  /// Check if URL is a valid Spotify playlist
  static bool isSpotifyPlaylistUrl(String url) {
    return _spotifyPlaylistRegex.hasMatch(url) ||
        _spotifyUriRegex.hasMatch(url);
  }

  /// Check if URL is a valid Apple Music playlist
  static bool isAppleMusicPlaylistUrl(String url) {
    return _appleMusicPlaylistRegex.hasMatch(url);
  }

  /// Validate minimum length
  static String? validateMinLength(
      String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(
      String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must be at most $maxLength characters';
    }
    return null;
  }

  /// Validate numeric input
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    if (int.tryParse(value) == null && double.tryParse(value) == null) {
      return '$fieldName must be a number';
    }
    return null;
  }

  /// Validate phone number (basic)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a phone number';
    }
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Sanitize user input (remove potentially harmful characters)
  static String sanitizeInput(String input) {
    // Remove null bytes and control characters
    return input.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
  }

  /// Validate URL format (general)
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a URL';
    }
    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme ||
          (!uri.scheme.startsWith('http') && uri.scheme != 'spotify')) {
        return 'Please enter a valid URL';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }
}
