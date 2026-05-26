import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeocodingService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
  
  static const String _defaultApiKey = 'AIzaSyCWQhybU7pl0dVWxzADgb_Hm-qrRPyUc98';

  String get _apiKey {
    final envKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    return envKey.isNotEmpty ? envKey : _defaultApiKey;
  }

  Future<String?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final url = Uri.parse('$_baseUrl?latlng=$lat,$lng&key=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          // formatted_address usually contains the full readable address
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
}
