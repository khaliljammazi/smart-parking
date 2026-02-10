import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../authentication/auth_service.dart';

class PaymentService {
  static String get baseUrl => AuthService.baseUrl;

  // Generate payment QR code for a booking
  static Future<Map<String, dynamic>?> generatePaymentQR({
    required String bookingId,
    required double amount,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/payments/generate-qr'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'bookingId': bookingId,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating payment QR: $e');
      }
      return null;
    }
  }

  // Scan and process payment QR code
  static Future<Map<String, dynamic>?> processPaymentQR({
    required String qrCode,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/payments/process-qr'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'qrCode': qrCode,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error processing payment QR: $e');
      }
      return null;
    }
  }

  // Verify payment status
  static Future<Map<String, dynamic>?> verifyPayment({
    required String bookingId,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/payments/verify/$bookingId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying payment: $e');
      }
      return null;
    }
  }

  // Get payment history
  static Future<List<dynamic>?> getPaymentHistory() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/payments/history'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['payments'] ?? [];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching payment history: $e');
      }
      return null;
    }
  }
}
