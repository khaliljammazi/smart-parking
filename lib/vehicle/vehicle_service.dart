import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../authentication/auth_service.dart';

class VehicleService {
  static const String baseUrl = 'http://localhost:5000/api';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Authorization': 'Bearer ${token ?? ''}',
      'Content-Type': 'application/json',
    };
  }

  // ── CRUD ──────────────────────────────────────

  /// Get user's vehicles (sorted by default first)
  static Future<List<dynamic>?> getUserVehicles() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['data'] ?? [];
      }
      return null;
    } catch (e) {
      print('Get vehicles error: $e');
      return null;
    }
  }

  /// Create new vehicle (includes type, fuelType, insurance, isDefault)
  static Future<Map<String, dynamic>?> createVehicle({
    required String licensePlate,
    required String make,
    required String model,
    required int year,
    required String color,
    String type = 'car',
    String fuelType = 'petrol',
    String? insuranceNumber,
    String? insuranceExpiry,
    bool isDefault = false,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = {
        'licensePlate': licensePlate,
        'make': make,
        'model': model,
        'year': year,
        'color': color,
        'type': type,
        'fuelType': fuelType,
        'isDefault': isDefault,
        if (insuranceNumber != null && insuranceNumber.isNotEmpty)
          'insuranceNumber': insuranceNumber,
        if (insuranceExpiry != null && insuranceExpiry.isNotEmpty)
          'insuranceExpiry': insuranceExpiry,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/vehicles'),
        headers: headers,
        body: json.encode(body),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 201) return data;
      // Return the body so caller can read error code / message
      return data;
    } catch (e) {
      print('Create vehicle error: $e');
      return null;
    }
  }

  /// Update vehicle
  static Future<Map<String, dynamic>?> updateVehicle({
    required String vehicleId,
    required String licensePlate,
    required String make,
    required String model,
    required int year,
    required String color,
    String? type,
    String? fuelType,
    String? insuranceNumber,
    String? insuranceExpiry,
  }) async {
    try {
      final headers = await _authHeaders();
      final body = {
        'licensePlate': licensePlate,
        'make': make,
        'model': model,
        'year': year,
        'color': color,
        if (type != null) 'type': type,
        if (fuelType != null) 'fuelType': fuelType,
        'insuranceNumber': insuranceNumber ?? '',
        'insuranceExpiry': insuranceExpiry ?? '',
      };

      final response = await http.put(
        Uri.parse('$baseUrl/vehicles/$vehicleId'),
        headers: headers,
        body: json.encode(body),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) return data;
      return data;
    } catch (e) {
      print('Update vehicle error: $e');
      return null;
    }
  }

  /// Delete vehicle
  static Future<bool> deleteVehicle(String vehicleId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/vehicles/$vehicleId'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Delete vehicle error: $e');
      return false;
    }
  }

  // ── Default vehicle ───────────────────────────

  /// Toggle default vehicle flag
  static Future<Map<String, dynamic>?> toggleDefault(String vehicleId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/vehicles/$vehicleId/default'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Toggle default error: $e');
      return null;
    }
  }

  // ── Photos ────────────────────────────────────

  /// Upload photos for a vehicle (max 3)
  static Future<Map<String, dynamic>?> uploadPhotos(
    String vehicleId,
    List<File> files,
  ) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final uri = Uri.parse('$baseUrl/vehicles/$vehicleId/photos');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token';

      for (final file in files) {
        final ext = file.path.split('.').last.toLowerCase();
        final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'photos',
            file.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final streamed = await request.send();
      final responseBody = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) {
        return json.decode(responseBody);
      }
      return null;
    } catch (e) {
      print('Upload photos error: $e');
      return null;
    }
  }

  /// Delete a photo by index
  static Future<bool> deletePhoto(String vehicleId, int index) async {
    try {
      final headers = await _authHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/vehicles/$vehicleId/photos/$index'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Delete photo error: $e');
      return false;
    }
  }

  // ── History & Stats ───────────────────────────

  /// Get booking history for a specific vehicle
  static Future<Map<String, dynamic>?> getVehicleHistory(
    String vehicleId,
  ) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/$vehicleId/history'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      return null;
    } catch (e) {
      print('Get vehicle history error: $e');
      return null;
    }
  }

  /// Get vehicle statistics summary for current user
  static Future<Map<String, dynamic>?> getVehicleStats() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/stats/summary'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      return null;
    } catch (e) {
      print('Get vehicle stats error: $e');
      return null;
    }
  }

  /// Get compatible parking slots for a vehicle
  static Future<Map<String, dynamic>?> getSlotMatch(String vehicleId) async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/slot-match/$vehicleId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      return null;
    } catch (e) {
      print('Get slot match error: $e');
      return null;
    }
  }

  /// Vehicle type → recommended slot types mapping (client-side)
  static List<String> getRecommendedSlots(String? vehicleType) {
    switch (vehicleType) {
      case 'motorcycle':
        return ['motorcycle', 'compact', 'standard', 'large'];
      case 'car':
        return ['compact', 'standard', 'large'];
      case 'electric':
        return ['ev_charging', 'compact', 'standard', 'large'];
      case 'hybrid':
        return ['compact', 'standard', 'large', 'ev_charging'];
      case 'van':
        return ['standard', 'large'];
      case 'truck':
        return ['large'];
      default:
        return ['standard', 'large'];
    }
  }

  /// Human-readable slot type labels in French
  static String slotTypeLabel(String type) {
    switch (type) {
      case 'motorcycle':
        return 'Moto';
      case 'compact':
        return 'Compact';
      case 'standard':
        return 'Standard';
      case 'large':
        return 'Grand';
      case 'ev_charging':
        return 'Borne électrique';
      default:
        return type;
    }
  }
}
