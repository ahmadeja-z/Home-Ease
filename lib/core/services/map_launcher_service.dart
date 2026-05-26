import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

class MapLauncherService {
  /// Opens Google Maps app with directions to the specified location
  static Future<void> openGoogleMapsWithDirections({
    required double latitude,
    required double longitude,
    required String destinationName,
    double? userLatitude,
    double? userLongitude,
  }) async {
    String url;
    
    if (userLatitude != null && userLongitude != null) {
      // Directions from user location to destination
      url = 'https://www.google.com/maps/dir/?api=1&origin=$userLatitude,$userLongitude&destination=$latitude,$longitude&travelmode=driving';
    } else {
      // Directions to destination (Google Maps will use current location)
      url = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=driving';
    }

    await _launchUrl(url, destinationName);
  }

  /// Opens Apple Maps app with directions (iOS only)
  static Future<void> openAppleMapsWithDirections({
    required double latitude,
    required double longitude,
    required String destinationName,
    double? userLatitude,
    double? userLongitude,
  }) async {
    String url;
    
    if (userLatitude != null && userLongitude != null) {
      // Directions from user location to destination
      url = 'http://maps.apple.com/?saddr=$userLatitude,$userLongitude&daddr=$latitude,$longitude&dirflg=d';
    } else {
      // Directions to destination
      url = 'http://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d';
    }

    await _launchUrl(url, destinationName);
  }

  /// Opens Waze app with directions
  static Future<void> openWazeWithDirections({
    required double latitude,
    required double longitude,
    required String destinationName,
  }) async {
    final url = 'https://waze.com/ul?ll=$latitude,$longitude&navigate=yes';
    await _launchUrl(url, destinationName);
  }

  /// Shows a dialog with multiple map options
  static Future<void> showMapOptionsDialog({
    required BuildContext context,
    required double latitude,
    required double longitude,
    required String destinationName,
    double? userLatitude,
    double? userLongitude,
  }) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              'Navigate to $destinationName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Map options
            _buildMapOption(
              context: context,
              icon: Icons.map,
              title: 'Google Maps',
              subtitle: 'Open in Google Maps app',
              onTap: () {
                Navigator.pop(context);
                openGoogleMapsWithDirections(
                  latitude: latitude,
                  longitude: longitude,
                  destinationName: destinationName,
                  userLatitude: userLatitude,
                  userLongitude: userLongitude,
                );
              },
            ),
            
            _buildMapOption(
              context: context,
              icon: Icons.navigation,
              title: 'Apple Maps',
              subtitle: 'Open in Apple Maps app',
              onTap: () {
                Navigator.pop(context);
                openAppleMapsWithDirections(
                  latitude: latitude,
                  longitude: longitude,
                  destinationName: destinationName,
                  userLatitude: userLatitude,
                  userLongitude: userLongitude,
                );
              },
            ),
            
            _buildMapOption(
              context: context,
              icon: Icons.directions_car,
              title: 'Waze',
              subtitle: 'Open in Waze app',
              onTap: () {
                Navigator.pop(context);
                openWazeWithDirections(
                  latitude: latitude,
                  longitude: longitude,
                  destinationName: destinationName,
                );
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _buildMapOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        child: Icon(
          icon,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }

  /// Helper method to launch URL with error handling
  static Future<void> _launchUrl(String url, String destinationName) async {
    try {
      final Uri uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        print('❌ Could not launch $url');
        // You could show a snackbar or dialog here
      }
    } catch (e) {
      print('❌ Error launching map: $e');
      // You could show a snackbar or dialog here
    }
  }

  /// Quick method to open Google Maps directly (most common use case)
  static Future<void> navigateToLocation({
    required double latitude,
    required double longitude,
    required String destinationName,
    double? userLatitude,
    double? userLongitude,
  }) async {
    await openGoogleMapsWithDirections(
      latitude: latitude,
      longitude: longitude,
      destinationName: destinationName,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );
  }
}
