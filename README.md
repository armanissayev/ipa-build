# Flutter Maps Application

A Flutter application that provides interactive map functionality with features like location search, marker placement, and route directions.

## Features

- Interactive Google Maps integration
- Current location tracking
- Location search functionality
- Place markers on the map
- Save favorite locations
- Get directions to selected locations
- Custom map controls (zoom in/out)
- Beautiful and intuitive UI

## Prerequisites

Before running this project, make sure you have the following installed:

1. **Flutter SDK**
   - Download from: https://docs.flutter.dev/get-started/install
   - Run `flutter doctor` to verify installation

2. **Android Studio** (for Android development)
   - Download from: https://developer.android.com/studio
   - Install Android SDK through Android Studio
   - Accept Android licenses by running `flutter doctor --android-licenses`

3. **Xcode** (for iOS development, macOS only)
   - Download from the Mac App Store
   - Install Xcode Command Line Tools

4. **Google Maps API Key**
   - Get an API key from the [Google Cloud Console](https://console.cloud.google.com/)
   - Enable the following APIs:
     - Maps SDK for Android
     - Maps SDK for iOS
     - Places API
     - Directions API

## Setup

1. **Clone the repository**
   ```bash
   git clone [[your-repository-url]](https://github.com/armanissayev/ipa-build.git)
   cd ipa-build
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

- `lib/main.dart` - Main application file
- `assets/` - Contains app assets (images, etc.)
- `android/` - Android-specific configuration
- `ios/` - iOS-specific configuration

## Dependencies

The project uses the following main dependencies:
- `google_maps_flutter` - For Google Maps integration
- `geolocator` - For location services
- `google_maps_webservice` - For Places and Directions API
- `flutter_polyline_points` - For route visualization

## Troubleshooting

If you encounter any issues:

1. Run `flutter doctor` to check for setup issues
2. Ensure all API keys are properly configured
3. Check that location services are enabled on your device
4. Verify that you have accepted all necessary licenses

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details.
