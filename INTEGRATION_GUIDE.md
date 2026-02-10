# 🔌 Integration Guide for New Features

This guide will help you integrate the new features into your existing app screens.

## 📍 1. Location Services Integration

### In any page that needs location:

```dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Get current location
Position position = await Geolocator.getCurrentPosition();
print('Lat: ${position.latitude}, Lng: ${position.longitude}');

// Get address from coordinates
List<Placemark> placemarks = await placemarkFromCoordinates(
  position.latitude, 
  position.longitude
);
String address = placemarks.first.locality ?? 'Unknown';
```

---

## 🔔 2. Push Notifications

### Already initialized in main.dart! Just use:

```dart
import '../utils/notification_service.dart';

// Show local notification
await NotificationService.showLocalNotification(
  title: 'Booking Confirmed',
  body: 'Your parking is ready!',
  data: {'type': 'booking', 'id': '123'},
);

// Schedule booking reminder
await NotificationService.scheduleBookingReminder(
  bookingId: '123',
  parkingName: 'Central Parking',
  bookingTime: DateTime.now().add(Duration(hours: 2)),
);
```

---

## 📱 3. Booking Cancellation/Extension

### Add to booking details page:

```dart
import '../booking/booking_actions_dialog.dart';

// Show actions dialog
IconButton(
  icon: Icon(Icons.more_vert),
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) => BookingActionsDialog(
        bookingId: booking['_id'],
        status: booking['status'],
        onUpdate: () {
          // Refresh booking data
          _loadBooking();
        },
      ),
    );
  },
)
```

---

## 💳 4. Payment QR Code

### Add to completed bookings or checkout:

```dart
import '../booking/payment_qr_dialog.dart';

// Show payment QR
ElevatedButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) => PaymentQRDialog(
        bookingId: booking['_id'],
        amount: 25.50,
        parkingName: 'Central Parking',
      ),
    );
  },
  child: Text('Generate Payment QR'),
)
```

---

## ⭐ 5. Rating System

### Add after booking completion:

```dart
import '../booking/rating_dialog.dart';

// Show rating dialog
void _showRatingDialog() {
  showDialog(
    context: context,
    builder: (context) => RatingDialog(
      parkingId: parking.id,
      parkingName: parking.name,
    ),
  ).then((submitted) {
    if (submitted == true) {
      // Rating was submitted successfully
      _loadUpdatedRatings();
    }
  });
}
```

### Display ratings in parking details:

```dart
import '../utils/rating_service.dart';

// Load ratings
Future<void> _loadRatings() async {
  final result = await RatingService.getParkingRatings(
    parkingId: parking.id,
    page: 1,
    limit: 10,
  );
  
  if (result != null) {
    setState(() {
      _ratings = result['data']['ratings'];
      _avgRating = result['data']['averageRating'];
    });
  }
}
```

---

## 🎁 6. Promo Code Widget

### Add to booking/checkout page:

```dart
import '../booking/promo_code_widget.dart';

// Add in your build method
PromoCodeWidget(
  parkingId: parking.id,
  bookingAmount: totalAmount,
  onPromoApplied: (promoData) {
    // Calculate discount
    setState(() {
      if (promoData.isNotEmpty) {
        final discountType = promoData['discountType'];
        final discountValue = promoData['discountValue'];
        
        if (discountType == 'percentage') {
          _discount = totalAmount * (discountValue / 100);
        } else {
          _discount = discountValue.toDouble();
        }
        
        _finalAmount = totalAmount - _discount;
      } else {
        _discount = 0;
        _finalAmount = totalAmount;
      }
    });
  },
)
```

---

## 💬 7. Support Chat

### Add to settings or help menu:

```dart
import '../account/support_chat_page.dart';

// Navigate to support
ListTile(
  leading: Icon(Icons.support_agent),
  title: Text('Support'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupportChatPage(),
      ),
    );
  },
)
```

---

## 🎯 8. Error Handling

### Use throughout the app:

```dart
import '../utils/error_handler.dart';

// Show errors
try {
  final result = await someApiCall();
  if (result == null) {
    ErrorHandler.showErrorSnackBar(
      context,
      message: 'Failed to load data',
      onRetry: () => someApiCall(),
    );
  }
} catch (e) {
  ErrorHandler.logError('Screen Name', e);
  ErrorHandler.showErrorDialog(
    context,
    title: 'Error',
    message: ErrorHandler.getUserFriendlyMessage(e),
    onRetry: () => someApiCall(),
  );
}

// Show success
ErrorHandler.showSuccess(context, 'Booking confirmed!');

// Form validation
String? emailError = ErrorHandler.validateEmail(emailController.text);
String? passwordError = ErrorHandler.validatePassword(passwordController.text);
```

---

## 🔗 Complete Example: Booking Details Page

```dart
import 'package:flutter/material.dart';
import '../booking/booking_actions_dialog.dart';
import '../booking/payment_qr_dialog.dart';
import '../booking/rating_dialog.dart';
import '../utils/error_handler.dart';
import '../utils/constanst.dart';

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;
  
  const BookingDetailsPage({super.key, required this.bookingId});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage> {
  Map<String, dynamic>? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await BookingService.getBookingById(widget.bookingId);
      
      if (mounted) {
        if (result != null) {
          setState(() {
            _booking = result;
            _isLoading = false;
          });
        } else {
          ErrorHandler.showErrorDialog(
            context,
            title: 'Error',
            message: 'Failed to load booking',
            onRetry: _loadBooking,
          );
        }
      }
    } catch (e) {
      ErrorHandler.logError('BookingDetails', e);
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          message: ErrorHandler.getUserFriendlyMessage(e),
          onRetry: _loadBooking,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Booking Details'),
        backgroundColor: AppColor.navy,
        foregroundColor: Colors.white,
        actions: [
          if (_booking != null && _booking!['status'] != 'cancelled')
            IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => BookingActionsDialog(
                    bookingId: widget.bookingId,
                    status: _booking!['status'],
                    onUpdate: _loadBooking,
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _booking == null
              ? Center(child: Text('Booking not found'))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Booking details...
                      
                      SizedBox(height: 16),
                      
                      // Payment QR Button
                      if (_booking!['status'] == 'active')
                        ElevatedButton.icon(
                          icon: Icon(Icons.qr_code),
                          label: Text('Generate Payment QR'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => PaymentQRDialog(
                                bookingId: widget.bookingId,
                                amount: _booking!['amount'],
                                parkingName: _booking!['parking']['name'],
                              ),
                            );
                          },
                        ),
                      
                      // Rate Parking Button
                      if (_booking!['status'] == 'completed' && 
                          _booking!['rated'] != true)
                        ElevatedButton.icon(
                          icon: Icon(Icons.star),
                          label: Text('Rate This Parking'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => RatingDialog(
                                parkingId: _booking!['parking']['_id'],
                                parkingName: _booking!['parking']['name'],
                              ),
                            ).then((submitted) {
                              if (submitted == true) {
                                ErrorHandler.showSuccess(
                                  context,
                                  'Thank you for your feedback!',
                                );
                                _loadBooking();
                              }
                            });
                          },
                        ),
                    ],
                  ),
                ),
    );
  }
}
```

---

## 📦 Services Available

All these services are ready to use:

### `BookingService`
- `getUserBookings()`
- `getBookingById(id)`
- `cancelBooking(id, reason)`
- `extendBooking(id, hours)`
- `checkIn(id)`
- `checkOut(id)`

### `PaymentService`
- `generatePaymentQR(bookingId, amount)`
- `processPaymentQR(qrCode)`
- `verifyPayment(bookingId)`
- `getPaymentHistory()`

### `RatingService`
- `submitRating(parkingId, rating, review, tags)`
- `getParkingRatings(parkingId, page, limit)`
- `getMyRatings()`
- `updateRating(id, rating, review, tags)`
- `deleteRating(id)`
- `reportReview(id, reason)`

### `PromoCodeService`
- `validatePromoCode(code, parkingId, amount)`
- `applyPromoCode(bookingId, code)`
- `getAvailablePromoCodes()`
- `getPromoCodeHistory()`

### `SupportService`
- `createSupportTicket(subject, message, category)`
- `getUserTickets(status)`
- `getTicketDetails(id)`
- `replyToTicket(id, message)`
- `closeTicket(id)`
- `reopenTicket(id)`
- `getFAQ(category)`

### `NotificationService`
- `initialize()`
- `showLocalNotification(title, body, data)`
- `scheduleBookingReminder(bookingId, parkingName, time)`
- `cancelNotification(id)`
- `cancelAllNotifications()`
- `getToken()`
- `unsubscribe()`

### `ErrorHandler`
- `showErrorDialog(context, title, message, onRetry)`
- `showErrorSnackBar(context, message, onRetry)`
- `showSuccess(context, message)`
- `showWarning(context, message)`
- `showInfo(context, message)`
- `handleApiCall(apiCall, maxRetries, retryDelay)`
- `getUserFriendlyMessage(error)`
- `logError(context, error, stackTrace)`
- `validateEmail(value)`
- `validatePassword(value, minLength)`
- `validateRequired(value, fieldName)`
- `validatePhone(value)`

---

## 🚀 Quick Start Checklist

1. ✅ Install dependencies: `flutter pub get`
2. ✅ Set up Firebase (google-services.json, GoogleService-Info.plist)
3. ✅ Test location permissions
4. ✅ Test camera permissions (for QR scanning)
5. ✅ Configure backend API endpoints
6. ✅ Test on real devices (notifications don't work in simulators)

---

## 💡 Tips

- Always wrap API calls with error handlers
- Use loading states for better UX
- Test permission flows on both granted and denied scenarios
- Test with poor network conditions
- Handle edge cases (empty states, no data, etc.)

---

## 🐛 Common Issues

### Firebase not initializing:
- Check google-services.json placement
- Verify Firebase project configuration
- Ensure internet permission in AndroidManifest.xml

### Location not working:
- Check permissions in manifest files
- Test on real device, not simulator
- Ensure location services enabled on device

### QR code not displaying:
- Check network connection
- Verify booking status is correct
- Ensure QR package is imported

---

Happy coding! 🎉
