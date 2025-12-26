import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/analysis.dart';
import '../models/battle.dart';
import '../config/env_config.dart';
import '../services/cache_service.dart';
import '../services/retry_interceptor.dart';
import '../services/auth_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  final Dio _dio;
  final String baseUrl;
  final AuthService? _authService;

  ApiClient({String? baseUrl, AuthService? authService})
      : baseUrl = baseUrl ?? EnvConfig.apiBaseUrl,
        _authService = authService,
        _dio = Dio(BaseOptions(
          baseUrl: baseUrl ?? EnvConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        )) {
    // Add retry interceptor (before other interceptors)
    if (EnvConfig.enableRetryLogic) {
      _dio.interceptors.add(RetryInterceptor());
    }

    // Add auth interceptor to include auth token and Spotify token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add Supabase auth token if available
        if (_authService != null) {
          final token = _authService.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Add Spotify access token for endpoints that need it
          final needsSpotifyToken = _needsSpotifyToken(options.path);
          if (needsSpotifyToken) {
            try {
              final spotifyToken = await _authService.getSpotifyAccessToken();
              if (spotifyToken != null && spotifyToken.isNotEmpty) {
                options.headers['X-Spotify-Token'] = spotifyToken;
              }
            } catch (e) {
              // If token fetch fails, continue without it
              // Backend will handle the error appropriately
            }
          }
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle Spotify token expiration (401)
        if (error.response?.statusCode == 401 && 
            _needsSpotifyToken(error.requestOptions.path)) {
          // Try to refresh token and retry
          if (_authService != null) {
            try {
              final newToken = await _authService.refreshSpotifyToken();
              if (newToken != null) {
                // Retry the request with new token
                final opts = error.requestOptions;
                opts.headers['X-Spotify-Token'] = newToken;
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              }
            } catch (e) {
              // Refresh failed, continue with original error
            }
          }
        }
        return handler.next(error);
      },
    ));

    // Add cache interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Check cache for GET requests
        if (options.method == 'GET' && EnvConfig.enableOfflineCache) {
          final cacheKey = CacheService.generateCacheKey(
            options.method,
            options.path,
            options.queryParameters,
          );
          final cached = await CacheService.get(cacheKey);
          if (cached != null) {
            // Return cached response
            return handler.resolve(
              Response(
                requestOptions: options,
                data: cached,
                statusCode: 200,
              ),
            );
          }
        }
        return handler.next(options);
      },
      onResponse: (response, handler) async {
        // Cache successful GET responses
        if (response.requestOptions.method == 'GET' && 
            EnvConfig.enableOfflineCache &&
            response.statusCode == 200) {
          final cacheKey = CacheService.generateCacheKey(
            response.requestOptions.method,
            response.requestOptions.path,
            response.requestOptions.queryParameters,
          );
          await CacheService.set(cacheKey, response.data);
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        // Handle CORS errors
        if (error.type == DioExceptionType.connectionError) {
          return handler.reject(DioException(
            requestOptions: error.requestOptions,
            error: 'Connection failed. Make sure the backend server is running on $baseUrl',
            type: DioExceptionType.connectionError,
          ));
        }
        return handler.next(error);
      },
    ));

    // Only log in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ));
    }
  }

  Future<PlaylistAnalysis> analyzePlaylist(String url) async {
    try {
      // Include Spotify token in request body as well (for backend compatibility)
      final requestData = {'url': url};
      if (_authService != null) {
        final spotifyToken = await _authService.getSpotifyAccessToken();
        if (spotifyToken != null) {
          requestData['spotify_token'] = spotifyToken;
        }
      }

      final response = await _dio.post(
        '/api/analyze',
        data: requestData,
      );
      return PlaylistAnalysis.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BattleResult> battlePlaylists(String url1, String url2) async {
    try {
      // Include Spotify token in request body
      final requestData = {'url1': url1, 'url2': url2};
      if (_authService != null) {
        final spotifyToken = await _authService.getSpotifyAccessToken();
        if (spotifyToken != null) {
          requestData['spotify_token'] = spotifyToken;
        }
      }

      final response = await _dio.post(
        '/api/battle',
        data: requestData,
      );
      return BattleResult.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getRecommendations({
    String? type,
    String? playlistId,
    String? seedTracks,
    String? seedGenres,
    String? seedArtists,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null) queryParams['type'] = type;
      if (playlistId != null) queryParams['playlistId'] = playlistId;
      if (seedTracks != null) queryParams['seed_tracks'] = seedTracks;
      if (seedGenres != null) queryParams['seed_genres'] = seedGenres;
      if (seedArtists != null) queryParams['seed_artists'] = seedArtists;

      // Spotify token will be added via interceptor header
      final response = await _dio.get('/api/recommendations', queryParameters: queryParams);
      return (response.data as List).map((json) => Map<String, dynamic>.from(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final response = await _dio.get('/api/history');
      return (response.data as List).map((json) => Map<String, dynamic>.from(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getSavedPlaylists() async {
    try {
      final response = await _dio.get('/api/playlists');
      return (response.data as List).map((json) => Map<String, dynamic>.from(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dio.get('/api/stats');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createPlaylist({
    required String name,
    String? description,
    required List<Map<String, dynamic>> tracks,
    String? coverUrl,
  }) async {
    try {
      // Include Spotify token in request body
      final requestData = {
        'name': name,
        'description': description,
        'tracks': tracks,
        'coverUrl': coverUrl,
      };
      if (_authService != null) {
        final spotifyToken = await _authService.getSpotifyAccessToken();
        if (spotifyToken != null) {
          requestData['spotify_token'] = spotifyToken;
        }
      }

      final response = await _dio.post(
        '/api/playlists',
        data: requestData,
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    try {
      await _dio.delete('/api/playlists/$playlistId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Check if endpoint needs Spotify token
  bool _needsSpotifyToken(String path) {
    final spotifyEndpoints = [
      '/api/analyze',
      '/api/battle',
      '/api/recommendations',
      '/api/playlists',
    ];
    return spotifyEndpoints.any((endpoint) => path.contains(endpoint));
  }

  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(message: 'Connection timeout. Please check your internet connection.', statusCode: 408);
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ?? 
                       error.response?.data?['error'] ?? 
                       'Unknown error occurred';
        return ApiException(message: message.toString(), statusCode: statusCode);
      case DioExceptionType.cancel:
        return ApiException(message: 'Request cancelled', statusCode: 0);
      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: error.message ?? 'Network error. Please try again.',
          statusCode: null,
        );
    }
  }
}

