import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Model class for route information
class RouteInfo {
  final List<LatLng> polylinePoints;
  final String distanceText;
  final String durationText;
  final int distanceValue; // in meters
  final int durationValue; // in seconds

  const RouteInfo({
    required this.polylinePoints,
    required this.distanceText,
    required this.durationText,
    required this.distanceValue,
    required this.durationValue,
  });
}

/// Service for fetching route directions from Google Directions API
class DirectionsService {
  static final DirectionsService _instance = DirectionsService._internal();
  factory DirectionsService() => _instance;
  DirectionsService._internal();

  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  // Use the same API key as configured in Android/iOS native configs
  // This is the key from android/app/src/main/AndroidManifest.xml and ios/Runner/AppDelegate.swift
  static const String _defaultApiKey =
      'AIzaSyCWQhybU7pl0dVWxzADgb_Hm-qrRPyUc98';

  /// Get Google Maps API key - first tries .env, then uses default
  String get _apiKey {
    final envKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (envKey.isNotEmpty) {
      return envKey;
    }
    // Fallback to the same key used in native configs
    return _defaultApiKey;
  }

  /// Fetch route between origin and destination
  /// Returns [RouteInfo] containing polyline points, distance, and duration
  Future<RouteInfo?> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=driving'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        debugPrint('Directions API error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK') {
        debugPrint('Directions API status: ${data['status']}');
        debugPrint(
          'Error message: ${data['error_message'] ?? 'Unknown error'}',
        );
        return null;
      }

      if (data['routes'] == null || (data['routes'] as List).isEmpty) {
        debugPrint('No routes found');
        return null;
      }

      final route = data['routes'][0];
      final leg = route['legs'][0];

      // Decode the polyline
      final encodedPolyline = route['overview_polyline']['points'] as String;
      final polylinePoints = _decodePolyline(encodedPolyline);

      // Extract distance and duration
      final distance = leg['distance'];
      final duration = leg['duration'];

      return RouteInfo(
        polylinePoints: polylinePoints,
        distanceText: distance['text'] as String,
        durationText: duration['text'] as String,
        distanceValue: distance['value'] as int,
        durationValue: duration['value'] as int,
      );
    } catch (e) {
      debugPrint('Error fetching directions: $e');
      return null;
    }
  }

  /// Decode Google's encoded polyline format into LatLng points
  List<LatLng> _decodePolyline(String encoded) {
    // Instantiate PolylinePoints to call decodePolyline
    final result = PolylinePoints.decodePolyline(encoded);

    return result
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();
  }

  /// Calculate bounds that contain both points with padding
  LatLngBounds calculateBounds(LatLng origin, LatLng destination) {
    final double minLat = origin.latitude < destination.latitude
        ? origin.latitude
        : destination.latitude;
    final double maxLat = origin.latitude > destination.latitude
        ? origin.latitude
        : destination.latitude;
    final double minLng = origin.longitude < destination.longitude
        ? origin.longitude
        : destination.longitude;
    final double maxLng = origin.longitude > destination.longitude
        ? origin.longitude
        : destination.longitude;

    // Add padding (approximately 10%)
    final double latPadding = (maxLat - minLat) * 0.2;
    final double lngPadding = (maxLng - minLng) * 0.2;

    return LatLngBounds(
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
    );
  }
}
