import 'dart:convert';
import 'package:http/http.dart' as http;
import '../authentication/auth_service.dart';
import 'base_repository.dart';

/// Repository for managing booking operations
/// 
/// Handles:
/// - Creating new bookings
/// - Fetching user bookings
/// - Canceling bookings
/// - Booking status updates
class BookingRepository extends BaseRepository {
  /// Create a new booking/reservation
  Future<Result<Map<String, dynamic>>> createBooking({
    required String parkingId,
    String? vehicleId,
    DateTime? startTime,
    DateTime? endTime,
    int? durationHours,
    String? durationType,
  }) async {
    return executeOperation(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final body = <String, dynamic>{
        'parkingId': parkingId,
        if (vehicleId != null) 'vehicleId': vehicleId,
        if (startTime != null) 'startTime': startTime.toIso8601String(),
        if (endTime != null) 'endTime': endTime.toIso8601String(),
        if (durationHours != null) 'duration': durationHours,
        if (durationType != null) 'durationType': durationType,
      };

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/bookings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data']?['booking'] ?? data['booking'] ?? data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to create booking');
      }
    }, errorMessage: 'Failed to create booking. Please try again.');
  }

  /// Get all bookings for the current user
  Future<Result<List<Map<String, dynamic>>>> getUserBookings({
    String? status, // 'active', 'completed', 'cancelled'
  }) async {
    return executeOperation(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      var url = '${AuthService.baseUrl}/bookings/user';
      if (status != null) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bookings = data['data']?['bookings'] ?? 
                        data['bookings'] ?? 
                        [];
        return List<Map<String, dynamic>>.from(bookings);
      } else {
        throw Exception('Failed to load bookings');
      }
    }, errorMessage: 'Failed to load your bookings');
  }

  /// Get booking by ID
  Future<Result<Map<String, dynamic>>> getBookingById(String bookingId) async {
    return executeOperation(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/bookings/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['booking'] ?? data['booking'] ?? data;
      } else {
        throw Exception('Booking not found');
      }
    }, errorMessage: 'Failed to load booking details');
  }

  /// Cancel a booking
  Future<Result<bool>> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    return executeBoolOperation(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final body = <String, dynamic>{
        if (reason != null) 'reason': reason,
      };

      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/bookings/$bookingId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    }, errorMessage: 'Failed to cancel booking');
  }

  /// Update booking status (for admins/operators)
  Future<Result<Map<String, dynamic>>> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    return executeOperation(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/bookings/$bookingId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'status': status}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['booking'] ?? data['booking'] ?? data;
      } else {
        throw Exception('Failed to update status');
      }
    }, errorMessage: 'Failed to update booking status');
  }

  /// Complete a booking (check-out)
  Future<Result<Map<String, dynamic>>> completeBooking(String bookingId) async {
    return executeOperation(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/bookings/$bookingId/complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['booking'] ?? data['booking'] ?? data;
      } else {
        throw Exception('Failed to complete booking');
      }
    }, errorMessage: 'Failed to complete booking');
  }

  /// Get booking statistics
  Future<Result<Map<String, dynamic>>> getBookingStats() async {
    return executeOperation(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/bookings/stats'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? data;
      } else {
        throw Exception('Failed to load stats');
      }
    }, errorMessage: 'Failed to load booking statistics');
  }

  /// Verify booking with QR code
  Future<Result<Map<String, dynamic>>> verifyBooking(String qrCode) async {
    return executeOperation(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/bookings/verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'qrCode': qrCode}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['booking'] ?? data['booking'] ?? data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Invalid QR code');
      }
    }, errorMessage: 'Failed to verify booking');
  }
}
