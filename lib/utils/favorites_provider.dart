import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../authentication/auth_service.dart';

class FavoritesProvider with ChangeNotifier {
  static const String _favoritesKey = 'favorite_parkings';
  
  Set<String> _favoriteIds = {};
  bool _isLoading = false;
  bool _isSynced = false;

  Set<String> get favoriteIds => _favoriteIds;
  bool get isLoading => _isLoading;

  FavoritesProvider() {
    _initializeFavorites();
  }

  Future<void> _initializeFavorites() async {
    // Load from local storage first
    await _loadLocalFavorites();
    // Then sync with backend
    await syncWithBackend();
  }

  Future<void> _loadLocalFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getString(_favoritesKey);
    
    if (favoritesJson != null) {
      final List<dynamic> decoded = json.decode(favoritesJson);
      _favoriteIds = decoded.map((e) => e.toString()).toSet();
      notifyListeners();
    }
  }

  Future<void> _saveLocalFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = json.encode(_favoriteIds.toList());
    await prefs.setString(_favoritesKey, favoritesJson);
  }

  // Sync favorites with backend
  Future<void> syncWithBackend() async {
    if (_isSynced) return;
    
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        // User not logged in, use local storage only
        return;
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/users/favorites'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final favorites = data['data']?['favorites'] as List?;
        
        if (favorites != null) {
          _favoriteIds = favorites
              .map((f) => (f['_id'] ?? f['id']).toString())
              .toSet();
          await _saveLocalFavorites();
          _isSynced = true;
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sync favorites error: $e');
      }
      // Continue with local storage if sync fails
    }
  }

  bool isFavorite(String parkingId) {
    return _favoriteIds.contains(parkingId);
  }

  Future<void> toggleFavorite(String parkingId) async {
    if (_favoriteIds.contains(parkingId)) {
      await removeFavorite(parkingId);
    } else {
      await addFavorite(parkingId);
    }
  }

  Future<void> addFavorite(String parkingId) async {
    if (_favoriteIds.contains(parkingId)) return;

    // Optimistic update
    _favoriteIds.add(parkingId);
    notifyListeners();
    await _saveLocalFavorites();

    // Sync with backend
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      _isLoading = true;
      notifyListeners();

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/users/favorites/$parkingId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      _isLoading = false;

      if (response.statusCode != 200) {
        // Rollback on failure
        _favoriteIds.remove(parkingId);
        await _saveLocalFavorites();
        notifyListeners();
        if (kDebugMode) {
          print('Failed to add favorite to backend');
        }
      }
    } catch (e) {
      _isLoading = false;
      if (kDebugMode) {
        print('Add favorite error: $e');
      }
      // Keep local change even if backend fails
    }
  }

  Future<void> removeFavorite(String parkingId) async {
    if (!_favoriteIds.contains(parkingId)) return;

    // Optimistic update
    _favoriteIds.remove(parkingId);
    notifyListeners();
    await _saveLocalFavorites();

    // Sync with backend
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      _isLoading = true;
      notifyListeners();

      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/users/favorites/$parkingId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      _isLoading = false;

      if (response.statusCode != 200) {
        // Rollback on failure
        _favoriteIds.add(parkingId);
        await _saveLocalFavorites();
        notifyListeners();
        if (kDebugMode) {
          print('Failed to remove favorite from backend');
        }
      }
    } catch (e) {
      _isLoading = false;
      if (kDebugMode) {
        print('Remove favorite error: $e');
      }
      // Keep local change even if backend fails
    }
  }

  List<String> getFavorites() {
    return _favoriteIds.toList();
  }

  // Clear favorites (e.g., on logout)
  Future<void> clearFavorites() async {
    _favoriteIds.clear();
    _isSynced = false;
    await _saveLocalFavorites();
    notifyListeners();
  }
}
