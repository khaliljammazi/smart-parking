# Smart Parking App

A Flutter-based mobile application for finding and booking parking spots.

## Features

- **Find Parking**: Browse available parking spots with details
- **Booking System**: Reserve parking spots with real-time availability
- **User Authentication**: Secure login and registration
- **Vehicle Management**: Add and manage personal vehicles
- **Notifications**: Real-time updates on bookings and activities
- **Location Services**: GPS-based parking suggestions
- **User Interface**: Clean and intuitive UI with Material Design

## Prerequisites

- Flutter SDK (version 3.0 or higher)
- Dart SDK
- Android Studio or Xcode for mobile development
- Google Cloud account for Maps API

## Getting Started

1. Ensure Flutter is installed and set up
2. Clone the repository
3. Run `flutter pub get` to install dependencies
4. For web development: Run `flutter run -d chrome --web-port=51919`
5. For mobile: Run `flutter run` to start the app on connected device/emulator

## Project Structure

- `lib/account/`: User account management and profile pages
- `lib/activity/`: User activity and booking history
- `lib/authentication/`: Login, registration, and OTP verification
- `lib/booking/`: Booking process and slot selection
- `lib/bottombar/`: Bottom navigation bar components
- `lib/home/`: Home page with nearby parking suggestions
- `lib/identification/`: User identification and verification
- `lib/introduction/`: App introduction and splash screens
- `lib/location/`: Location services and parking suggestions
- `lib/model/`: Data models for parking, users, etc.
- `lib/network/`: API services and backend communication
- `lib/notification/`: Push notifications and alerts
- `lib/otp/`: OTP verification pages
- `lib/parkingdetail/`: Detailed parking information pages
- `lib/parkinglist/`: List of available parking spots
- `lib/personalinformation/`: Personal information management
- `lib/utils/`: Utilities, themes, and common widgets
- `lib/vehicle/`: Vehicle management and forms
- `lib/wallet/`: Payment and wallet integration

## Google Maps Setup

To use Google Maps functionality, you need to configure a Google Maps API key:

### For Web:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. **Enable Billing**: Google Maps requires a billing account to be enabled
4. Enable the "Maps JavaScript API"
5. Create credentials (API Key)
6. The API key `` is already configured in the app

### For Android:
1. The API key is already configured in `android/app/build.gradle.kts` and `AndroidManifest.xml`

### For iOS:
1. Add your API key to `ios/Runner/AppDelegate.swift` or create a `ios/Runner/Info.plist` entry

**Important**: Google Maps requires billing to be enabled on your Google Cloud project. Without billing enabled, you'll see a "BillingNotEnabledMapError" even with a valid API key.

### Environment Setup:
1. Copy `.env` file and add your Google Maps API key:
   ```bash
   ```
2. **Important**: Never commit `.env` file to version control - it's already in `.gitignore`

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

flutter run -d chrome --web-port=51919