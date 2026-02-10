import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../authentication/auth_service.dart';

class RatingService {
  static String get baseUrl => AuthService.baseUrl;

  // Submit a rating and review for a parking spot
  static Future<Map<String, dynamic>?> submitRating({
    required String parkingId,
    required double rating,
    String? review,
    List<String>? tags,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/ratings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'parkingId': parkingId,
          'rating': rating,
          if (review != null) 'review': review,
          if (tags != null && tags.isNotEmpty) 'tags': tags,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting rating: $e');
      }
      return null;
    }
  }

  // Get ratings for a parking spot
  static Future<Map<String, dynamic>?> getParkingRatings({
    required String parkingId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/$parkingId?page=$page&limit=$limit'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching ratings: $e');
      }
      return null;
    }
  }

  // Get user's own ratings
  static Future<List<dynamic>?> getMyRatings() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/ratings/my-ratings'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['ratings'] ?? [];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching my ratings: $e');
      }
      return null;
    }
  }

  // Update a rating
  static Future<Map<String, dynamic>?> updateRating({
    required String ratingId,
    required double rating,
    String? review,
    List<String>? tags,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.put(
        Uri.parse('$baseUrl/ratings/$ratingId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'rating': rating,
          if (review != null) 'review': review,
          if (tags != null && tags.isNotEmpty) 'tags': tags,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating rating: $e');
      }
      return null;
    }
  }

  // Delete a rating
  static Future<bool> deleteRating(String ratingId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/ratings/$ratingId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting rating: $e');
      }
      return false;
    }
  }

  // Report a review
  static Future<bool> reportReview({
    required String ratingId,
    required String reason,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/ratings/$ratingId/report'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'reason': reason,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error reporting review: $e');
      }
      return false;
    }
  }
}
