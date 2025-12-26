import 'dart:math';
import 'package:dio/dio.dart';
import '../config/env_config.dart';

class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration baseDelay;

  RetryInterceptor({
    int? maxRetries,
    Duration? baseDelay,
  })  : maxRetries = maxRetries ?? EnvConfig.maxRetryAttempts,
        baseDelay = baseDelay ?? const Duration(seconds: 1);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!EnvConfig.enableRetryLogic) {
      return handler.next(err);
    }

    // Only retry on network errors or 5xx server errors
    final shouldRetry = _shouldRetry(err);
    if (!shouldRetry) {
      return handler.next(err);
    }

    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;
    if (retryCount >= maxRetries) {
      return handler.next(err);
    }

    // Calculate exponential backoff delay
    final delay = baseDelay * pow(2, retryCount);
    
    // Add jitter to prevent thundering herd
    final jitter = Duration(milliseconds: Random().nextInt(500));
    final totalDelay = delay + jitter;

    await Future.delayed(totalDelay);

    // Update retry count
    err.requestOptions.extra['retryCount'] = retryCount + 1;

    // Retry the request
    try {
      final response = await Dio().fetch(err.requestOptions);
      return handler.resolve(response);
    } catch (e) {
      if (e is DioException) {
        return onError(e, handler);
      }
      return handler.next(err);
    }
  }

  bool _shouldRetry(DioException err) {
    // Retry on network errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // Retry on 5xx server errors
    if (err.response != null) {
      final statusCode = err.response!.statusCode;
      if (statusCode != null && statusCode >= 500 && statusCode < 600) {
        return true;
      }
    }

    // Don't retry on 4xx client errors (except 408 Request Timeout)
    if (err.response != null) {
      final statusCode = err.response!.statusCode;
      if (statusCode == 408) {
        return true;
      }
    }

    return false;
  }
}

