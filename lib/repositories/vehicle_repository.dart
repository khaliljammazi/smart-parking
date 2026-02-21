import 'dart:convert';
import 'package:http/http.dart' as http;
import '../authentication/auth_service.dart';
import 'base_repository.dart';
import 'local_storage_service.dart';

/// Repository for managing user vehicles
/// 
/// Provides:
/// - CRUD operations for vehicles
/// - Vehicle caching
/// - Default vehicle management
class VehicleRepository extends BaseRepository {
  final LocalStorageService _localStorage;

  VehicleRepository({LocalStorageService? localStorage})
      : _localStorage = localStorage ?? LocalStorageService();

  /// Get all vehicles for current user with caching
  Future<Result<List<Map<String, dynamic>>>> getUserVehicles({
    bool forceRefresh = false,
  }) async {
    return executeOperation(() async {
      // Try cache first
      if (!forceRefresh) {
        final cached = await _localStorage.getCachedVehicles();
        if (cached != null) {
          return cached.map((v) => Map<String, dynamic>.from(v)).toList();
        }
      }

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/vehicles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final vehicles = data['data']?['vehicles'] ?? 
                        data['vehicles'] ?? 
                        [];
        
        final vehicleList = List<Map<String, dynamic>>.from(vehicles);
        
        // Cache the vehicles
        await _localStorage.cacheVehicles(vehicleList);
        
        return vehicleList;
      } else {
        throw Exception('Failed to load vehicles');
      }
    }, errorMessage: 'Failed to load your vehicles');
  }

  /// Add a new vehicle
  Future<Result<Map<String, dynamic>>> addVehicle({
    required String registrationNumber,
    required String type, // 'car', 'motorcycle', 'van', etc.
    String? make,
    String? model,
    String? color,
    bool isDefault = false,
  }) async {
    return executeOperation(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final body = {
        'registrationNumber': registrationNumber,
        'type': type,
        if (make != null) 'make': make,
        if (model != null) 'model': model,
        if (color != null) 'color': color,
        'isDefault': isDefault,
      };

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/vehicles'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final vehicle = data['data']?['vehicle'] ?? data['vehicle'] ?? data;
        
        // Clear cache to force refresh
        await _localStorage.clearCache('cached_vehicles');
        
        return vehicle;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to add vehicle');
      }
    }, errorMessage: 'Failed to add vehicle');
  }

  /// Update vehicle information
  Future<Result<Map<String, dynamic>>> updateVehicle({
    required String vehicleId,
    String? registrationNumber,
    String? type,
    String? make,
    String? model,
    String? color,
    bool? isDefault,
  }) async {
    return executeOperation(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final body = <String, dynamic>{
        if (registrationNumber != null) 'registrationNumber': registrationNumber,
        if (type != null) 'type': type,
        if (make != null) 'make': make,
        if (model != null) 'model': model,
        if (color != null) 'color': color,
        if (isDefault != null) 'isDefault': isDefault,
      };

      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/vehicles/$vehicleId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final vehicle = data['data']?['vehicle'] ?? data['vehicle'] ?? data;
        
        // Clear cache to force refresh
        await _localStorage.clearCache('cached_vehicles');
        
        return vehicle;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update vehicle');
      }
    }, errorMessage: 'Failed to update vehicle');
  }

  /// Delete a vehicle
  Future<Result<bool>> deleteVehicle(String vehicleId) async {
    return executeBoolOperation(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.delete(
        Uri.parse('${AuthService.baseUrl}/vehicles/$vehicleId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Clear cache to force refresh
        await _localStorage.clearCache('cached_vehicles');
        return true;
      }
      
      return false;
    }, errorMessage: 'Failed to delete vehicle');
  }

  /// Set a vehicle as default
  Future<Result<bool>> setDefaultVehicle(String vehicleId) async {
    return executeBoolOperation(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.put(
        Uri.parse('${AuthService.baseUrl}/vehicles/$vehicleId/default'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Clear cache to force refresh
        await _localStorage.clearCache('cached_vehicles');
        return true;
      }
      
      return false;
    }, errorMessage: 'Failed to set default vehicle');
  }

  /// Get vehicle by ID
  Future<Result<Map<String, dynamic>>> getVehicleById(String vehicleId) async {
    return executeOperation(() async {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/vehicles/$vehicleId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']?['vehicle'] ?? data['vehicle'] ?? data;
      } else {
        throw Exception('Vehicle not found');
      }
    }, errorMessage: 'Failed to load vehicle details');
  }

  /// Clear cached vehicles
  Future<void> clearCache() async {
    await _localStorage.clearCache('cached_vehicles');
  }

  /// Refresh vehicle cache
  Future<Result<List<Map<String, dynamic>>>> refreshCache() async {
    return getUserVehicles(forceRefresh: true);
  }
}
