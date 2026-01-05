/// Error Handling Utilities for Frontend
/// Provides consistent error handling and user-friendly messaging
library;

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../services/logger_service.dart';

/// Centralized error handler for API and network errors
class ErrorHandler {
  ErrorHandler._(); // Private constructor

  /// Handle an error and show appropriate user feedback
  static void handleError(
    dynamic error,
    BuildContext context, {
    String? customMessage,
    VoidCallback? onRetry,
    bool showSnackbar = true,
  }) {
    final errorInfo = _parseError(error);

    // Log error for debugging
    LoggerService.error(
      errorInfo.message,
      error: error,
      stackTrace: errorInfo.stackTrace,
      tag: 'ErrorHandler',
    );

    // Show user-friendly message
    if (showSnackbar && context.mounted) {
      _showErrorSnackbar(
        context,
        customMessage ?? errorInfo.userMessage,
        onRetry: onRetry,
      );
    }
  }

  /// Parse error into structured information
  static ErrorInfo _parseError(dynamic error) {
    if (error is ApiException) {
      return _handleApiException(error);
    } else if (error is DioException) {
      return _handleDioException(error);
    } else if (error is Exception) {
      return ErrorInfo(
        message: error.toString(),
        userMessage: 'An unexpected error occurred. Please try again.',
        code: 'UNKNOWN_ERROR',
      );
    } else {
      return ErrorInfo(
        message: error.toString(),
        userMessage: 'Something went wrong. Please try again later.',
        code: 'UNEXPECTED_ERROR',
      );
    }
  }

  /// Handle API-specific exceptions
  static ErrorInfo _handleApiException(ApiException error) {
    String userMessage;

    switch (error.statusCode) {
      case 401:
        userMessage = 'Authentication required. Please log in again.';
        break;
      case 403:
        userMessage = 'You don\'t have permission to perform this action.';
        break;
      case 404:
        userMessage = 'The requested resource was not found.';
        break;
      case 429:
        userMessage = 'Too many requests. Please wait a moment and try again.';
        break;
      case 500:
      case 502:
      case 503:
        userMessage = 'Server error. Our team has been notified.';
        break;
      default:
        userMessage = error.message;
    }

    return ErrorInfo(
      message: error.message,
      userMessage: userMessage,
      code: 'API_ERROR_${error.statusCode ?? 'UNKNOWN'}',
      statusCode: error.statusCode,
    );
  }

  /// Handle Dio network exceptions
  static ErrorInfo _handleDioException(DioException error) {
    String userMessage;
    String code;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        userMessage =
            'Connection timeout. Please check your internet connection.';
        code = 'TIMEOUT';
        break;

      case DioExceptionType.connectionError:
        userMessage = 'No internet connection. Please check your network.';
        code = 'NO_CONNECTION';
        break;

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        userMessage = _getStatusCodeMessage(statusCode);
        code = 'BAD_RESPONSE_$statusCode';
        break;

      case DioExceptionType.cancel:
        userMessage = 'Request was cancelled.';
        code = 'CANCELLED';
        break;

      default:
        userMessage = 'Network error. Please try again.';
        code = 'NETWORK_ERROR';
    }

    return ErrorInfo(
      message: error.message ?? 'Dio error occurred',
      userMessage: userMessage,
      code: code,
      statusCode: error.response?.statusCode,
      stackTrace: error.stackTrace,
    );
  }

  /// Get user-friendly message for HTTP status codes
  static String _getStatusCodeMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Please log in to continue.';
      case 403:
        return 'Access denied.';
      case 404:
        return 'Resource not found.';
      case 429:
        return 'Too many requests. Please wait and try again.';
      case 500:
      case 502:
      case 503:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  /// Show error snackbar with retry option
  static void _showErrorSnackbar(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// Check if error is a network connectivity issue
  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout;
    }
    return false;
  }

  /// Check if error requires re-authentication
  static bool isAuthError(dynamic error) {
    if (error is ApiException) {
      return error.statusCode == 401;
    }
    if (error is DioException) {
      return error.response?.statusCode == 401;
    }
    return false;
  }
}

/// Structured error information
class ErrorInfo {
  final String message;
  final String userMessage;
  final String code;
  final int? statusCode;
  final StackTrace? stackTrace;

  ErrorInfo({
    required this.message,
    required this.userMessage,
    required this.code,
    this.statusCode,
    this.stackTrace,
  });
}
