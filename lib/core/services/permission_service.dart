import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' show Platform;

/// Service to handle app permissions across iOS and Android
class PermissionService {
  /// Request location permission (using geolocator for better iOS support)
  /// Returns true if permission is granted, false otherwise
  static Future<bool> requestLocationPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check current permission
    LocationPermission permission = await Geolocator.checkPermission();
    
    // If denied, request permission
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    // Return true if granted (either whileInUse or always)
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  /// Check if location permission is granted
  static Future<bool> isLocationPermissionGranted() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse || 
           permission == LocationPermission.always;
  }

  /// Check if location permission is permanently denied
  static Future<bool> isLocationPermissionPermanentlyDenied() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.deniedForever;
  }

  /// Request camera permission (for QR scanning)
  /// Returns true if permission is granted, false otherwise
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Check if camera permission is granted
  static Future<bool> isCameraPermissionGranted() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Request photo library permission
  /// Returns true if permission is granted, false otherwise
  static Future<bool> requestPhotoLibraryPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Check if photo library permission is granted
  static Future<bool> isPhotoLibraryPermissionGranted() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  /// Request notification permission
  /// Returns true if permission is granted, false otherwise
  static Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Check if notification permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Open app settings
  /// This is useful when permission is permanently denied
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Get location permission status message for UI
  static Future<String> getLocationPermissionStatusMessage() async {
    final permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.whileInUse || 
        permission == LocationPermission.always) {
      return 'Location permission granted';
    } else if (permission == LocationPermission.denied) {
      return 'Location permission denied. Please allow location access to use this feature.';
    } else if (permission == LocationPermission.deniedForever) {
      if (Platform.isIOS) {
        return 'Location permission denied. Please go to Settings > Speezu > Location to enable.';
      } else {
        return 'Location permission denied. Please go to app settings to enable.';
      }
    } else if (permission == LocationPermission.unableToDetermine) {
      return 'Unable to determine location permission status.';
    }
    
    return 'Location permission status unknown';
  }

  /// Get camera permission status message for UI
  static Future<String> getCameraPermissionStatusMessage() async {
    final status = await Permission.camera.status;
    
    if (status.isGranted) {
      return 'Camera permission granted';
    } else if (status.isDenied) {
      return 'Camera permission denied. Please allow camera access to scan QR codes.';
    } else if (status.isPermanentlyDenied) {
      if (Platform.isIOS) {
        return 'Camera permission permanently denied. Please go to Settings > Speezu > Camera to enable.';
      } else {
        return 'Camera permission permanently denied. Please go to app settings to enable.';
      }
    } else if (status.isRestricted) {
      return 'Camera access is restricted on this device.';
    }
    
    return 'Camera permission status unknown';
  }

  /// Request all required permissions at once
  /// Useful for onboarding screens
  static Future<Map<String, bool>> requestAllPermissions() async {
    final locationGranted = await requestLocationPermission();
    final notificationGranted = await requestNotificationPermission();
    
    return {
      'location': locationGranted,
      'notification': notificationGranted,
    };
  }
}

