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
        Uri.parse('$baseUrl/parking?limit=100'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final parkings = data['data']?['parkings'] as List?;
        
        if (parkings != null && parkings.isNotEmpty) {
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
        address: '123 Main St, Hammamet',
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
        name: 'Parking Marina',
        address: '456 Avenue Habib Bourguiba, Hammamet',
        latitude: lat - 0.005,
        longitude: lng - 0.005,
        pricePerHour: 3.0,
        totalSpots: 30,
        availableSpots: 10,
        rating: 4.5,
        imageUrl: 'https://via.placeholder.com/300x200',
        isOpen: true,
      ),
      ParkingModel(
        id: '3',
        name: 'Parking Médina',
        address: 'Rue de la Médina, Hammamet',
        latitude: lat + 0.008,
        longitude: lng - 0.012,
        pricePerHour: 2.0,
        totalSpots: 40,
        availableSpots: 35,
        rating: 4.0,
        imageUrl: 'https://via.placeholder.com/300x200',
        isOpen: true,
      ),
      ParkingModel(
        id: '4',
        name: 'Parking Yasmine',
        address: 'Yasmine Hammamet',
        latitude: lat - 0.02,
        longitude: lng + 0.015,
        pricePerHour: 3.5,
        totalSpots: 80,
        availableSpots: 40,
        rating: 4.8,
        imageUrl: 'https://via.placeholder.com/300x200',
        isOpen: true,
      ),
      ParkingModel(
        id: '5',
        name: 'Parking Sousse Nord',
        address: 'Avenue Hédi Chaker, Sousse',
        latitude: 35.8256 + 0.01,
        longitude: 10.6411 - 0.008,
        pricePerHour: 2.5,
        totalSpots: 60,
        availableSpots: 30,
        rating: 4.3,
        imageUrl: 'https://via.placeholder.com/300x200',
        isOpen: true,
      ),
      ParkingModel(
        id: '6',
        name: 'Parking Plage',
        address: 'Avenue de la Corniche, Hammamet',
        latitude: lat + 0.005,
        longitude: lng + 0.008,
        pricePerHour: 4.0,
        totalSpots: 45,
        availableSpots: 15,
        rating: 4.6,
        imageUrl: 'https://via.placeholder.com/300x200',
        isOpen: true,
      ),
      ParkingModel(
        id: '7',
        name: 'Parking Nabeul Centre',
        address: 'Avenue Farhat Hached, Nabeul',
        latitude: 36.4561 + 0.005,
        longitude: 10.7376 - 0.005,
        pricePerHour: 2.0,
        totalSpots: 35,
        availableSpots: 20,
        rating: 3.9,
        imageUrl: 'https://via.placeholder.com/300x200',
        isOpen: true,
      ),
      ParkingModel(
        id: '8',
        name: 'Parking Tunis Ville',
        address: 'Avenue Habib Bourguiba, Tunis',
        latitude: 36.8065 + 0.005,
        longitude: 10.1815 - 0.005,
        pricePerHour: 3.0,
        totalSpots: 70,
        availableSpots: 45,
        rating: 4.4,
        imageUrl: 'https://via.placeholder.com/300x200',
        isOpen: true,
      ),
      ParkingModel(
        id: '9',
        name: 'Parking Sfax Port',
        address: 'Rue de Tunis, Sfax',
        latitude: 34.7406 + 0.008,
        longitude: 10.7603 + 0.008,
        pricePerHour: 2.5,
        totalSpots: 55,
        availableSpots: 25,
        rating: 4.1,
        imageUrl: 'https://via.placeholder.com/300x200',
        isOpen: true,
      ),
      ParkingModel(
        id: '10',
        name: 'Parking Monastir Aéroport',
        address: 'Route de l\'Aéroport, Monastir',
        latitude: 35.7777 - 0.01,
        longitude: 10.8264 + 0.01,
        pricePerHour: 3.5,
        totalSpots: 100,
        availableSpots: 60,
        rating: 4.7,
        imageUrl: 'https://via.placeholder.com/300x200',
        isOpen: true,
      ),
    ];
  }
}