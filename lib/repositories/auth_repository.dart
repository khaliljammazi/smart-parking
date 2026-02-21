import 'dart:convert';
import 'package:http/http.dart' as http;
import '../authentication/auth_service.dart';
import 'base_repository.dart';
import 'local_storage_service.dart';

/// Repository for handling authentication-related data operations
/// 
/// This repository manages:
/// - User authentication (login, logout, registration)
/// - User profile data with caching
/// - Token management
/// - Session persistence
class AuthRepository extends BaseRepository {
  final LocalStorageService _localStorage;

  AuthRepository({LocalStorageService? localStorage})
      : _localStorage = localStorage ?? LocalStorageService();

  /// Login with email and password
  /// 
  /// Returns user data and token on success
  Future<Result<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    return executeOperation(() async {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['data']?['token'] ?? data['token'];
        
        if (token != null) {
          await AuthService.storeToken(token);
          
          // Cache user profile
          final userData = data['data']?['user'] ?? data['user'];
          if (userData != null) {
            await _localStorage.cacheUserProfile(userData);
          }
        }
        
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Login failed');
      }
    }, errorMessage: 'Failed to login. Please check your credentials.');
  }

  /// Register new user
  Future<Result<Map<String, dynamic>>> register(
    Map<String, dynamic> userData,
  ) async {
    return executeOperation(() async {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(userData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['data']?['token'] ?? data['token'];
        
        if (token != null) {
          await AuthService.storeToken(token);
        }
        
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Registration failed');
      }
    }, errorMessage: 'Failed to register. Please try again.');
  }

  /// Get user profile with caching
  /// 
  /// [forceRefresh] - if true, bypasses cache and fetches fresh data
  Future<Result<Map<String, dynamic>>> getUserProfile({
    bool forceRefresh = false,
  }) async {
    return executeOperation(() async {
      // Try cache first if not forcing refresh
      if (!forceRefresh) {
        final cached = await _localStorage.getCachedUserProfile();
        if (cached != null) {
          return cached;
        }
      }

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profile = data['data']?['user'] ?? data['user'] ?? data;
        
        // Cache the profile
        await _localStorage.cacheUserProfile(profile);
        
        return profile;
      } else {
        throw Exception('Failed to load profile');
      }
    }, errorMessage: 'Failed to load user profile');
  }

  /// Update user profile
  Future<Result<Map<String, dynamic>>> updateUserProfile(
    Map<String, dynamic> updates,
  ) async {
    return executeOperation(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final profile = data['data']?['user'] ?? data['user'] ?? data;
        
        // Update cache
        await _localStorage.cacheUserProfile(profile);
        
        return profile;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Update failed');
      }
    }, errorMessage: 'Failed to update profile');
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await AuthService.getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout user and clear all cached data
  Future<Result<bool>> logout() async {
    return executeBoolOperation(() async {
      await AuthService.logout();
      await _localStorage.clearAllCaches();
      return true;
    }, errorMessage: 'Failed to logout');
  }

  /// Change password
  Future<Result<bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return executeBoolOperation(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/users/password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      return response.statusCode == 200;
    }, errorMessage: 'Failed to change password');
  }

  /// Reset password request
  Future<Result<bool>> requestPasswordReset(String email) async {
    return executeBoolOperation(() async {
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      return response.statusCode == 200;
    }, errorMessage: 'Failed to send password reset email');
  }

  /// Clear cached user data
  Future<void> clearCache() async {
    await _localStorage.clearCache('cached_user_profile');
  }
}
