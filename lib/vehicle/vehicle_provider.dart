import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'vehicle_service.dart';

/// Provider for managing user's vehicles state
class VehicleProvider with ChangeNotifier {
  List<dynamic> _vehicles = [];
  bool _isLoading = false;
  String? _error;
  dynamic _selectedVehicle;

  List<dynamic> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  dynamic get selectedVehicle => _selectedVehicle;
  
  int get vehicleCount => _vehicles.length;
  bool get hasVehicles => _vehicles.isNotEmpty;

  /// Load all user vehicles from the API
  Future<void> loadVehicles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final vehicles = await VehicleService.getUserVehicles();
      if (vehicles != null) {
        _vehicles = vehicles;
        // Auto-select first vehicle if none selected
        if (_selectedVehicle == null && _vehicles.isNotEmpty) {
          _selectedVehicle = _vehicles.first;
        }
      } else {
        _vehicles = [];
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to load vehicles: $e';
      if (kDebugMode) {
        print(_error);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a specific vehicle for booking
  void selectVehicle(dynamic vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  /// Clear the selected vehicle
  void clearSelection() {
    _selectedVehicle = null;
    notifyListeners();
  }

  /// Add a new vehicle and reload the list
  Future<bool> addVehicle({
    required String licensePlate,
    required String make,
    required String model,
    required int year,
    required String color,
  }) async {
    try {
      final result = await VehicleService.createVehicle(
        licensePlate: licensePlate,
        make: make,
        model: model,
        year: year,
        color: color,
      );
      
      if (result != null) {
        await loadVehicles(); // Reload to get the new vehicle
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to add vehicle: $e';
      if (kDebugMode) {
        print(_error);
      }
      notifyListeners();
      return false;
    }
  }

  /// Delete a vehicle by ID
  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      final success = await VehicleService.deleteVehicle(vehicleId);
      if (success) {
        // Clear selection if the deleted vehicle was selected
        if (_selectedVehicle != null && 
            _selectedVehicle['vehicleInforId'].toString() == vehicleId) {
          _selectedVehicle = null;
        }
        await loadVehicles(); // Reload the list
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to delete vehicle: $e';
      if (kDebugMode) {
        print(_error);
      }
      notifyListeners();
      return false;
    }
  }

  /// Update a vehicle's information
  Future<bool> updateVehicle({
    required String vehicleId,
    required String licensePlate,
    required String make,
    required String model,
    required int year,
    required String color,
  }) async {
    try {
      final result = await VehicleService.updateVehicle(
        vehicleId: vehicleId,
        licensePlate: licensePlate,
        make: make,
        model: model,
        year: year,
        color: color,
      );
      
      if (result != null) {
        await loadVehicles(); // Reload to get updated data
        return true;
      }
      return false;
    } catch (e) {
      _error = 'Failed to update vehicle: $e';
      if (kDebugMode) {
        print(_error);
      }
      notifyListeners();
      return false;
    }
  }

  /// Get vehicle by ID
  dynamic getVehicleById(String vehicleId) {
    try {
      return _vehicles.firstWhere(
        (v) => v['vehicleInforId'].toString() == vehicleId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Filter vehicles by type (car/motorcycle)
  List<dynamic> getVehiclesByType(String type) {
    return _vehicles.where((vehicle) {
      final trafficName = (vehicle['trafficName'] ?? '').toString().toLowerCase();
      if (type.toLowerCase() == 'car') {
        return !trafficName.contains('motor') && !trafficName.contains('moto');
      } else if (type.toLowerCase() == 'motorcycle' || type.toLowerCase() == 'moto') {
        return trafficName.contains('motor') || trafficName.contains('moto');
      }
      return true;
    }).toList();
  }
}
