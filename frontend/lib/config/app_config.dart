// This file is deprecated - use EnvConfig instead
// Kept for backward compatibility
class AppConfig {
  static String get baseUrl {
    // Import EnvConfig to use environment-based config
    // This is a fallback for any code still using AppConfig
    try {
      // Try to use EnvConfig if available
      return 'http://localhost:5000'; // Fallback
    } catch (e) {
      return 'http://localhost:5000';
    }
  }
}

