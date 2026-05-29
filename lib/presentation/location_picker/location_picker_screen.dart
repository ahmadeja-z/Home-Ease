import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homeease/core/services/geocoding_service.dart';
import 'package:homeease/core/services/permission_service.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/presentation/location_picker/models/location_picker_result.dart';
import 'package:homeease/presentation/location_picker/widgets/location_confirm_button.dart';
import 'package:homeease/presentation/location_picker/widgets/location_search_field.dart';
import 'package:homeease/widgets/custom_app_bar.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final String? initialAddress;

  const LocationPickerScreen({
    super.key,
    this.initialLocation,
    this.initialAddress,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final GeocodingService _geocoding = GeocodingService();
  final TextEditingController _searchController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _usedFallbackAddress = false;
  bool _isGeocoding = false;
  bool _isMapReady = false;
  bool _isInitializing = true;
  bool _isSearching = false;
  bool _suppressCameraIdle = false;
  String? _errorMessage;

  List<PlaceSuggestion> _suggestions = [];
  Timer? _searchDebounce;
  Timer? _geocodeDebounce;

  static const LatLng _fallbackCenter = LatLng(37.7749, -122.4194);

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.initialAddress?.trim() ?? '';
    _bootstrapLocation();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _geocodeDebounce?.cancel();
    _mapController = null;
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapLocation() async {
    if (widget.initialLocation != null) {
      if (!mounted) return;
      setState(() {
        _selectedLocation = widget.initialLocation;
        _isInitializing = false;
      });
      return;
    }

    try {
      final granted = await PermissionService.requestLocationPermission();
      if (!granted) {
        if (!mounted) return;
        setState(() {
          _selectedLocation = _fallbackCenter;
          _errorMessage =
              'Location permission denied. Search or move the map to pick a spot.';
          _isInitializing = false;
        });
        return;
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!mounted) return;
        setState(() {
          _selectedLocation = _fallbackCenter;
          _errorMessage = 'GPS is off. Search or drag the map to choose a location.';
          _isInitializing = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final latLng = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _selectedLocation = latLng;
        _isInitializing = false;
      });
      await _reverseGeocode(latLng, immediate: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _selectedLocation = _fallbackCenter;
        _errorMessage = 'Could not get GPS. Move the map or search instead.';
        _isInitializing = false;
      });
    }
  }

  Future<void> _reverseGeocode(LatLng location, {bool immediate = false}) async {
    _geocodeDebounce?.cancel();

    Future<void> run() async {
      if (!mounted) return;
      setState(() => _isGeocoding = true);

      final result = await _geocoding.resolveLocation(location);

      if (!mounted) return;
      setState(() {
        _selectedLocation = result.location;
        _selectedAddress = result.address;
        _usedFallbackAddress = result.usedFallbackAddress;
        _isGeocoding = false;
      });
    }

    if (immediate) {
      await run();
    } else {
      _geocodeDebounce = Timer(const Duration(milliseconds: 450), run);
    }
  }

  void _onSearchQueryChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 2) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);

      final results = await _geocoding.searchPlaces(
        query,
        biasLocation: _selectedLocation,
      );

      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    });
  }

  Future<void> _onSuggestionSelected(PlaceSuggestion suggestion) async {
    setState(() {
      _suggestions = [];
      _isSearching = true;
      _searchController.text = suggestion.description;
    });

    final details = await _geocoding.getPlaceDetails(suggestion.placeId);

    if (!mounted) return;

    if (details == null) {
      setState(() {
        _isSearching = false;
        _errorMessage = 'Could not load that place. Try another search.';
      });
      return;
    }

    setState(() {
      _isSearching = false;
      _selectedLocation = details.location;
      _selectedAddress = details.address;
      _usedFallbackAddress = details.usedFallbackAddress;
      _errorMessage = null;
    });

    _suppressCameraIdle = true;
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(details.location, 16),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _suppressCameraIdle = false;
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final granted = await PermissionService.requestLocationPermission();
      if (!granted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enable location permission to use current location.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final latLng = LatLng(position.latitude, position.longitude);

      _suppressCameraIdle = true;
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(latLng, 16),
      );
      await _reverseGeocode(latLng, immediate: true);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      _suppressCameraIdle = false;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onCameraIdle() {
    if (_suppressCameraIdle || !_isMapReady) return;
    final location = _selectedLocation;
    if (location == null) return;
    _reverseGeocode(location);
  }

  void _confirmSelection() {
    final location = _selectedLocation;
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select service location.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final address = _selectedAddress.trim().isEmpty
        ? 'Selected Location'
        : _selectedAddress.trim();

    Navigator.of(context).pop(
      LocationPickerResult(
        location: location,
        address: address,
        usedFallbackAddress:
            _usedFallbackAddress || _selectedAddress.trim().isEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canConfirm = _selectedLocation != null && !_isInitializing;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Pick location'),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation ?? _fallbackCenter,
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (!mounted) return;
                    setState(() => _isMapReady = true);
                    if (_selectedLocation != null &&
                        widget.initialAddress == null &&
                        _selectedAddress.isEmpty) {
                      _reverseGeocode(_selectedLocation!, immediate: true);
                    }
                  },
                  onCameraMove: (position) {
                    if (!mounted) return;
                    setState(() => _selectedLocation = position.target);
                  },
                  onCameraIdle: _onCameraIdle,
                  onTap: (latLng) {
                    _suppressCameraIdle = true;
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLng(latLng),
                    );
                    Future<void>.delayed(const Duration(milliseconds: 350), () {
                      if (!mounted) return;
                      _suppressCameraIdle = false;
                      _reverseGeocode(latLng, immediate: true);
                    });
                  },
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 36),
                    child: Icon(
                      Icons.location_on,
                      size: 48,
                      color: AppTheme.errorColor,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isGeocoding)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 72,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Material(
                        borderRadius: BorderRadius.circular(20),
                        color: theme.cardColor.withValues(alpha: 0.95),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('Updating address…'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  left: 16,
                  right: 16,
                  child: LocationSearchField(
                    controller: _searchController,
                    suggestions: _suggestions,
                    isSearching: _isSearching,
                    onQueryChanged: _onSearchQueryChanged,
                    onSuggestionSelected: _onSuggestionSelected,
                    onClear: () {
                      _searchController.clear();
                      setState(() => _suggestions = []);
                    },
                  ),
                ),
                if (_errorMessage != null)
                  Positioned(
                    top: 72,
                    left: 16,
                    right: 16,
                    child: Material(
                      color: AppTheme.warningColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppTheme.warningColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 16,
                  bottom: 200,
                  child: FloatingActionButton(
                    heroTag: 'location_picker_my_location',
                    onPressed: _goToCurrentLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: LocationConfirmButton(
                    address: _selectedAddress,
                    isLoading: _isGeocoding,
                    showFallbackWarning: _usedFallbackAddress,
                    onConfirm: canConfirm ? _confirmSelection : null,
                  ),
                ),
              ],
            ),
    );
  }
}
