import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../repositories/vehicle_repository.dart';

/// Enhanced AuthProvider using Repository Pattern
/// 
/// Benefits:
/// - Separation of concerns (UI logic vs data access)
/// - Better testability (can mock repositories)
/// - Centralized error handling
/// - Automatic caching through repositories
class AuthProviderWithRepository with ChangeNotifier {
  final AuthRepository _authRepository;
  final VehicleRepository _vehicleRepository;
  
  bool _isAuthenticated = false;
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  List<dynamic>? _userVehicles;
  String? _lastError;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get userProfile => _userProfile;
  List<dynamic>? get userVehicles => _userVehicles;
  String? get lastError => _lastError;

  // Check if user needs to complete profile
  bool get needsPhoneNumber {
    if (_userProfile == null) return false;
    final phone = _userProfile!['phone']?.toString() ?? '';
    return phone.isEmpty || phone == 'null';
  }

  bool get needsVehicles {
    return _userVehicles == null || _userVehicles!.isEmpty;
  }

  AuthProviderWithRepository({
    AuthRepository? authRepository,
    VehicleRepository? vehicleRepository,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _vehicleRepository = vehicleRepository ?? VehicleRepository() {
    _checkAuthStatus();
  }

  /// Check authentication status on app start
  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    _isAuthenticated = await _authRepository.isAuthenticated();

    if (_isAuthenticated) {
      // Load user profile using repository (with caching)
      final profileResult = await _authRepository.getUserProfile();
      
      profileResult.onSuccess((profile) {
        _userProfile = profile;
      });

      profileResult.onFailure((error) {
        _lastError = error;
        _isAuthenticated = false;
      });

      // Load user's vehicles
      if (_isAuthenticated) {
        await _loadUserVehicles();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Load user vehicles with error handling
  Future<void> _loadUserVehicles() async {
    final result = await _vehicleRepository.getUserVehicles();
    
    result.onSuccess((vehicles) {
      _userVehicles = vehicles;
    });

    result.onFailure((error) {
      _userVehicles = [];
      // Don't set lastError for vehicles as it's not critical
    });
  }

  /// Login with email and password
  /// Returns true on success, false on failure
  Future<bool> loginWithEmail(String email, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final result = await _authRepository.login(email, password);
    
    if (result.isSuccess) {
      _isAuthenticated = true;
      
      // Get updated profile
      final profileResult = await _authRepository.getUserProfile(forceRefresh: true);
      profileResult.onSuccess((profile) {
        _userProfile = profile;
      });

      // Load vehicles
      await _loadUserVehicles();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _lastError = result.error;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register new user
  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    final result = await _authRepository.register(userData);
    
    if (result.isSuccess) {
      _isAuthenticated = true;
      
      // Get profile
      final profileResult = await _authRepository.getUserProfile(forceRefresh: true);
      profileResult.onSuccess((profile) {
        _userProfile = profile;
      });
      
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _lastError = result.error;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    _lastError = null;
    
    final result = await _authRepository.updateUserProfile(updates);
    
    if (result.isSuccess) {
      _userProfile = result.data;
      notifyListeners();
      return true;
    } else {
      _lastError = result.error;
      notifyListeners();
      return false;
    }
  }

  /// Logout user
  Future<void> logout() async {
    final result = await _authRepository.logout();
    
    result.onSuccess((_) {
      _isAuthenticated = false;
      _userProfile = null;
      _userVehicles = null;
      _lastError = null;
      notifyListeners();
    });
  }

  /// Manually set authenticated (for OAuth callbacks)
  Future<void> setAuthenticated(String token) async {
    _isAuthenticated = true;
    
    // Load profile
    final profileResult = await _authRepository.getUserProfile(forceRefresh: true);
    profileResult.onSuccess((profile) {
      _userProfile = profile;
    });

    // Load vehicles
    await _loadUserVehicles();
    
    notifyListeners();
  }

  /// Refresh user data (pull to refresh)
  Future<void> refreshUserData() async {
    if (!_isAuthenticated) return;

    final profileResult = await _authRepository.getUserProfile(forceRefresh: true);
    profileResult.onSuccess((profile) {
      _userProfile = profile;
    });

    final vehiclesResult = await _vehicleRepository.getUserVehicles(forceRefresh: true);
    vehiclesResult.onSuccess((vehicles) {
      _userVehicles = vehicles;
    });

    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _lastError = null;
    
    final result = await _authRepository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    
    if (!result.isSuccess) {
      _lastError = result.error;
      notifyListeners();
    }
    
    return result.isSuccess;
  }
}
