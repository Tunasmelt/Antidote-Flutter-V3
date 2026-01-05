import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/analysis.dart';
import '../models/battle.dart';
import '../config/env_config.dart';
import '../services/cache_service.dart';
import '../services/retry_interceptor.dart';
import '../services/request_deduplication_interceptor.dart';
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
    // Add request deduplication interceptor (first to catch all requests)
    _dio.interceptors.add(RequestDeduplicationInterceptor());

    // Add retry interceptor (before other interceptors)
    if (EnvConfig.enableRetryLogic) {
      _dio.interceptors.add(RetryInterceptor());
    }

    // Add auth interceptor to include auth token and Spotify token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add Supabase auth token if available
        if (_authService != null) {
          try {
            final token = _authService.getAuthToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            // Continue without auth token - guest mode
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
              // This allows guest mode to work for features that support it
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
            error:
                'Connection failed. Make sure the backend server is running on $baseUrl',
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
      final response = await _dio.post(
        '/api/analyze',
        data: {'url': url},
      );
      return PlaylistAnalysis.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<BattleResult> battlePlaylists(String url1, String url2) async {
    try {
      final response = await _dio.post(
        '/api/battle',
        data: {'url1': url1, 'url2': url2},
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
      final response =
          await _dio.get('/api/recommendations', queryParameters: queryParams);
      if (response.data == null) {
        return [];
      }
      if (response.data is! List) {
        throw ApiException(
            message: 'Invalid response format: expected array',
            statusCode: 500);
      }
      return (response.data as List).map((json) {
        if (json is Map) {
          return Map<String, dynamic>.from(json);
        }
        return <String, dynamic>{};
      }).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final response = await _dio.get('/api/history');
      if (response.data == null) {
        return [];
      }
      if (response.data is! List) {
        return [];
      }
      return (response.data as List).map((json) {
        if (json is Map) {
          return Map<String, dynamic>.from(json);
        }
        return <String, dynamic>{};
      }).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getSavedPlaylists() async {
    try {
      final response = await _dio.get('/api/playlists');
      if (response.data == null) {
        return [];
      }
      if (response.data is! List) {
        return [];
      }
      return (response.data as List).map((json) {
        if (json is Map) {
          return Map<String, dynamic>.from(json);
        }
        return <String, dynamic>{};
      }).toList();
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

  Future<Map<String, dynamic>> getTopTracks(
      {String timeRange = 'medium_term'}) async {
    try {
      final response = await _dio.get('/api/user/top-tracks',
          queryParameters: {'time_range': timeRange});
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getTopArtists(
      {String timeRange = 'medium_term'}) async {
    try {
      final response = await _dio.get('/api/user/top-artists',
          queryParameters: {'time_range': timeRange});
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getRecentlyPlayed({int limit = 50}) async {
    try {
      final response = await _dio
          .get('/api/user/recently-played', queryParameters: {'limit': limit});
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getSavedTracks(
      {int limit = 50, int offset = 0}) async {
    try {
      final response = await _dio.get('/api/user/saved-tracks',
          queryParameters: {'limit': limit, 'offset': offset});
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getSavedAlbums(
      {int limit = 50, int offset = 0}) async {
    try {
      final response = await _dio.get('/api/user/saved-albums',
          queryParameters: {'limit': limit, 'offset': offset});
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getEnhancedTasteProfile() async {
    try {
      final response = await _dio.get('/api/profile/taste');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> analyzeMood({int limit = 20}) async {
    try {
      final response =
          await _dio.post('/api/mood/analyze', data: {'limit': limit});
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> generateMoodPlaylist(
      {String? mood, int limit = 20}) async {
    try {
      final response = await _dio
          .post('/api/mood/playlist', data: {'mood': mood, 'limit': limit});
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getListeningPersonality() async {
    try {
      final response = await _dio.get('/api/personality/listening');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> optimizePlaylist(
      {String? playlistId, String? url}) async {
    try {
      final response = await _dio.post('/api/playlists/optimize',
          data: {'playlistId': playlistId, 'url': url});
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> generatePlaylist(
      {String? type, String? mood, String? activity, int limit = 30}) async {
    try {
      final response = await _dio.post('/api/playlists/generate', data: {
        'type': type,
        'mood': mood,
        'activity': activity,
        'limit': limit,
      });
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDiscoveryTimeline() async {
    try {
      final response = await _dio.get('/api/discovery/timeline');
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
      final response = await _dio.post(
        '/api/playlists',
        data: {
          'name': name,
          'description': description,
          'tracks': tracks,
          'coverUrl': coverUrl,
        },
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

  Future<Map<String, dynamic>> createMergedPlaylist({
    required String name,
    String? description,
    required List<String> trackIds,
  }) async {
    try {
      final response = await _dio.post(
        '/api/playlists/merge',
        data: {
          'name': name,
          if (description != null) 'description': description,
          'track_ids': trackIds,
        },
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Note: Analysis and Battle are automatically saved by backend when called with authentication
  // These methods are kept for potential future use but are currently no-ops
  // The backend saves to database automatically when user is authenticated

  Future<Map<String, dynamic>> savePlaylist({
    required String url,
    String? name,
    String? description,
    String? coverUrl,
  }) async {
    try {
      final requestData = {
        'url': url,
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (coverUrl != null) 'coverUrl': coverUrl,
      };

      final response = await _dio.post(
        '/api/playlists/save',
        data: requestData,
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getUserSpotifyPlaylists() async {
    try {
      final response = await _dio.get('/api/spotify/playlists');
      if (response.data == null) {
        return [];
      }
      if (response.data is! List) {
        return [];
      }
      // Filter out invalid entries and ensure all playlists have required fields
      return (response.data as List)
          .map((json) {
            if (json is Map) {
              return Map<String, dynamic>.from(json);
            }
            return null;
          })
          .where((playlist) => playlist != null && playlist['id'] != null)
          .cast<Map<String, dynamic>>()
          .toList();
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
      '/api/spotify/playlists',
      '/api/user/top-tracks',
      '/api/user/top-artists',
      '/api/user/recently-played',
      '/api/user/saved-tracks',
      '/api/user/saved-albums',
      '/api/profile/taste',
      '/api/mood/analyze',
      '/api/mood/playlist',
      '/api/personality/listening',
      '/api/playlists/optimize',
      '/api/playlists/generate',
      '/api/discovery/timeline',
    ];
    return spotifyEndpoints.any((endpoint) => path.contains(endpoint));
  }

  Future<List<Map<String, dynamic>>> getRecommendationStrategies() async {
    try {
      final response = await _dio.get('/api/recommendations/strategies');
      if (response.data == null) {
        return [];
      }
      if (response.data is! List) {
        return [];
      }
      return (response.data as List).map((json) {
        if (json is Map) {
          return Map<String, dynamic>.from(json);
        }
        return <String, dynamic>{};
      }).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> saveLikedTrack({
    required String trackId,
    required String trackName,
    required String artistName,
    String? albumArtUrl,
    String? previewUrl,
  }) async {
    try {
      final requestData = {
        'track_id': trackId,
        'track_name': trackName,
        'artist_name': artistName,
        if (albumArtUrl != null) 'album_art_url': albumArtUrl,
        if (previewUrl != null) 'preview_url': previewUrl,
      };

      await _dio.post('/api/liked-tracks', data: requestData);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteLikedTrack(String id) async {
    try {
      await _dio.delete('/api/liked-tracks/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getLikedTracks() async {
    try {
      final response = await _dio.get('/api/liked-tracks');
      if (response.data == null) {
        return [];
      }
      if (response.data is! List) {
        return [];
      }
      return (response.data as List).map((json) {
        if (json is Map) {
          return Map<String, dynamic>.from(json);
        }
        return <String, dynamic>{};
      }).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
            message:
                'Connection timeout. Please check your internet connection.',
            statusCode: 408);
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['message'] ??
            error.response?.data?['error'] ??
            'Unknown error occurred';
        return ApiException(
            message: message.toString(), statusCode: statusCode);
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
