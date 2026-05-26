import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import '../core/services/localStorage/my-local-controller.dart';
import '../core/utils/constants.dart';
import '../models/user_model.dart';

class UserRepository {
  double? latitude;
  double? longitude;
  static final UserRepository _instance = UserRepository._internal();
  factory UserRepository() => _instance;
  UserRepository._internal();
  File? selectedImage;
  Uint8List? selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> pickImageFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      selectedImageBytes = await pickedFile.readAsBytes();
      try {
        selectedImage = File(pickedFile.path);
      } catch (_) {}
    }
  }

  Future<void> pickImageFromCamera() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      selectedImageBytes = await pickedFile.readAsBytes();
      try {
        selectedImage = File(pickedFile.path);
      } catch (_) {}
    }
  }

  Future<void> init() async {
    await loadInitialData();
  }

  UserModel? _currentUser;
  final StreamController<UserModel?> _userController =
      StreamController<UserModel?>.broadcast();

  UserModel? get currentUser => _currentUser;
  set currentUser(UserModel? user) =>
      _currentUser = user; // Allow AuthRepository to update

  StreamController<UserModel?> get userController =>
      _userController; // Allow AuthRepository to notify

  Stream<UserModel?> get userStream => _userController.stream;

  Future<UserModel?> loadInitialData() async {
    try {
      final savedUserData = await LocalStorage.getData(key: AppKeys.userData);
      if (savedUserData != null) {
        _currentUser = UserModel.fromJson(jsonDecode(savedUserData));
        _userController.add(_currentUser);
      }
      unawaited(_getCurrentLocation());
      return _currentUser;
    } catch (e) {
      log("Error loading data: $e");
      return null;
    }
  }

  Future<bool> isUserAuthenticated() async {
    final token = await LocalStorage.getData(key: AppKeys.authToken);
    return token != null;
  }

  Future<void> setUser(UserModel user) async {
    _currentUser = user;
    await LocalStorage.saveData(
      key: AppKeys.userData,
      value: jsonEncode(user.toJson()),
    );
    _userController.add(_currentUser);
  }

  Future<void> clearUser() async {
    _currentUser = null;
    await LocalStorage.removeData(key: AppKeys.userData);
    _userController.add(null);
  }

  void dispose() {
    _userController.close();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      latitude = position.latitude;
      longitude = position.longitude;
    } catch (e) {
      debugPrint('⚠️ Error getting location: $e');
    }
  }

  Future<void> updateFcmToken(String fcmToken) async {
    if (_currentUser == null || _currentUser!.id == null) return;

    try {
      final supabase = Supabase.instance.client;
      final updatedAt = DateTime.now().toIso8601String();

      await supabase
          .from('profiles')
          .update({'deviceFcmToken': fcmToken, 'updated_at': updatedAt})
          .eq('id', _currentUser!.id!);

      _currentUser!.deviceFcmToken = fcmToken;
      _currentUser!.updatedAt = DateTime.parse(updatedAt);
      await setUser(_currentUser!);
    } catch (e) {
      log("❌ [UserRepository] Error updating FCM token: $e");
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    final supabase = Supabase.instance.client;
    await supabase
        .from('profiles')
        .update({
          'name': user.name,
          'phone_number': user.phoneNumber,
          'profile_picture': user.profileImage,
          'latitude': user.address?.latitude,
          'longitude': user.address?.longitude,
          'address': user.address?.address,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', user.id!);
  }
}
