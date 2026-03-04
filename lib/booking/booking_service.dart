import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../authentication/auth_service.dart';

class BookingService {
  static String get baseUrl => AuthService.baseUrl;

  // Create immediate reservation
  static Future<Map<String, dynamic>?> createReservation({
    required String parkingId,
    String? vehicleId,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/bookings/reserve'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'parkingId': parkingId,
          if (vehicleId != null) 'vehicleId': vehicleId,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        print('Reservation failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating reservation: $e');
      return null;
    }
  }

  // Check in to booking
  static Future<Map<String, dynamic>?> checkIn(String bookingId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/checkin'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('Check-in error: $e');
      return null;
    }
  }

  // Check out from booking
  static Future<Map<String, dynamic>?> checkOut(String bookingId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/checkout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('Check-out error: $e');
      return null;
    }
  }

  // Get user's bookings
  static Future<List<dynamic>?> getUserBookings() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/bookings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['bookings'] ?? [];
      }
      return null;
    } catch (e) {
      print('Get bookings error: $e');
      return null;
    }
  }

  // Get user's parking stats dashboard
  static Future<Map<String, dynamic>?> getMyStats() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/bookings/my-stats'),
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
      print('Get my stats error: $e');
      return null;
    }
  }

  // Get booking by ID
  static Future<Map<String, dynamic>?> getBookingById(String bookingId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/bookings/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['booking'];
      }
      return null;
    } catch (e) {
      print('Error getting booking: $e');
      return null;
    }
  }

  // Verify QR code (for entry)
  static Future<Map<String, dynamic>?> verifyQRCode(String qrCode) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/qr/verify'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'qrCode': qrCode}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error verifying QR code: $e');
      return null;
    }
  }

  // Admin validate QR code (for admin validation before check-in)
  static Future<Map<String, dynamic>?> adminValidateQRCode(String qrCode) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/qr/scan'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'qrCode': qrCode}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error validating QR code: $e');
      return null;
    }
  }

  // Complete booking (payment)
  static Future<bool> completeBooking({
    required String bookingId,
    String paymentMethod = 'cash',
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'paymentMethod': paymentMethod,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error completing booking: $e');
      return false;
    }
  }

  // Cancel booking
  static Future<Map<String, dynamic>?> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          if (reason != null) 'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final body = json.decode(response.body);
        return {'success': false, 'message': body['message'] ?? 'Erreur'};
      }
    } catch (e) {
      print('Error cancelling booking: $e');
      return null;
    }
  }

  // Modify booking (extend time)
  static Future<Map<String, dynamic>?> extendBooking({
    required String bookingId,
    required int additionalHours,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.put(
        Uri.parse('$baseUrl/bookings/$bookingId/extend'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'additionalHours': additionalHours,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error extending booking: $e');
      return null;
    }
  }

  // Calculate smart price preview
  static Future<Map<String, dynamic>?> calculateSmartPrice({
    required String parkingId,
    required String startTime,
    required String endTime,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/bookings/calculate-price'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'parkingId': parkingId,
          'startTime': startTime,
          'endTime': endTime,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Error calculating smart price: $e');
      return null;
    }
  }

  // Create recurring booking series
  static Future<Map<String, dynamic>?> createRecurringBooking({
    required String parkingId,
    String? vehicleId,
    required String pattern,
    List<int>? daysOfWeek,
    required int startHour,
    required int endHour,
    String? validUntil,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/bookings/recurring'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'parkingId': parkingId,
          if (vehicleId != null) 'vehicleId': vehicleId,
          'pattern': pattern,
          if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
          'startHour': startHour,
          'endHour': endHour,
          if (validUntil != null) 'validUntil': validUntil,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Error creating recurring booking: $e');
      return null;
    }
  }

  // Cancel all future recurring bookings
  static Future<Map<String, dynamic>?> cancelRecurringBookings(String parentId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.delete(
        Uri.parse('$baseUrl/bookings/recurring/$parentId'),
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
      print('Error cancelling recurring bookings: $e');
      return null;
    }
  }
}
