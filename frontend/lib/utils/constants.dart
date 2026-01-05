/// Application-wide constants
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPlaylistsPerPage = 10;

  // Thresholds
  static const int analysesPerLevel = 5;
  static const double minCompatibilityScore = 0.0;
  static const double maxCompatibilityScore = 100.0;

  // Animation durations (in milliseconds)
  static const int shortAnimationDuration = 300;
  static const int mediumAnimationDuration = 500;
  static const int longAnimationDuration = 800;
  static const int splashAnimationDuration = 8000;

  // Cache
  static const int cacheExpirationMinutes = 60;
  static const int maxCacheSize = 100;

  // API
  static const int maxRetryAttempts = 3;
  static const int requestTimeoutSeconds = 30;

  // UI
  static const double defaultBorderRadius = 12.0;
  static const double cardElevation = 8.0;
  static const double defaultPadding = 16.0;

  // Validation
  static const int minPlaylistUrlLength = 10;
  static const int maxPlaylistNameLength = 100;
  static const int minPasswordLength = 8;

  // Feature flags
  static const bool enableOfflineMode = true;
  static const bool enableBattleMode = true;
  static const bool enableRecommendations = true;
}

/// Application route constants
class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String analysis = '/analysis';
  static const String battle = '/battle';
  static const String recommendations = '/recommendations';
  static const String profile = '/profile';
  static const String login = '/login';
  static const String settings = '/settings';
  static const String history = '/history';
  static const String likedTracks = '/liked-tracks';
  static const String topTracks = '/top-tracks';
  static const String topArtists = '/top-artists';
  static const String recentlyPlayed = '/recently-played';
  static const String moodDiscovery = '/mood-discovery';
  static const String playlistGenerator = '/playlist-generator';
  static const String discoveryTimeline = '/discovery-timeline';
  static const String savedPlaylists = '/saved-playlists';
  static const String savedTracks = '/saved-tracks';
  static const String savedAlbums = '/saved-albums';
  static const String authCallback = '/auth/callback';
  static const String notFound = '/404';
}

/// Error message constants
class ErrorMessages {
  ErrorMessages._();

  static const String networkError =
      'Network connection failed. Please check your internet connection.';
  static const String serverError =
      'Server error occurred. Please try again later.';
  static const String authRequired = 'Authentication required. Please log in.';
  static const String invalidPlaylistUrl =
      'Invalid playlist URL. Please check the URL and try again.';
  static const String tokenExpired =
      'Your session has expired. Please log in again.';
  static const String insufficientPermissions =
      'Insufficient permissions. Please reconnect your Spotify account.';
  static const String playlistNotFound =
      'Playlist not found. The playlist may be private or deleted.';
  static const String genericError = 'An error occurred. Please try again.';
}
