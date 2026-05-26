import 'dart:io';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../models/user_model.dart';

enum ProfileStatus { initial, loading, success, failure, updating }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final UserModel? user;
  final File? selectedImage;
  final Uint8List? selectedImageBytes;
  final String? error;
  final String? message;
  final DateTime? lastEditTime; // Added to force rebuilds on controller changes
  final GlobalKey<FormState> formKey;

  // Controllers are usually in the UI, but user requested them in state.
  // We'll provide them as part of the state for their specific architecture.
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;

  ProfileState({
    this.status = ProfileStatus.initial,
    this.user,
    this.selectedImage,
    this.selectedImageBytes,
    this.error,
    this.message,
    this.lastEditTime,
    GlobalKey<FormState>? formKey,
    TextEditingController? nameController,
    TextEditingController? emailController,
    TextEditingController? phoneController,
    TextEditingController? addressController,
  }) : formKey = formKey ?? GlobalKey<FormState>(),
       nameController = nameController ?? TextEditingController(),
       emailController = emailController ?? TextEditingController(),
       phoneController = phoneController ?? TextEditingController(),
       addressController = addressController ?? TextEditingController();

  bool get isModified {
    final nameChanged = nameController.text != (user?.name ?? '');
    final phoneChanged = phoneController.text != (user?.phoneNumber ?? '');
    final addressChanged =
        addressController.text != (user?.address?.address ?? '');
    final imageChanged = selectedImageBytes != null;
    return nameChanged || phoneChanged || addressChanged || imageChanged;
  }

  static const Object _undefined = Object();

  ProfileState copyWith({
    ProfileStatus? status,
    UserModel? user,
    File? selectedImage,
    Uint8List? selectedImageBytes,
    LatLng? selectedLocation,
    Object? error = _undefined,
    Object? message = _undefined,
    DateTime? lastEditTime,
  }) {
    return ProfileState(
      status: status ?? this.status,
      user: user ?? this.user,
      selectedImage: selectedImage ?? this.selectedImage,
      selectedImageBytes: selectedImageBytes ?? this.selectedImageBytes,
      error: error == _undefined ? this.error : (error as String?),
      message: message == _undefined ? this.message : (message as String?),
      lastEditTime: lastEditTime ?? this.lastEditTime,
      formKey: formKey,
      nameController: nameController,
      emailController: emailController,
      phoneController: phoneController,
      addressController: addressController,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    selectedImage,
    selectedImageBytes,
    error,
    message,
    lastEditTime,
  ];
}
