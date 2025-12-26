import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class EnvConfig {
  // Load environment variables
  static Future<void> load() async {
    if (kDebugMode) {
      await dotenv.load(fileName: '.env.development');
    } else {
      await dotenv.load(fileName: '.env.production');
    }
  }

  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // API Configuration
  static String get apiBaseUrl {
    if (kDebugMode) {
      return dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
    } else {
      return dotenv.env['API_BASE_URL'] ?? 'https://api.antidote.app';
    }
  }

  // Spotify OAuth
  // Note: Only Client ID is needed (public, safe to use)
  // Client Secret is NOT needed - users authenticate with their own Spotify accounts
  static String get spotifyClientId => dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  static String get spotifyRedirectUri => dotenv.env['SPOTIFY_REDIRECT_URI'] ?? 
    (kDebugMode ? 'com.antidote.app://auth/callback' : 'https://antidote.app/auth/callback');

  // App Configuration
  static String get appName => dotenv.env['APP_NAME'] ?? 'Antidote v3';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';

  // Feature Flags
  static bool get enableOfflineCache => dotenv.env['ENABLE_OFFLINE_CACHE'] != 'false';
  static bool get enableRetryLogic => dotenv.env['ENABLE_RETRY_LOGIC'] != 'false';
  static int get maxRetryAttempts => int.tryParse(dotenv.env['MAX_RETRY_ATTEMPTS'] ?? '3') ?? 3;

  // Cache Configuration
  static Duration get cacheExpiration => Duration(
    minutes: int.tryParse(dotenv.env['CACHE_EXPIRATION_MINUTES'] ?? '60') ?? 60,
  );

  // Validate required environment variables
  static bool validate() {
    final required = ['SUPABASE_URL', 'SUPABASE_ANON_KEY'];
    final missing = required.where((key) => dotenv.env[key]?.isEmpty ?? true).toList();
    
    if (missing.isNotEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ Missing environment variables: ${missing.join(', ')}');
        debugPrint('⚠️ Using default/empty values. Some features may not work.');
      }
      return false;
    }
    return true;
  }
}

