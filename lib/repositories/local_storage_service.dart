import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for managing local storage with caching capabilities
class LocalStorageService {
  static const String _parkingCacheKey = 'cached_parkings';
  static const String _parkingCacheTimeKey = 'cached_parkings_time';
  static const String _userProfileCacheKey = 'cached_user_profile';
  static const String _userProfileCacheTimeKey = 'cached_user_profile_time';
  static const String _vehiclesCacheKey = 'cached_vehicles';
  static const String _vehiclesCacheTimeKey = 'cached_vehicles_time';
  
  // Cache duration: 5 minutes for most data
  static const Duration _defaultCacheDuration = Duration(minutes: 5);
  
  /// Cache data with timestamp
  Future<bool> cacheData(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = json.encode(data);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      await prefs.setString(key, jsonData);
      await prefs.setInt('${key}_time', timestamp);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Cache error: $e');
      }
      return false;
    }
  }

  /// Get cached data if not expired
  Future<dynamic> getCachedData(
    String key, {
    Duration cacheDuration = _defaultCacheDuration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(key);
      final timestamp = prefs.getInt('${key}_time');
      
      if (jsonData == null || timestamp == null) {
        return null;
      }
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      
      if (now.difference(cacheTime) > cacheDuration) {
        // Cache expired
        await clearCache(key);
        return null;
      }
      
      return json.decode(jsonData);
    } catch (e) {
      if (kDebugMode) {
        print('Get cache error: $e');
      }
      return null;
    }
  }

  /// Clear specific cache
  Future<void> clearCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      await prefs.remove('${key}_time');
    } catch (e) {
      if (kDebugMode) {
        print('Clear cache error: $e');
      }
    }
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = [
        _parkingCacheKey,
        _parkingCacheTimeKey,
        _userProfileCacheKey,
        _userProfileCacheTimeKey,
        _vehiclesCacheKey,
        _vehiclesCacheTimeKey,
      ];
      
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Clear all caches error: $e');
      }
    }
  }

  /// Check if cache exists and is valid
  Future<bool> isCacheValid(
    String key, {
    Duration cacheDuration = _defaultCacheDuration,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt('${key}_time');
      
      if (timestamp == null) return false;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      
      return now.difference(cacheTime) <= cacheDuration;
    } catch (e) {
      return false;
    }
  }

  // Specific cache methods for common use cases
  
  Future<bool> cacheParkings(List<dynamic> parkings) async {
    return await cacheData(_parkingCacheKey, parkings);
  }

  Future<List<dynamic>?> getCachedParkings() async {
    final data = await getCachedData(_parkingCacheKey);
    return data != null ? List<dynamic>.from(data) : null;
  }

  Future<bool> cacheUserProfile(Map<String, dynamic> profile) async {
    return await cacheData(_userProfileCacheKey, profile);
  }

  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    final data = await getCachedData(_userProfileCacheKey);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  Future<bool> cacheVehicles(List<dynamic> vehicles) async {
    return await cacheData(_vehiclesCacheKey, vehicles);
  }

  Future<List<dynamic>?> getCachedVehicles() async {
    final data = await getCachedData(_vehiclesCacheKey);
    return data != null ? List<dynamic>.from(data) : null;
  }
}
