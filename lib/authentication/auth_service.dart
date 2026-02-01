import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String get baseUrl {
    // For web, use the current origin, for mobile use localhost
    if (kIsWeb) {
      return '${Uri.base.scheme}://${Uri.base.host}:5000/api';
    }
    return 'http://localhost:5000/api';
  }
  static const _storage = FlutterSecureStorage();
  static late SharedPreferences _prefs;

  static Future<void> _initPrefs() async {
    if (kIsWeb && !_prefsInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _prefsInitialized = true;
    }
  }

  static bool _prefsInitialized = false;

  // Store tokens securely
  static Future<void> storeToken(String token) async {
    await _initPrefs();
    if (kIsWeb) {
      await _prefs.setString('auth_token', token);
    } else {
      await _storage.write(key: 'auth_token', value: token);
    }
  }

  static Future<String?> getToken() async {
    await _initPrefs();
    if (kIsWeb) {
      return _prefs.getString('auth_token');
    } else {
      return await _storage.read(key: 'auth_token');
    }
  }

  static Future<void> logout() async {
    await _initPrefs();
    if (kIsWeb) {
      await _prefs.remove('auth_token');
    } else {
      await _storage.delete(key: 'auth_token');
    }
  }

  // Remember me functionality
  static Future<void> saveEmail(String email) async {
    await _initPrefs();
    if (kIsWeb) {
      await _prefs.setString('saved_email', email);
    } else {
      await _storage.write(key: 'saved_email', value: email);
    }
  }

  static Future<String?> getSavedEmail() async {
    await _initPrefs();
    if (kIsWeb) {
      return _prefs.getString('saved_email');
    } else {
      return await _storage.read(key: 'saved_email');
    }
  }

  static Future<void> clearSavedEmail() async {
    await _initPrefs();
    if (kIsWeb) {
      await _prefs.remove('saved_email');
    } else {
      await _storage.delete(key: 'saved_email');
    }
  }

  static Future<void> setRememberMePreference(bool value) async {
    await _initPrefs();
    if (kIsWeb) {
      await _prefs.setBool('remember_me', value);
    } else {
      await _storage.write(key: 'remember_me', value: value.toString());
    }
  }

  static Future<bool> getRememberMePreference() async {
    await _initPrefs();
    if (kIsWeb) {
      return _prefs.getBool('remember_me') ?? false;
    } else {
      final value = await _storage.read(key: 'remember_me');
      return value == 'true';
    }
  }

  // OAuth URLs
  static String getGoogleAuthUrl() {
    return '$baseUrl/auth/google';
  }

  // Handle OAuth callback
  static Future<bool> handleAuthCallback(String url) async {
    try {
      // Parse the callback URL to extract token
      final uri = Uri.parse(url);
      final token = uri.queryParameters['token'];
      final provider = uri.queryParameters['provider'];

      if (token != null && provider != null) {
        await storeToken(token);
        return true;
      }
      return false;
    } catch (e) {
      print('Error handling auth callback: $e');
      return false;
    }
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Get user profile (if needed)
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  static Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updates),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Login with email and password
  static Future<Map<String, dynamic>?> loginWithEmail(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error logging in: $e');
      return null;
    }
  }

  // Request password reset OTP
  static Future<Map<String, dynamic>?> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      print('Error requesting password reset: $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }

  // Reset password with OTP
  static Future<Map<String, dynamic>?> resetPassword(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      print('Error resetting password: $e');
      return {'success': false, 'message': 'Network error. Please try again.'};
    }
  }
}