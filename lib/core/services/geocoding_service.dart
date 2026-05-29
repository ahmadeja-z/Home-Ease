import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homeease/presentation/location_picker/models/location_picker_result.dart';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _geocodeBaseUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';
  static const String _placesAutocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static const String _placeDetailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  static const String _defaultApiKey = 'AIzaSyCWQhybU7pl0dVWxzADgb_Hm-qrRPyUc98';

  String get _apiKey {
    final envKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    return envKey.isNotEmpty ? envKey : _defaultApiKey;
  }

  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final url = Uri.parse('$_geocodeBaseUrl?latlng=$lat,$lng&key=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          return data['results'][0]['formatted_address'] as String;
        } else {
          debugPrint('Geocoding API error: ${data['status']}');
        }
      } else {
        debugPrint('Geocoding HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Geocoding exception: $e');
    }
    return null;
  }

  /// Forward geocode a free-text query (fallback when Places is unavailable).
  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    if (address.trim().isEmpty) return null;

    try {
      final url = Uri.parse(
        '$_geocodeBaseUrl?address=${Uri.encodeComponent(address)}&key=$_apiKey',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final loc = data['results'][0]['geometry']['location'];
          return LatLng(
            (loc['lat'] as num).toDouble(),
            (loc['lng'] as num).toDouble(),
          );
        }
      }
    } catch (e) {
      debugPrint('Forward geocoding exception: $e');
    }
    return null;
  }

  /// Google Places Autocomplete suggestions.
  Future<List<PlaceSuggestion>> searchPlaces(
    String query, {
    LatLng? biasLocation,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    try {
      var url =
          '$_placesAutocompleteUrl?input=${Uri.encodeComponent(trimmed)}&key=$_apiKey';
      if (biasLocation != null) {
        url +=
            '&location=${biasLocation.latitude},${biasLocation.longitude}&radius=50000';
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
        debugPrint('Places autocomplete: ${data['status']}');
        return [];
      }

      final predictions = data['predictions'] as List<dynamic>? ?? [];
      return predictions.map((p) {
        final map = p as Map<String, dynamic>;
        final structured = map['structured_formatting'] as Map<String, dynamic>?;
        return PlaceSuggestion(
          placeId: map['place_id'] as String,
          description: map['description'] as String? ?? '',
          mainText: structured?['main_text'] as String? ??
              map['description'] as String? ??
              '',
          secondaryText: structured?['secondary_text'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('Places search exception: $e');
    }
    return [];
  }

  /// Resolve place_id to coordinates + formatted address.
  Future<LocationPickerResult?> getPlaceDetails(String placeId) async {
    try {
      final url = Uri.parse(
        '$_placeDetailsUrl?place_id=${Uri.encodeComponent(placeId)}&fields=geometry,formatted_address&key=$_apiKey',
      );
      final response = await http.get(url);

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;

      final result = data['result'] as Map<String, dynamic>;
      final geometry = result['geometry'] as Map<String, dynamic>;
      final loc = geometry['location'] as Map<String, dynamic>;
      final lat = (loc['lat'] as num).toDouble();
      final lng = (loc['lng'] as num).toDouble();
      final address = result['formatted_address'] as String? ?? '';

      return LocationPickerResult(
        location: LatLng(lat, lng),
        address: address.isNotEmpty ? address : 'Selected Location',
        usedFallbackAddress: address.isEmpty,
      );
    } catch (e) {
      debugPrint('Place details exception: $e');
    }
    return null;
  }

  /// Reverse geocode with fallback label.
  Future<LocationPickerResult> resolveLocation(LatLng location) async {
    final address = await getAddressFromCoordinates(
      location.latitude,
      location.longitude,
    );

    if (address != null && address.trim().isNotEmpty) {
      return LocationPickerResult(
        location: location,
        address: address,
      );
    }

    return LocationPickerResult(
      location: location,
      address: 'Selected Location',
      usedFallbackAddress: true,
    );
  }
}
