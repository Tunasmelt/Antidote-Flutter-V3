import 'package:flutter/material.dart';
import '../utils/theme.dart';

/// Reusable error view widget with user-friendly messages
/// Displays error with icon, message, and actionable buttons
class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String? customMessage;
  final IconData? icon;

  const ErrorView({
    super.key,
    required this.error,
    this.onRetry,
    this.customMessage,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final errorInfo = _parseError(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? errorInfo.icon,
              size: 64,
              color: errorInfo.color,
            ),
            const SizedBox(height: 24),
            Text(
              customMessage ?? errorInfo.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              errorInfo.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textMuted,
                  ),
              textAlign: TextAlign.center,
            ),
            if (errorInfo.suggestion != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: errorInfo.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: errorInfo.color,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorInfo.suggestion!,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ErrorInfo _parseError(Object error) {
    final errorStr = error.toString().toLowerCase();

    // Network errors
    if (errorStr.contains('socket') ||
        errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return ErrorInfo(
        title: 'Connection Problem',
        message:
            'Unable to connect to the server. Please check your internet connection.',
        suggestion:
            'Make sure you\'re connected to the internet and try again.',
        icon: Icons.wifi_off,
        color: Colors.orange,
      );
    }

    // Timeout errors
    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return ErrorInfo(
        title: 'Request Timed Out',
        message: 'The request took too long to complete.',
        suggestion:
            'This might be due to a slow connection. Try again in a moment.',
        icon: Icons.access_time,
        color: Colors.orange,
      );
    }

    // Authentication errors
    if (errorStr.contains('token') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('authentication')) {
      return ErrorInfo(
        title: 'Authentication Required',
        message:
            'Your session has expired or you need to connect your account.',
        suggestion: 'Please reconnect your Spotify account from Settings.',
        icon: Icons.lock_outline,
        color: Colors.red,
      );
    }

    // Rate limit errors
    if (errorStr.contains('rate limit') ||
        errorStr.contains('too many requests') ||
        errorStr.contains('429')) {
      return ErrorInfo(
        title: 'Too Many Requests',
        message: 'You\'ve made too many requests. Please wait a moment.',
        suggestion:
            'Try again in a few minutes. We need to protect our servers from overload.',
        icon: Icons.speed,
        color: Colors.orange,
      );
    }

    // Server errors
    if (errorStr.contains('500') ||
        errorStr.contains('502') ||
        errorStr.contains('503') ||
        errorStr.contains('server error')) {
      return ErrorInfo(
        title: 'Server Error',
        message: 'Something went wrong on our end.',
        suggestion: 'Our team has been notified. Please try again later.',
        icon: Icons.cloud_off,
        color: Colors.red,
      );
    }

    // Validation errors
    if (errorStr.contains('invalid') || errorStr.contains('validation')) {
      return ErrorInfo(
        title: 'Invalid Input',
        message: 'The information you provided is not valid.',
        suggestion: 'Please check your input and try again.',
        icon: Icons.error_outline,
        color: Colors.orange,
      );
    }

    // Not found errors
    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return ErrorInfo(
        title: 'Not Found',
        message: 'The requested resource could not be found.',
        suggestion:
            'The playlist or track might have been deleted or made private.',
        icon: Icons.search_off,
        color: Colors.grey,
      );
    }

    // Permission errors
    if (errorStr.contains('permission') ||
        errorStr.contains('forbidden') ||
        errorStr.contains('403')) {
      return ErrorInfo(
        title: 'Access Denied',
        message: 'You don\'t have permission to access this resource.',
        suggestion:
            'Make sure the playlist is public or you have the necessary permissions.',
        icon: Icons.block,
        color: Colors.red,
      );
    }

    // Generic error
    return ErrorInfo(
      title: 'Something Went Wrong',
      message: 'An unexpected error occurred.',
      suggestion: 'Please try again. If the problem persists, contact support.',
      icon: Icons.error_outline,
      color: Colors.red,
    );
  }
}

class ErrorInfo {
  final String title;
  final String message;
  final String? suggestion;
  final IconData icon;
  final Color color;

  ErrorInfo({
    required this.title,
    required this.message,
    this.suggestion,
    required this.icon,
    required this.color,
  });
}
