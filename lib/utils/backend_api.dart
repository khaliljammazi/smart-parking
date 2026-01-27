import '../model/parking_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class BackendApi {
  static String get baseUrl {
    if (kIsWeb) {
      return '${Uri.base.scheme}://${Uri.base.host}:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  // Get parking spots from backend
  static Future<List<ParkingModel>> getParkingSpots(double lat, double lng, double radius) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/parking?latitude=$lat&longitude=$lng&radius=$radius'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parkings = data['data']?['parkings'] as List?;
        
        if (parkings != null) {
          return parkings.map((p) => _parseParkingModel(p)).toList();
        }
      }
      // Fallback to mock data if API fails
      return _getMockParkingData(lat, lng);
    } catch (e) {
      print('Error fetching parking spots: $e');
      return _getMockParkingData(lat, lng);
    }
  }

  static Future<List<ParkingModel>> getAllParkingSpots() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/parking?limit=50'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parkings = data['data']?['parkings'] as List?;
        
        if (parkings != null) {
          return parkings.map((p) => _parseParkingModel(p)).toList();
        }
      }
      // Fallback to mock data if API fails
      return _getMockParkingData(36.8065, 10.1815);
    } catch (e) {
      print('Error fetching all parking spots: $e');
      return _getMockParkingData(36.8065, 10.1815);
    }
  }

  static ParkingModel _parseParkingModel(Map<String, dynamic> json) {
    // Build address string from address object
    String address = '';
    if (json['address'] is Map) {
      final addr = json['address'];
      address = addr['street']?.toString() ?? '';
      if (addr['city'] != null && addr['city'] != address) {
        address += ', ${addr['city']}';
      }
      if (addr['country'] != null && addr['country'] != addr['city']) {
        address += ', ${addr['country']}';
      }
    } else if (json['address'] is String) {
      address = json['address'];
    }

    // Extract imageUrl
    String imageUrl = '';
    if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      final firstImage = json['images'][0];
      imageUrl = firstImage is String ? firstImage : '';
    } else if (json['imageUrl'] is String) {
      imageUrl = json['imageUrl'];
    }

    return ParkingModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: address,
      latitude: (json['coordinates']?['latitude'] ?? json['latitude'] ?? 0).toDouble(),
      longitude: (json['coordinates']?['longitude'] ?? json['longitude'] ?? 0).toDouble(),
      pricePerHour: (json['pricing']?['hourly'] ?? json['pricePerHour'] ?? 0).toDouble(),
      totalSpots: (json['totalSpots'] ?? json['capacity']?['total'] ?? 0).toInt(),
      availableSpots: (json['availableSpots'] ?? json['capacity']?['available'] ?? 0).toInt(),
      rating: (json['rating']?['average'] ?? json['rating'] ?? 0).toDouble(),
      imageUrl: imageUrl,
      isOpen: json['isActive'] ?? json['isOpen'] ?? true,
    );
  }

  static Future<bool> createParking(Map<String, dynamic> parkingData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/parking'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(parkingData),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error creating parking: $e');
      return false;
    }
  }

  static Future<bool> updateParking(String parkingId, Map<String, dynamic> parkingData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/parking/$parkingId'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(parkingData),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating parking: $e');
      return false;
    }
  }

  static Future<bool> deleteParking(String parkingId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/parking/$parkingId'),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting parking: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllBookings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings?limit=1000'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bookings = data['data']?['bookings'] as List? ?? [];
        return bookings.map((b) => b as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching all bookings: $e');
      return [];
    }
  }

  static Future<bool> updateParkingAvailability(String parkingId, int availableSpots) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/parking/$parkingId/availability'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'availableSpots': availableSpots}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error updating parking availability: $e');
      return false;
    }
  }

  static List<ParkingModel> _getMockParkingData(double lat, double lng) {
    return [
      ParkingModel(
        id: '1',
        name: 'Parking Central',
        address: '123 Main St, Tunis',
        latitude: lat + 0.01,
        longitude: lng + 0.01,
        pricePerHour: 2.5,
        totalSpots: 50,
        availableSpots: 25,
        rating: 4.2,
        imageUrl: 'https://via.placeholder.com/300x200',
        isOpen: true,
      ),
      ParkingModel(
        id: '2',
        name: 'Downtown Parking',
        address: '456 Center Ave, Tunis',
        latitude: lat - 0.005,
        longitude: lng - 0.005,
        pricePerHour: 3.0,
        totalSpots: 30,
        availableSpots: 10,
        rating: 4.5,
        imageUrl: 'https://via.placeholder.com/300x200',
        isOpen: true,
      ),
    ];
  }
}