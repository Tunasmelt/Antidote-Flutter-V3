import 'package:flutter/foundation.dart';

/// Simple logging service for the application
/// Uses debugPrint in debug mode, can be extended for production logging
class LoggerService {
  static const String _prefix = '[Antidote]';

  /// Log informational messages
  static void info(String message, {String? tag}) {
    _log('INFO', message, tag: tag);
  }

  /// Log warning messages
  static void warning(String message, {String? tag}) {
    _log('WARNING', message, tag: tag);
  }

  /// Log error messages
  static void error(String message,
      {Object? error, StackTrace? stackTrace, String? tag}) {
    _log('ERROR', message, tag: tag);
    if (error != null) {
      _log('ERROR', 'Error details: $error', tag: tag);
    }
    if (stackTrace != null && kDebugMode) {
      _log('ERROR', 'Stack trace: $stackTrace', tag: tag);
    }
  }

  /// Log debug messages (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      _log('DEBUG', message, tag: tag);
    }
  }

  /// Internal logging method
  static void _log(String level, String message, {String? tag}) {
    final timestamp = DateTime.now().toIso8601String();
    final tagStr = tag != null ? '[$tag]' : '';
    final logMessage = '$_prefix $timestamp [$level]$tagStr $message';

    if (kDebugMode) {
      debugPrint(logMessage);
    }
    // In production, you could send logs to a service like:
    // - Firebase Crashlytics
    // - Sentry
    // - Custom logging backend
    // Example: if (kReleaseMode) { _sendToLogService(logMessage); }
  }

  /// Log successful migration events
  static void logMigration({required int itemsMigrated}) {
    info('Guest data migration completed: $itemsMigrated items migrated',
        tag: 'Migration');
  }

  /// Log migration failures
  static void logMigrationError(Object error, {StackTrace? stackTrace}) {
    LoggerService.error(
      'Guest data migration failed',
      error: error,
      stackTrace: stackTrace,
      tag: 'Migration',
    );
  }
}
