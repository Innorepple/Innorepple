import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  /// Get current location with permission handling
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      print('Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  /// Get location for emergency situations (more aggressive approach)
  Future<Position?> getEmergencyLocation() async {
    try {
      // For emergency, try to get any available location quickly
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Try to open location settings
        await Geolocator.openLocationSettings();
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        // For emergency, request permission
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        // Try to get last known position as fallback
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          print('Using last known location for emergency: ${lastKnown.latitude}, ${lastKnown.longitude}');
          return lastKnown;
        }
        return null;
      }

      // Get current position with lower accuracy for speed
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      
      print('Emergency location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Error getting emergency location: $e');
      // Try last known position as final fallback
      try {
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          print('Using last known position as fallback: ${lastKnown.latitude}, ${lastKnown.longitude}');
          return lastKnown;
        }
      } catch (e2) {
        print('Error getting last known position: $e2');
      }
      return null;
    }
  }

  /// Convert position to readable address (requires geocoding service - optional)
  String formatLocationForSMS(Position position) {
    return 'Emergency Location: https://maps.google.com/?q=${position.latitude},${position.longitude}';
  }

  /// Create location data map for Firestore
  Map<String, dynamic> createLocationData(Position position, String userId) {
    return {
      'userId': userId,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
      'timestamp': DateTime.now().toIso8601String(),
      'altitude': position.altitude,
      'speed': position.speed,
      'heading': position.heading,
      'googleMapsUrl': 'https://maps.google.com/?q=${position.latitude},${position.longitude}',
      'type': 'emergency_sos',
    };
  }
}