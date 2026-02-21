# 🏗️ Repository Pattern Implementation Guide

## 📁 Structure Created

```
lib/
└── repositories/
    ├── base_repository.dart         # Base class with common functionality
    ├── local_storage_service.dart   # Cache management service
    ├── auth_repository.dart         # Authentication operations
    ├── parking_repository.dart      # Parking data operations
    ├── booking_repository.dart      # Booking operations
    └── vehicle_repository.dart      # Vehicle management
```

## ✨ Benefits

### 1. **Separation of Concerns**
- **Before**: Providers directly called HTTP APIs
- **After**: Providers use repositories, repositories handle data access

### 2. **Automatic Caching**
- Repositories automatically cache data locally
- Reduces API calls and improves performance
- Works offline with cached data

### 3. **Better Error Handling**
- Standardized `Result<T>` type for all operations
- No more try-catch in every UI component
- User-friendly error messages

### 4. **Testability**
- Easy to mock repositories for unit tests
- Can test providers without real API calls
- Isolated testing of data layer

### 5. **Maintainability**
- Single place to change API calls
- Consistent patterns across all data operations
- Easy to add new features

## 🚀 Usage Examples

### Example 1: Using AuthRepository

```dart
import 'package:smart_parking/repositories/auth_repository.dart';

// In your provider or widget
final authRepo = AuthRepository();

// Login
final result = await authRepo.login('user@example.com', 'password123');

result.onSuccess((data) {
  print('Logged in successfully!');
  print('User: ${data['user']['name']}');
});

result.onFailure((error) {
  print('Login failed: $error');
  // Show error to user
});

// Or use isSuccess
if (result.isSuccess) {
  final userData = result.data;
  // Handle success
} else {
  final errorMessage = result.error;
  // Handle error
}

// Get user profile with caching
final profileResult = await authRepo.getUserProfile();
// First call: fetches from API and caches
// Subsequent calls: returns cached data if valid

// Force refresh
final freshProfile = await authRepo.getUserProfile(forceRefresh: true);
```

### Example 2: Using ParkingRepository

```dart
import 'package:smart_parking/repositories/parking_repository.dart';

final parkingRepo = ParkingRepository();

// Get all parkings with automatic caching
final result = await parkingRepo.getAllParkings();

result.onSuccess((parkings) {
  print('Loaded ${parkings.length} parking spots');
  // Use parkings in UI
});

// Search parkings
final searchResult = await parkingRepo.searchParkings('downtown');

// Get nearby parkings
final nearbyResult = await parkingRepo.getNearbyParkings(
  latitude: 36.8065,
  longitude: 10.1815,
  radiusKm: 5.0,
);

// Filter parkings (local operation, no API call)
final filtered = parkingRepo.filterParkings(
  parkings,
  maxPrice: 5.0,
  minRating: 4.0,
  features: ['covered', 'security'],
  availableOnly: true,
);

// Sort parkings (local operation)
final sorted = parkingRepo.sortParkings(parkings, 'price_low');
```

### Example 3: Using BookingRepository

```dart
import 'package:smart_parking/repositories/booking_repository.dart';

final bookingRepo = BookingRepository();

// Create a booking
final result = await bookingRepo.createBooking(
  parkingId: 'parking123',
  vehicleId: 'vehicle456',
  startTime: DateTime.now(),
  durationHours: 3,
);

result.onSuccess((booking) {
  print('Booking created!');
  print('QR Code: ${booking['qrCode']}');
  // Navigate to booking confirmation
});

result.onFailure((error) {
  // Show error dialog
});

// Get user bookings
final bookingsResult = await bookingRepo.getUserBookings(status: 'active');

// Cancel booking
final cancelResult = await bookingRepo.cancelBooking(
  bookingId,
  reason: 'Change of plans',
);

if (cancelResult.isSuccess) {
  // Show success message
}
```

### Example 4: Using VehicleRepository

```dart
import 'package:smart_parking/repositories/vehicle_repository.dart';

final vehicleRepo = VehicleRepository();

// Get vehicles with caching
final result = await vehicleRepo.getUserVehicles();

// Add new vehicle
final addResult = await vehicleRepo.addVehicle(
  registrationNumber: 'TUN-123-AB',
  type: 'car',
  make: 'Toyota',
  model: 'Corolla',
  color: 'Blue',
  isDefault: true,
);

addResult.onSuccess((vehicle) {
  print('Vehicle added: ${vehicle['registrationNumber']}');
});

// Update vehicle
final updateResult = await vehicleRepo.updateVehicle(
  vehicleId: vehicleId,
  color: 'Red',
);

// Delete vehicle
final deleteResult = await vehicleRepo.deleteVehicle(vehicleId);
```

## 🔄 Migrating Existing Code

### Step 1: Update Providers

**Before (AuthProvider):**
```dart
class AuthProvider with ChangeNotifier {
  Future<bool> loginWithEmail(String email, String password) async {
    try {
      final result = await AuthService.loginWithEmail(email, password);
      // Handle response...
      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
}
```

**After (with Repository):**
```dart
class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  
  Future<bool> loginWithEmail(String email, String password) async {
    final result = await _authRepo.login(email, password);
    
    if (result.isSuccess) {
      // Update state
      return true;
    } else {
      // Show error: result.error
      return false;
    }
  }
}
```

### Step 2: Update Main.dart

```dart
// Add repository initialization (optional - they auto-initialize)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        // Use the new provider with repository
        ChangeNotifierProvider(
          create: (_) => AuthProviderWithRepository(),
        ),
        // Or keep existing and update gradually
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        // ... other providers
      ],
      child: const MyApp(),
    ),
  );
}
```

## 🧪 Testing Benefits

### Unit Test Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  test('Login updates authentication state', () async {
    // Arrange
    final mockRepo = MockAuthRepository();
    final provider = AuthProviderWithRepository(authRepository: mockRepo);
    
    when(mockRepo.login(any, any)).thenAnswer(
      (_) async => Result.success({'user': {'name': 'Test User'}}),
    );
    
    // Act
    final success = await provider.loginWithEmail('test@test.com', 'pass');
    
    // Assert
    expect(success, true);
    expect(provider.isAuthenticated, true);
    verify(mockRepo.login('test@test.com', 'pass')).called(1);
  });
}
```

## 📊 Result Type Usage

The `Result<T>` type provides multiple ways to handle responses:

```dart
final result = await repository.someOperation();

// Method 1: Callbacks
result.onSuccess((data) => print('Success: $data'));
result.onFailure((error) => print('Error: $error'));

// Method 2: isSuccess check
if (result.isSuccess) {
  final data = result.data;
} else {
  final error = result.error;
}

// Method 3: Map result
final mapped = result.map((user) => user['name']);

// Method 4: Get or throw
try {
  final data = result.getOrThrow();
} catch (e) {
  // Handle error
}

// Method 5: Get or default
final data = result.getOrDefault(defaultValue);
```

## 🎯 Next Steps

1. **Gradually migrate existing providers** to use repositories
2. **Add unit tests** for repositories and providers
3. **Configure cache durations** based on data update frequency
4. **Monitor performance** improvements from caching
5. **Add more repositories** as needed (Favorites, Notifications, etc.)

## 📝 Cache Management

```dart
import 'package:smart_parking/repositories/local_storage_service.dart';

final storage = LocalStorageService();

// Check if cache is valid
final isValid = await storage.isCacheValid('cached_parkings');

// Clear specific cache
await storage.clearCache('cached_parkings');

// Clear all caches (useful on logout)
await storage.clearAllCaches();

// Custom cache with different duration
await storage.cacheData('my_key', myData);
final data = await storage.getCachedData(
  'my_key',
  cacheDuration: Duration(minutes: 10),
);
```

## 🔒 Security Note

The repository pattern doesn't change security - tokens are still stored securely using:
- `FlutterSecureStorage` on mobile
- `SharedPreferences` on web

## 💡 Pro Tips

1. **Use forceRefresh sparingly** - only for pull-to-refresh or critical updates
2. **Cache durations**: 
   - User profile: 5 minutes (default)
   - Parkings: 5 minutes
   - Vehicles: 5 minutes
   - Adjust based on your needs
3. **Error handling**: Always handle both success and failure cases
4. **Testing**: Repository pattern makes testing 10x easier
5. **Offline support**: Cached data works even without internet

## 🎉 Success!

You now have a professional, maintainable, and testable repository pattern implementation!
