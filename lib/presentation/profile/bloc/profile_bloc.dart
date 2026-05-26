import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homeease/core/services/geocoding_service.dart';
import 'package:homeease/models/address_model.dart';
import 'package:homeease/models/user_model.dart';
import 'package:homeease/repositories/user_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserRepository userRepository;
  final GeocodingService geocodingService = GeocodingService();

  ProfileBloc({required this.userRepository}) : super(ProfileState()) {
    on<LoadProfile>(_onLoadProfile);
    on<PickImage>(_onPickImage);
    on<PickImageFromCamera>(_onPickImageFromCamera);
    on<SaveProfile>(_onSaveProfile);
    on<UploadProfileImage>(_onUploadProfileImage);
    on<ProfileEdited>(
      (event, emit) => emit(
        state.copyWith(
          message: null,
          error: null,
          lastEditTime: DateTime.now(),
        ),
      ),
    );
  }

  void _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) {
    final user = userRepository.currentUser;
    if (user != null) {
      state.nameController.text = user.name ?? '';
      state.emailController.text = user.email ?? '';
      state.phoneController.text = user.phoneNumber ?? '';
      state.addressController.text = user.address?.address ?? '';

      emit(
        state.copyWith(
          status: ProfileStatus.success,
          user: user,
          selectedLocation: user.address != null
              ? (user.address!.latitude != null &&
                        user.address!.longitude != null
                    ? LatLng(user.address!.latitude!, user.address!.longitude!)
                    : null)
              : null,
        ),
      );
    }
  }

  Future<void> _onPickImage(PickImage event, Emitter<ProfileState> emit) async {
    await userRepository.pickImageFromGallery();
    if (userRepository.selectedImageBytes != null) {
      emit(
        state.copyWith(
          selectedImage: userRepository.selectedImage,
          selectedImageBytes: userRepository.selectedImageBytes,
          message: null,
          error: null,
        ),
      );
    }
  }

  Future<void> _onPickImageFromCamera(
    PickImageFromCamera event,
    Emitter<ProfileState> emit,
  ) async {
    await userRepository.pickImageFromCamera();
    if (userRepository.selectedImageBytes != null) {
      emit(
        state.copyWith(
          selectedImage: userRepository.selectedImage,
          selectedImageBytes: userRepository.selectedImageBytes,
          message: null,
          error: null,
        ),
      );
    }
  }

  Future<void> _onSaveProfile(
    SaveProfile event,
    Emitter<ProfileState> emit,
  ) async {
    if (!state.formKey.currentState!.validate()) return;

    emit(
      state.copyWith(
        status: ProfileStatus.updating,
        message: null,
        error: null,
      ),
    );

    try {
      final currentUser = userRepository.currentUser;
      if (currentUser == null) {
        emit(
          state.copyWith(
            status: ProfileStatus.failure,
            error: "User session not found",
          ),
        );
        return;
      }
      String? profileImageUrl;
      if (state.selectedImageBytes != null) {
        print("uploadingImage");
        profileImageUrl = await _onUploadProfileImage(
          UploadProfileImage(
            userId: currentUser.id!,
            imageBytes: state.selectedImageBytes!,
          ),
          emit,
        );
        print("image uploaded $profileImageUrl");
      }
      // Create updated address model
      final updatedAddress = AddressModel(
        address: state.addressController.text,
      );

      // Create updated user model
      final updatedUser = UserModel(
        id: currentUser.id,
        name: state.nameController.text,
        email: currentUser.email, // Non-editable
        phoneNumber: state.phoneController.text,
        role: currentUser.role,
        address: updatedAddress,
        status: currentUser.status,
        isActive: currentUser.isActive,
        verification: currentUser.verification,
        profileImage: profileImageUrl ?? currentUser.profileImage,
        createdAt: currentUser.createdAt,
        updatedAt: DateTime.now(),
        deviceFcmToken: currentUser.deviceFcmToken,
      );

      // Persist changes
      await userRepository.setUser(updatedUser);
      await userRepository.updateUserProfile(updatedUser);

      emit(
        state.copyWith(
          status: ProfileStatus.success,
          user: updatedUser,
          selectedImage: null,
          selectedImageBytes: null,
          message: 'Profile updated successfully!',
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, error: e.toString()));
      print("error $e");
    }
  }

  Future<String?> _onUploadProfileImage(
    UploadProfileImage event,
    Emitter<ProfileState> emit,
  ) async {
    final supabase = Supabase.instance.client;

    final filePath =
        "profiles/${event.userId}-${DateTime.now().millisecondsSinceEpoch}.png";

    await supabase.storage
        .from('profile-images')
        .uploadBinary(
          filePath,
          event.imageBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final imageUrl = supabase.storage
        .from('profile-images')
        .getPublicUrl(filePath);

    return imageUrl;
  }
}
