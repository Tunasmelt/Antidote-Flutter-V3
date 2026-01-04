import 'package:hive_flutter/hive_flutter.dart';
import '../config/env_config.dart';

/// Cache service for non-sensitive API response data
///
/// SECURITY WARNING: This service uses Hive which stores data unencrypted.
/// DO NOT use this for storing sensitive data like:
/// - Authentication tokens (use SecureTokenStorage instead)
/// - User credentials
/// - Personal identification information
///
/// This cache is intended for:
/// - API response data (playlists, tracks, analysis results)
/// - User preferences and settings
/// - Non-sensitive metadata
class CacheEntry {
  final String key;
  final dynamic data;
  final DateTime expiresAt;

  CacheEntry({
    required this.key,
    required this.data,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'key': key,
        'data': data,
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
        key: json['key'],
        data: json['data'],
        expiresAt: DateTime.parse(json['expiresAt']),
      );
}

class CacheService {
  static const String _cacheBoxName = 'api_cache';
  static Box? _cacheBox;

  static Future<void> init() async {
    if (!EnvConfig.enableOfflineCache) return;

    await Hive.initFlutter();
    _cacheBox = await Hive.openBox(_cacheBoxName);
  }

  // Get cached data
  static Future<T?> get<T>(String key) async {
    if (!EnvConfig.enableOfflineCache || _cacheBox == null) return null;

    try {
      final entryJson = _cacheBox!.get(key);
      if (entryJson == null) return null;

      final entry = CacheEntry.fromJson(Map<String, dynamic>.from(entryJson));

      if (entry.isExpired) {
        await delete(key);
        return null;
      }

      return entry.data as T?;
    } catch (e) {
      return null;
    }
  }

  // Set cached data
  static Future<void> set(String key, dynamic data,
      {Duration? expiration}) async {
    if (!EnvConfig.enableOfflineCache || _cacheBox == null) return;

    try {
      final expirationDuration = expiration ?? EnvConfig.cacheExpiration;
      final entry = CacheEntry(
        key: key,
        data: data,
        expiresAt: DateTime.now().add(expirationDuration),
      );

      await _cacheBox!.put(key, entry.toJson());
    } catch (e) {
      // Silently fail - caching is optional
    }
  }

  // Delete cached data
  static Future<void> delete(String key) async {
    if (_cacheBox == null) return;
    await _cacheBox!.delete(key);
  }

  // Clear all cache
  static Future<void> clear() async {
    if (_cacheBox == null) return;
    await _cacheBox!.clear();
  }

  // Get cache size
  static int get size => _cacheBox?.length ?? 0;

  // Check if key exists and is valid
  static Future<bool> exists(String key) async {
    if (!EnvConfig.enableOfflineCache || _cacheBox == null) return false;

    final entryJson = _cacheBox!.get(key);
    if (entryJson == null) return false;

    try {
      final entry = CacheEntry.fromJson(Map<String, dynamic>.from(entryJson));
      if (entry.isExpired) {
        await delete(key);
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Cache API response with automatic key generation
  static String generateCacheKey(
      String method, String path, Map<String, dynamic>? params) {
    final paramsStr =
        params?.entries.map((e) => '${e.key}=${e.value}').join('&') ?? '';
    return '${method}_${path}_$paramsStr';
  }
}
