# Multiple Vehicle Management Feature

## Overview
The Smart Parking app now supports **multiple vehicles per user**. Users can add unlimited cars and motorcycles to their account and select which specific vehicle to use for each parking reservation.

## Key Features

### 1. Multiple Vehicle Support
- Users can add multiple vehicles (cars, motorcycles)
- Each vehicle stores: license plate, name, color, type
- Vehicles are managed through the Vehicle Management page
- Easy add/edit/delete operations with swipe-to-delete gesture

### 2. Vehicle Selection During Booking
- During the booking process, users select which vehicle they're using
- Visual vehicle selector shows all registered vehicles
- Selected vehicle is highlighted with checkmark
- Vehicle information includes icon, license plate, color indicator

### 3. Vehicle Provider State Management
- **VehicleProvider** manages global vehicle state
- Automatically loads user's vehicles from API
- Syncs selection across the app
- Provides methods for CRUD operations

## New Files Added

### `lib/vehicle/vehicle_provider.dart`
State management for vehicles with Provider pattern:
```dart
class VehicleProvider with ChangeNotifier {
  List<dynamic> _vehicles = [];
  dynamic _selectedVehicle;
  
  // Methods:
  Future<void> loadVehicles()
  void selectVehicle(dynamic vehicle)
  Future<bool> addVehicle(...)
  Future<bool> deleteVehicle(String vehicleId)
  Future<bool> updateVehicle(...)
  List<dynamic> getVehiclesByType(String type)
}
```

### `lib/booking/vehicle_selector_widget.dart`
Reusable widget for vehicle selection:
- Displays all user vehicles in cards
- Shows vehicle icon based on type (car/motorcycle)
- Color indicator for vehicle color
- Selection state with visual feedback
- "Add New Vehicle" button
- Empty state when no vehicles

### `lib/booking/enhanced_booking_page.dart`
Enhanced booking confirmation page:
- Integrated vehicle selector
- Booking time and location display
- Payment method selection
- Guest booking option
- Price summary
- Validates vehicle selection before booking

## User Flow

### Adding a Vehicle
1. Navigate to **Account** → **Vehicle Management**
2. Tap the **+ (Add)** floating button
3. Fill in vehicle details:
   - License Plate
   - Vehicle Name/Model
   - Color
   - Type (Car/Motorcycle)
4. Tap **Create** to save

### Booking with Specific Vehicle
1. Select parking spot and time
2. On booking confirmation page, see **"Select Vehicle for Booking"** section
3. Tap on desired vehicle card to select it
4. Vehicle card highlights with blue border and checkmark
5. If no vehicles exist, tap **"Add Your First Vehicle"**
6. Complete booking with selected vehicle

### Managing Multiple Vehicles
- **View All**: Vehicle Management page lists all vehicles
- **Edit**: Tap on vehicle card to edit details
- **Delete**: Swipe left on vehicle card and tap delete
- **Switch**: During booking, simply tap different vehicle to switch selection

## API Integration

### Endpoints Used
```
GET  /api/vehicles - Get user's vehicles
POST /api/vehicles - Create new vehicle
PUT  /api/vehicles/:id - Update vehicle
DELETE /api/vehicles/:id - Delete vehicle
POST /api/customer-booking - Create booking with vehicleInforId
```

### Booking Payload
```json
{
  "bookingDto": {
    "parkingSlotId": 123,
    "startTime": "2026-02-05T10:00:00",
    "endTime": "2026-02-05T14:00:00",
    "vehicleInforId": 456,  // Selected vehicle ID
    "paymentMethod": "tra_sau",
    "userId": 789
  }
}
```

## Technical Implementation

### State Management
Uses Provider pattern for global state:
1. **VehicleProvider** registered in `main.dart`
2. Available throughout app via `context.read<VehicleProvider>()`
3. Widgets rebuild automatically when vehicle list changes

### Vehicle Data Structure
```dart
{
  "vehicleInforId": 123,
  "licensePlate": "ABC-123",
  "vehicleName": "Toyota Camry",
  "color": "black",
  "trafficName": "Car"
}
```

### Color Mapping
Widget automatically maps color names to Flutter colors:
- English: red, blue, black, white, silver, etc.
- Vietnamese: đỏ, xanh, đen, trắng, bạc, etc.

### Vehicle Type Icons
- **Car** → `Icons.directions_car`
- **Motorcycle** → `Icons.two_wheeler`

## UI Components

### Vehicle Card Features
- **Vehicle Icon**: Car or motorcycle based on type
- **Vehicle Name**: Bold display at top
- **License Plate**: Highlighted in bordered box
- **Color Indicator**: Circle showing actual vehicle color
- **Type Badge**: "Car" or "Motorcycle" label
- **Selection State**: Border and checkmark when selected

### Empty State
When user has no vehicles:
- Large car icon
- "No vehicles added yet" message
- "Add Your First Vehicle" button

### Loading State
- Circular progress indicator while loading vehicles
- Prevents user interaction during API calls

## Configuration in main.dart

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (context) => ThemeProvider()),
    ChangeNotifierProvider(create: (context) => AuthProvider()),
    ChangeNotifierProvider(create: (context) => FavoritesProvider()),
    ChangeNotifierProvider(create: (context) => VehicleProvider()),  // NEW
  ],
  child: const MyApp(),
)
```

## Usage Examples

### Load Vehicles
```dart
// In initState or button press
context.read<VehicleProvider>().loadVehicles();
```

### Select Vehicle
```dart
// In onTap handler
final provider = context.read<VehicleProvider>();
provider.selectVehicle(vehicle);
```

### Get Selected Vehicle
```dart
// Access in Consumer widget
Consumer<VehicleProvider>(
  builder: (context, provider, child) {
    final selectedVehicle = provider.selectedVehicle;
    final vehicleId = selectedVehicle?['vehicleInforId'];
    return Text('Selected: $vehicleId');
  },
)
```

### Add New Vehicle
```dart
final success = await context.read<VehicleProvider>().addVehicle(
  licensePlate: 'ABC-123',
  make: 'Toyota',
  model: 'Camry',
  year: 2024,
  color: 'Black',
);
```

## Benefits

### For Users
- **Convenience**: Manage family vehicles in one account
- **Flexibility**: Choose different vehicle per booking
- **Accuracy**: Parking staff know exactly which vehicle to expect
- **Quick Access**: Fast vehicle switching during booking

### For Parking Operators
- **Verification**: Know vehicle details before arrival
- **Security**: Match license plate at entry/exit
- **Records**: Track which vehicles use the parking
- **Compliance**: Better management of vehicle types (car vs motorcycle pricing)

## Testing Checklist

- [ ] Add first vehicle (empty state → populated list)
- [ ] Add multiple vehicles (3+ different vehicles)
- [ ] Edit vehicle details
- [ ] Delete vehicle (swipe gesture)
- [ ] Select vehicle during booking
- [ ] Switch vehicle selection
- [ ] Complete booking with selected vehicle
- [ ] Verify vehicle ID sent to API
- [ ] Test with no vehicles (empty state)
- [ ] Test with only cars
- [ ] Test with only motorcycles
- [ ] Test with mixed vehicle types

## Future Enhancements

1. **Default Vehicle**: Set a preferred vehicle for quick booking
2. **Vehicle Photos**: Upload vehicle images
3. **Vehicle Verification**: Link to registration documents
4. **Shared Vehicles**: Share vehicle access with family members
5. **Vehicle History**: See booking history per vehicle
6. **Smart Suggestions**: Auto-suggest vehicle based on parking type
7. **Vehicle Stats**: Track parking frequency per vehicle

## Troubleshooting

### Vehicle List Not Loading
- Check auth token is valid
- Verify API endpoint is accessible
- Check network connection

### Cannot Select Vehicle
- Ensure VehicleProvider is registered in main.dart
- Verify vehicle data structure matches expected format
- Check for null values in vehicle object

### Booking Fails with Vehicle
- Confirm `vehicleInforId` is valid integer
- Verify vehicle belongs to current user
- Check API expects this field in booking payload

## Summary

This feature transforms the Smart Parking app from single-vehicle to **multi-vehicle management**, providing:
- ✅ Unlimited vehicle registration
- ✅ Easy vehicle selection during booking
- ✅ Visual vehicle indicators and cards
- ✅ State management with Provider
- ✅ Seamless API integration
- ✅ Intuitive UI/UX design

Users can now manage their entire fleet of vehicles and choose the right one for each parking session!
