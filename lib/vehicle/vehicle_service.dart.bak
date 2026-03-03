import 'dart:convert';
import 'package:http/http.dart' as http;
import '../authentication/auth_service.dart';

class VehicleService {
  static const String baseUrl = 'http://localhost:5000/api';

  // Get user's vehicles
  static Future<List<dynamic>?> getUserVehicles() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/vehicles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      }
      return null;
    } catch (e) {
      print('Get vehicles error: $e');
      return null;
    }
  }

  // Create new vehicle
  static Future<Map<String, dynamic>?> createVehicle({
    required String licensePlate,
    required String make,
    required String model,
    required int year,
    required String color,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/vehicles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'licensePlate': licensePlate,
          'make': make,
          'model': model,
          'year': year,
          'color': color,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('Create vehicle error: $e');
      return null;
    }
  }

  // Update vehicle
  static Future<Map<String, dynamic>?> updateVehicle({
    required String vehicleId,
    required String licensePlate,
    required String make,
    required String model,
    required int year,
    required String color,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final response = await http.put(
        Uri.parse('$baseUrl/vehicles/$vehicleId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'licensePlate': licensePlate,
          'make': make,
          'model': model,
          'year': year,
          'color': color,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('Update vehicle error: $e');
      return null;
    }
  }

  // Delete vehicle
  static Future<bool> deleteVehicle(String vehicleId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$baseUrl/vehicles/$vehicleId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Delete vehicle error: $e');
      return false;
    }
  }
}