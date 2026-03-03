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

  // Get all users
  static Future<Map<String, dynamic>?> getUsers({
    int page = 1,
    int limit = 10,
    String? role,
    String? search,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (role != null) 'role': role,
        if (search != null) 'search': search,
      };

      final uri = Uri.parse('$baseUrl/admin/users').replace(queryParameters: queryParams);

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
      print('Get users error: $e');
      return null;
    }
  }

  // Delete user
  static Future<bool> deleteUser(String userId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Delete user error: $e');
      return false;
    }
  }

  // Update user role (Super Admin only)
  static Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/role'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'role': newRole}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Update user role error: $e');
      return false;
    }
  }

  // Create parking
  static Future<Map<String, dynamic>?> createParking(Map<String, dynamic> parkingData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/admin/parkings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(parkingData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Create parking error: $e');
      return null;
    }
  }

  // Update parking
  static Future<bool> updateParking(String parkingId, Map<String, dynamic> parkingData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/admin/parkings/$parkingId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(parkingData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Update parking error: $e');
      return false;
    }
  }

  // Delete parking
  static Future<bool> deleteParking(String parkingId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/parkings/$parkingId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Delete parking error: $e');
      return false;
    }
  }

  // Get all admin users (Super Admin only)
  static Future<List<dynamic>?> getAdmins() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/admin/admins'),
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
      print('Get admins error: $e');
      return null;
    }
  }

  // Create admin user (Super Admin only)
  static Future<bool> createAdmin(Map<String, dynamic> adminData) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/admin/admins'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(adminData),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Create admin error: $e');
      return false;
    }
  }

  // Delete admin user (Super Admin only)
  static Future<bool> deleteAdmin(String userId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/admins/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Delete admin error: $e');
      return false;
    }
  }

  // Get support tickets (admin)
  static Future<Map<String, dynamic>?> getSupportTickets({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
      };

      final uri = Uri.parse('$baseUrl/admin/support/tickets').replace(queryParameters: queryParams);

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
      print('Get support tickets error: $e');
      return null;
    }
  }

  // Update support ticket status
  static Future<bool> updateSupportTicketStatus(String ticketId, String status) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/admin/support/tickets/$ticketId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({ 'status': status }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Update support ticket status error: $e');
      return false;
    }
  }

  // Reply to support ticket (sends email to user)
  static Future<bool> replyToSupportTicket(String ticketId, String response, {String? newStatus}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final res = await http.put(
        Uri.parse('$baseUrl/admin/support/tickets/$ticketId/respond'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'response': response,
          if (newStatus != null) 'newStatus': newStatus,
        }),
      );

      return res.statusCode == 200;
    } catch (e) {
      print('Reply to support ticket error: $e');
      return false;
    }
  }

  // Get all bookings (admin)
  static Future<Map<String, dynamic>?> getAllBookings({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null && status != 'all') 'status': status,
      };

      final uri = Uri.parse('$baseUrl/admin/bookings').replace(queryParameters: queryParams);

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
      print('Get all bookings error: $e');
      return null;
    }
  }

  // Delete booking (admin)
  static Future<bool> deleteBooking(String bookingId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/bookings/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Delete booking error: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════
  //  REVIEW ANALYTICS & MANAGEMENT
  // ═══════════════════════════════════════════

  // Get review analytics dashboard data
  static Future<Map<String, dynamic>?> getReviewAnalytics() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/admin/reviews/analytics'),
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
      print('Get review analytics error: $e');
      return null;
    }
  }

  // Get all reviews (admin)
  static Future<Map<String, dynamic>?> getAllReviews({
    int page = 1,
    int limit = 20,
    int? minRating,
    int? maxRating,
    bool? hasReply,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (minRating != null) 'minRating': minRating.toString(),
        if (maxRating != null) 'maxRating': maxRating.toString(),
        if (hasReply != null) 'hasReply': hasReply.toString(),
      };

      final uri = Uri.parse('$baseUrl/admin/reviews').replace(queryParameters: queryParams);

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
      print('Get all reviews error: $e');
      return null;
    }
  }

  // Reply to a review (admin/owner)
  static Future<bool> replyToReview(String reviewId, String reply) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/admin/reviews/$reviewId/reply'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'reply': reply}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Reply to review error: $e');
      return false;
    }
  }

  // Delete a review (moderation)
  static Future<bool> deleteReview(String reviewId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/reviews/$reviewId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Delete review error: $e');
      return false;
    }
  }
}