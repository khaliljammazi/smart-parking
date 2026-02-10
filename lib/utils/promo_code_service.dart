import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../authentication/auth_service.dart';

class PromoCodeService {
  static String get baseUrl => AuthService.baseUrl;

  // Validate and apply promo code
  static Future<Map<String, dynamic>?> validatePromoCode({
    required String code,
    required String parkingId,
    double? bookingAmount,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/promo-codes/validate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'code': code,
          'parkingId': parkingId,
          if (bookingAmount != null) 'amount': bookingAmount,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error validating promo code: $e');
      }
      return null;
    }
  }

  // Apply promo code to booking
  static Future<Map<String, dynamic>?> applyPromoCode({
    required String bookingId,
    required String promoCode,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/bookings/$bookingId/apply-promo'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'promoCode': promoCode,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error applying promo code: $e');
      }
      return null;
    }
  }

  // Get available promo codes
  static Future<List<dynamic>?> getAvailablePromoCodes() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/promo-codes/available'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['promoCodes'] ?? [];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching promo codes: $e');
      }
      return null;
    }
  }

  // Get user's promo code usage history
  static Future<List<dynamic>?> getPromoCodeHistory() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/promo-codes/history'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['history'] ?? [];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching promo code history: $e');
      }
      return null;
    }
  }

  // Calculate discount amount
  static double calculateDiscount({
    required double originalAmount,
    required String discountType,
    required dynamic discountValue,
  }) {
    if (discountType == 'percentage') {
      final percentage = double.tryParse(discountValue.toString()) ?? 0;
      return originalAmount * (percentage / 100);
    } else if (discountType == 'fixed') {
      return double.tryParse(discountValue.toString()) ?? 0;
    }
    return 0;
  }

  // Format promo code discount text
  static String formatDiscountText({
    required String discountType,
    required dynamic discountValue,
  }) {
    if (discountType == 'percentage') {
      return '${discountValue}% de réduction';
    } else if (discountType == 'fixed') {
      return '$discountValue DT de réduction';
    }
    return 'Réduction';
  }
}
