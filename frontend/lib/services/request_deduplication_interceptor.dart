import 'dart:async';
import 'package:dio/dio.dart';

/// Request deduplication interceptor for Dio
/// Prevents duplicate simultaneous API calls to the same endpoint
class RequestDeduplicationInterceptor extends Interceptor {
  final Map<String, Completer<Response>> _pendingRequests = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Only deduplicate GET requests
    if (options.method != 'GET') {
      return handler.next(options);
    }

    final requestKey = _generateRequestKey(options);

    // Check if there's already a pending request for this endpoint
    if (_pendingRequests.containsKey(requestKey)) {
      // Return the existing pending request
      _pendingRequests[requestKey]!.future.then(
            (response) => handler.resolve(response),
            onError: (error) => handler.reject(error as DioException),
          );
      return;
    }

    // Create a new completer for this request
    final completer = Completer<Response>();
    _pendingRequests[requestKey] = completer;

    // Continue with the request
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final requestKey = _generateRequestKey(response.requestOptions);

    // Complete the pending request
    if (_pendingRequests.containsKey(requestKey)) {
      _pendingRequests[requestKey]!.complete(response);
      _pendingRequests.remove(requestKey);
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestKey = _generateRequestKey(err.requestOptions);

    // Reject the pending request
    if (_pendingRequests.containsKey(requestKey)) {
      _pendingRequests[requestKey]!.completeError(err);
      _pendingRequests.remove(requestKey);
    }

    handler.next(err);
  }

  /// Generate a unique key for a request based on method, path, and params
  String _generateRequestKey(RequestOptions options) {
    final params = options.queryParameters.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    return '${options.method}_${options.path}_$params';
  }

  /// Clear all pending requests (useful for testing or logout)
  void clearPendingRequests() {
    _pendingRequests.clear();
  }
}
