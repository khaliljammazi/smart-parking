import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../vehicle/vehicle_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  List<dynamic>? _userVehicles;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userProfile => _userProfile;
  List<dynamic>? get userVehicles => _userVehicles;

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    _isAuthenticated = await AuthService.isAuthenticated();

    if (_isAuthenticated) {
      final profileData = await AuthService.getUserProfile();
      // Handle nested response structure
      _userProfile = profileData?['data']?['user'] ?? profileData?['user'] ?? profileData;

      // Load user's vehicles
      await _loadUserVehicles();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserVehicles() async {
    try {
      _userVehicles = await VehicleService.getUserVehicles();
    } catch (e) {
      _userVehicles = [];
    }
  }

  Future<void> loginWithGoogle(BuildContext context) async {
    // This will be handled by the OAuth screen
  }

  Future<void> loginWithFacebook(BuildContext context) async {
    // This will be handled by the OAuth screen
  }

  Future<void> logout() async {
    await AuthService.logout();
    _isAuthenticated = false;
    _userProfile = null;
    _userVehicles = null;
    notifyListeners();
  }

  Future<void> setAuthenticated(String token) async {
    await AuthService.storeToken(token);
    _isAuthenticated = true;
    final profileData = await AuthService.getUserProfile();
    // Handle nested response structure
    _userProfile = profileData?['data']?['user'] ?? profileData?['user'] ?? profileData;

    // Load user's vehicles
    await _loadUserVehicles();

    notifyListeners();
  }

  // Check if user needs to complete profile (missing phone)
  bool get needsPhoneNumber {
    if (_userProfile == null) return false;
    final phone = _userProfile!['phone'];
    return phone == null || phone.toString().isEmpty;
  }

  // Check if user needs to add vehicles
  bool get needsVehicles {
    return _userVehicles == null || _userVehicles!.isEmpty;
  }

  Future<void> refreshVehicles() async {
    await _loadUserVehicles();
    notifyListeners();
  }

  Future<String?> getToken() async {
    return await AuthService.getToken();
  }
}