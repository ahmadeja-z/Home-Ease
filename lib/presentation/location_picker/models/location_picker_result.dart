import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerResult {
  final LatLng location;
  final String address;
  final bool usedFallbackAddress;

  const LocationPickerResult({
    required this.location,
    required this.address,
    this.usedFallbackAddress = false,
  });
}

class PlaceSuggestion {
  final String placeId;
  final String description;
  final String mainText;
  final String? secondaryText;

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    required this.mainText,
    this.secondaryText,
  });
}
