import 'dart:convert';
import 'package:http/http.dart' as http;
import '../authentication/auth_service.dart';

class RatingService {
  static String get baseUrl => AuthService.baseUrl;

  /// Fetch paginated ratings for a parking
  static Future<Map<String, dynamic>?> getParkingRatings(
    String parkingId, {
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/$parkingId?page=$page&limit=$limit'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Error fetching parking ratings: $e');
      return null;
    }
  }
}
