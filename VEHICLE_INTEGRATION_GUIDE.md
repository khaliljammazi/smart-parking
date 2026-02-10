## Quick Integration Guide: Multiple Vehicle Selection

### Option 1: Replace Existing Booking Flow (Recommended)

If you want to use the new enhanced booking page:

**In `lib/booking/booking_slot_page.dart`**, replace the navigation:

```dart
// OLD CODE:
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const BookingDetail()),
);

// NEW CODE:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EnhancedBookingConfirmationPage(
      parkingName: ParkingDetailPage.parkingName,
      parkingAddress: 'Address from API',  // Add this
      floorName: selectedFloor.floorName!,
      slotName: slotSelected.parkingSlotDto!.name!,
      startTime: widget.startTime,
      endTime: widget.endTime,
      duration: (widget.endTime.difference(widget.startTime).inHours),
      estimatedPrice: 0.0,  // Get from API
      parkingSlotId: slotSelected.parkingSlotDto!.parkingSlotId!,
      parkingId: ParkingDetailPage.parkingIdGlobal,
    ),
  ),
);
```

### Option 2: Integrate into Existing booking_detail.dart

If you want to keep the existing booking page but add the vehicle selector:

**Add import:**
```dart
import 'package:provider/provider.dart';
import '../vehicle/vehicle_provider.dart';
import 'vehicle_selector_widget.dart';
```

**In initState, load vehicles:**
```dart
@override
void initState() {
  _getCustomerName(context);
  // ADD THIS:
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<VehicleProvider>().loadVehicles();
  });
  super.initState();
}
```

**Replace the existing vehicle selection section** (around line 530):

```dart
// OLD: The _chooseVehicle and DottedBorder section

// NEW: Use the VehicleSelector widget
Consumer<VehicleProvider>(
  builder: (context, vehicleProvider, child) {
    if (vehicleProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return VehicleSelectorWidget(
      vehicles: vehicleProvider.vehicles,
      selectedVehicle: vehicleProvider.selectedVehicle,
      onVehicleSelected: (vehicle) {
        vehicleProvider.selectVehicle(vehicle);
        setState(() {
          result = Vehicle(
            vehicleInforId: vehicle['vehicleInforId'],
            licensePlate: vehicle['licensePlate'],
            vehicleName: vehicle['vehicleName'],
            color: vehicle['color'],
            trafficName: vehicle['trafficName'],
          );
        });
      },
      onAddVehicle: () async {
        final newVehicle = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VehiclePage(isSelected: true),
          ),
        );
        if (newVehicle != null) {
          vehicleProvider.loadVehicles();
        }
      },
    );
  },
),
```

### Option 3: Add Quick Vehicle Switcher

For a minimal change, add a dropdown to switch between vehicles:

```dart
Consumer<VehicleProvider>(
  builder: (context, vehicleProvider, child) {
    if (vehicleProvider.vehicles.isEmpty) {
      return ElevatedButton(
        onPressed: () => Navigator.push(...),
        child: const Text('Add Vehicle'),
      );
    }

    return DropdownButton<dynamic>(
      value: vehicleProvider.selectedVehicle,
      hint: const Text('Select Vehicle'),
      items: vehicleProvider.vehicles.map((vehicle) {
        return DropdownMenuItem(
          value: vehicle,
          child: Text(
            '${vehicle['vehicleName']} (${vehicle['licensePlate']})',
          ),
        );
      }).toList(),
      onChanged: (vehicle) {
        vehicleProvider.selectVehicle(vehicle);
      },
    );
  },
)
```

## Testing the Integration

1. **Run the app:**
   ```bash
   flutter run -d chrome --web-port=51919
   ```

2. **Add vehicles:**
   - Go to Account → Vehicle Management
   - Add 2-3 test vehicles

3. **Test booking:**
   - Select a parking spot
   - Go to booking confirmation
   - See your vehicles listed
   - Select one vehicle
   - Complete the booking

4. **Verify API call:**
   - Check the console for the booking request
   - Confirm `vehicleInforId` is included

## Common Issues

### "VehicleProvider not found"
**Solution:** Make sure you added it to main.dart providers list:
```dart
ChangeNotifierProvider(create: (context) => VehicleProvider()),
```

### Vehicles not showing
**Solution:** Check the API response structure matches:
```dart
{
  "vehicleInforId": int,
  "licensePlate": string,
  "vehicleName": string,
  "color": string,
  "trafficName": string
}
```

### Selected vehicle not persisting
**Solution:** Use Provider, not setState:
```dart
context.read<VehicleProvider>().selectVehicle(vehicle);
```

## API Backend Requirements

Your backend should support:

```javascript
// Get user vehicles
GET /api/vehicles
Headers: { Authorization: 'Bearer <token>' }
Response: {
  data: [
    {
      vehicleInforId: 1,
      licensePlate: "ABC-123",
      vehicleName: "Toyota Camry",
      color: "black",
      trafficName: "Car"
    }
  ]
}

// Create booking with vehicle
POST /api/customer-booking
Body: {
  bookingDto: {
    vehicleInforId: 1,  // REQUIRED
    parkingSlotId: 123,
    startTime: "...",
    endTime: "...",
    // ... other fields
  }
}
```

## Summary

You now have **three integration options**:

1. **Full Replacement** - Use new EnhancedBookingConfirmationPage
2. **Widget Integration** - Add VehicleSelectorWidget to existing page
3. **Minimal Change** - Add simple dropdown selector

Choose based on your needs. All options provide multiple vehicle support! 🚗🏍️
