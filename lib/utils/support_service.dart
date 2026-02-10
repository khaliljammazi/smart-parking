import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../authentication/auth_service.dart';

class SupportService {
  static String get baseUrl => AuthService.baseUrl;

  // Create a support ticket
  static Future<Map<String, dynamic>?> createSupportTicket({
    required String subject,
    required String message,
    required String category,
    List<String>? attachments,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/support/tickets'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'subject': subject,
          'message': message,
          'category': category,
          if (attachments != null && attachments.isNotEmpty) 
            'attachments': attachments,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating support ticket: $e');
      }
      return null;
    }
  }

  // Get all user support tickets
  static Future<List<dynamic>?> getUserTickets({
    String? status,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      String url = '$baseUrl/support/tickets';
      if (status != null) {
        url += '?status=$status';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['tickets'] ?? [];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching support tickets: $e');
      }
      return null;
    }
  }

  // Get ticket details with messages
  static Future<Map<String, dynamic>?> getTicketDetails(String ticketId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/support/tickets/$ticketId'),
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
        print('Error fetching ticket details: $e');
      }
      return null;
    }
  }

  // Reply to a support ticket
  static Future<Map<String, dynamic>?> replyToTicket({
    required String ticketId,
    required String message,
    List<String>? attachments,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/support/tickets/$ticketId/reply'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': message,
          if (attachments != null && attachments.isNotEmpty) 
            'attachments': attachments,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error replying to ticket: $e');
      }
      return null;
    }
  }

  // Close a support ticket
  static Future<bool> closeTicket(String ticketId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/support/tickets/$ticketId/close'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error closing ticket: $e');
      }
      return false;
    }
  }

  // Reopen a closed ticket
  static Future<bool> reopenTicket(String ticketId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$baseUrl/support/tickets/$ticketId/reopen'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error reopening ticket: $e');
      }
      return false;
    }
  }

  // Get FAQ
  static Future<List<dynamic>?> getFAQ({String? category}) async {
    try {
      String url = '$baseUrl/support/faq';
      if (category != null) {
        url += '?category=$category';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['faqs'] ?? [];
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching FAQ: $e');
      }
      return null;
    }
  }

  // Rate support response
  static Future<bool> rateSupportResponse({
    required String ticketId,
    required int rating,
    String? feedback,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/support/tickets/$ticketId/rate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'rating': rating,
          if (feedback != null) 'feedback': feedback,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error rating support response: $e');
      }
      return false;
    }
  }

  // Get support categories
  static List<Map<String, dynamic>> getSupportCategories() {
    return [
      {
        'id': 'booking',
        'label': 'Réservation',
        'icon': 'calendar_today',
      },
      {
        'id': 'payment',
        'label': 'Paiement',
        'icon': 'payment',
      },
      {
        'id': 'technical',
        'label': 'Technique',
        'icon': 'bug_report',
      },
      {
        'id': 'account',
        'label': 'Compte',
        'icon': 'person',
      },
      {
        'id': 'other',
        'label': 'Autre',
        'icon': 'help',
      },
    ];
  }
}
