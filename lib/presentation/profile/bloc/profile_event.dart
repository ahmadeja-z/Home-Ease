import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {}

class UpdateName extends ProfileEvent {
  final String name;
  const UpdateName(this.name);

  @override
  List<Object?> get props => [name];
}

class UpdatePhone extends ProfileEvent {
  final String phone;
  const UpdatePhone(this.phone);

  @override
  List<Object?> get props => [phone];
}

class UpdateAddress extends ProfileEvent {
  final String address;
  final LatLng location;
  const UpdateAddress({required this.address, required this.location});

  @override
  List<Object?> get props => [address, location];
}

class PickImage extends ProfileEvent {}

class PickImageFromCamera extends ProfileEvent {}

class ProfileEdited extends ProfileEvent {}

class SaveProfile extends ProfileEvent {}

class UploadProfileImage extends ProfileEvent {
  final String userId;
  final Uint8List imageBytes;

  const UploadProfileImage({required this.userId, required this.imageBytes});

  @override
  List<Object?> get props => [userId, imageBytes];
}
