# Smart Parking App

A Flutter-based mobile application for finding and booking parking spots.

## Features

- **Find Parking**: Browse available parking spots with details
- **Booking System**: Reserve parking spots (static mock for now)
- **User Interface**: Clean and intuitive UI with Material Design

## Getting Started

1. Ensure Flutter is installed
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## Project Structure

- `lib/home/`: Home page
- `lib/parkinglist/`: Parking list and details
- `lib/model/`: Data models
- `lib/utils/`: Utilities and constants

## Google Maps Setup

To use Google Maps functionality, you need to configure a Google Maps API key:

### For Web:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. **Enable Billing**: Google Maps requires a billing account to be enabled
4. Enable the "Maps JavaScript API"
5. Create credentials (API Key)
6. The API key `AIzaSyCYxFkL9vcvbaFz-Ut1Lm2Vge5byodujfk` is already configured in the app

### For Android:
1. The API key is already configured in `android/app/build.gradle.kts` and `AndroidManifest.xml`

### For iOS:
1. Add your API key to `ios/Runner/AppDelegate.swift` or create a `ios/Runner/Info.plist` entry

**Important**: Google Maps requires billing to be enabled on your Google Cloud project. Without billing enabled, you'll see a "BillingNotEnabledMapError" even with a valid API key.

### Environment Setup:
1. Copy `.env` file and add your Google Maps API key:
   ```bash
   GOOGLE_MAPS_API_KEY=your_actual_api_key_here
   ```
2. **Important**: Never commit `.env` file to version control - it's already in `.gitignore`

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
