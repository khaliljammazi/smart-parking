import 'dart:convert';
import 'package:http/http.dart' as http;
import '../authentication/auth_service.dart';

class AdminService {
  static const String baseUrl = 'http://localhost:5000/api';

  // Get admin dashboard data
  static Future<Map<String, dynamic>?> getDashboardData() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/admin/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Get dashboard data error: $e');
      return null;
    }
  }

  // Get revenue data
  static Future<Map<String, dynamic>?> getRevenueData({
    String? startDate,
    String? endDate,
    String period = 'month',
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final queryParams = {
        'period': period,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final uri = Uri.parse('$baseUrl/admin/revenue').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Get revenue data error: $e');
      return null;
    }
  }
}