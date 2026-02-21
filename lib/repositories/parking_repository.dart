import 'dart:convert';
import 'package:http/http.dart' as http;
import '../authentication/auth_service.dart';
import '../model/parking_model.dart';
import 'base_repository.dart';
import 'local_storage_service.dart';

/// Repository for managing parking spot data
/// 
/// Provides:
/// - Cached parking list with automatic refresh
/// - Search and filter operations
/// - Nearby parking spots
/// - Parking details
class ParkingRepository extends BaseRepository {
  final LocalStorageService _localStorage;

  ParkingRepository({LocalStorageService? localStorage})
      : _localStorage = localStorage ?? LocalStorageService();

  /// Get all parking spots with caching
  /// 
  /// [forceRefresh] - bypass cache and fetch fresh data
  /// [cacheDuration] - how long to keep cached data valid
  Future<Result<List<ParkingModel>>> getAllParkings({
    bool forceRefresh = false,
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    return executeOperation(() async {
      // Try cache first
      if (!forceRefresh) {
        final cached = await _localStorage.getCachedParkings();
        if (cached != null) {
          return cached
              .map((json) => ParkingModel.fromJson(json))
              .toList();
        }
      }

      final token = await AuthService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/parkings'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parkingsJson = data['data']?['parkings'] ?? 
                            data['parkings'] ?? 
                            data['data'] ?? 
                            [];
        
        // Cache the data
        await _localStorage.cacheParkings(parkingsJson);
        
        return (parkingsJson as List)
            .map((json) => ParkingModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load parkings');
      }
    }, errorMessage: 'Unable to load parking spots. Please try again.');
  }

  /// Get parking by ID
  Future<Result<ParkingModel>> getParkingById(String id) async {
    return executeOperation(() async {
      final token = await AuthService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/parkings/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parkingJson = data['data']?['parking'] ?? data['parking'] ?? data;
        return ParkingModel.fromJson(parkingJson);
      } else {
        throw Exception('Parking not found');
      }
    }, errorMessage: 'Failed to load parking details');
  }

  /// Search parkings by query
  Future<Result<List<ParkingModel>>> searchParkings(String query) async {
    return executeOperation(() async {
      final token = await AuthService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/parkings/search?q=$query'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parkingsJson = data['data']?['parkings'] ?? 
                            data['parkings'] ?? 
                            [];
        
        return (parkingsJson as List)
            .map((json) => ParkingModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Search failed');
      }
    }, errorMessage: 'Search failed. Please try again.');
  }

  /// Get nearby parkings based on location
  Future<Result<List<ParkingModel>>> getNearbyParkings({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    return executeOperation(() async {
      final token = await AuthService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse(
          '${AuthService.baseUrl}/parkings/nearby?'
          'lat=$latitude&lng=$longitude&radius=$radiusKm'
        ),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parkingsJson = data['data']?['parkings'] ?? 
                            data['parkings'] ?? 
                            [];
        
        return (parkingsJson as List)
            .map((json) => ParkingModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to find nearby parkings');
      }
    }, errorMessage: 'Failed to find nearby parkings');
  }

  /// Filter parkings by criteria
  List<ParkingModel> filterParkings(
    List<ParkingModel> parkings, {
    double? maxPrice,
    double? minRating,
    List<String>? features,
    bool? availableOnly,
  }) {
    var filtered = parkings;

    if (maxPrice != null) {
      filtered = filtered.where((p) => 
        (p.carPrice ?? double.infinity) <= maxPrice
      ).toList();
    }

    if (minRating != null) {
      filtered = filtered.where((p) => 
        (p.rating ?? 0) >= minRating
      ).toList();
    }

    if (features != null && features.isNotEmpty) {
      filtered = filtered.where((p) {
        return features.every((feature) => 
          p.features?.contains(feature) ?? false
        );
      }).toList();
    }

    if (availableOnly == true) {
      filtered = filtered.where((p) => 
        (p.availableSpots ?? 0) > 0
      ).toList();
    }

    return filtered;
  }

  /// Sort parkings by criteria
  List<ParkingModel> sortParkings(
    List<ParkingModel> parkings,
    String sortBy,
  ) {
    final sorted = List<ParkingModel>.from(parkings);

    switch (sortBy) {
      case 'price_low':
        sorted.sort((a, b) => 
          (a.carPrice ?? double.infinity)
            .compareTo(b.carPrice ?? double.infinity)
        );
        break;
      case 'price_high':
        sorted.sort((a, b) => 
          (b.carPrice ?? 0).compareTo(a.carPrice ?? 0)
        );
        break;
      case 'rating':
        sorted.sort((a, b) => 
          (b.rating ?? 0).compareTo(a.rating ?? 0)
        );
        break;
      case 'distance':
        sorted.sort((a, b) => 
          (a.distance ?? double.infinity)
            .compareTo(b.distance ?? double.infinity)
        );
        break;
      case 'availability':
        sorted.sort((a, b) => 
          (b.availableSpots ?? 0).compareTo(a.availableSpots ?? 0)
        );
        break;
      case 'name':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return sorted;
  }

  /// Clear cached parking data
  Future<void> clearCache() async {
    await _localStorage.clearCache('cached_parkings');
  }

  /// Refresh cache
  Future<Result<List<ParkingModel>>> refreshCache() async {
    return getAllParkings(forceRefresh: true);
  }
}
