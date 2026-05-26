import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Online worker shown on the customer map (all online workers in range).
class NearbyWorkerModel {
  final String id;
  final String name;
  final String? profileImage;
  final double rating;
  final double distance;
  final LatLng location;
  final bool isOnline;
  final String? categoryId;
  final String? categoryName;
  final double? perHourRate;
  final int? completedJobs;

  NearbyWorkerModel({
    required this.id,
    required this.name,
    this.profileImage,
    required this.rating,
    required this.distance,
    required this.location,
    required this.isOnline,
    this.categoryId,
    this.categoryName,
    this.perHourRate,
    this.completedJobs,
  });

  factory NearbyWorkerModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? json['worker_id']?.toString();
    if (id == null || id.isEmpty) {
      throw FormatException('NearbyWorkerModel requires id: $json');
    }

    return NearbyWorkerModel(
      id: id,
      name: json['name']?.toString() ?? '',
      profileImage: json['profile_picture']?.toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      location: LatLng(
        (json['latitude'] as num?)?.toDouble() ?? 0.0,
        (json['longitude'] as num?)?.toDouble() ?? 0.0,
      ),
      isOnline: json['is_online'] as bool? ?? false,
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name']?.toString(),
      perHourRate: (json['per_hour_rate'] as num?)?.toDouble(),
      completedJobs: (json['completed_jobs'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profile_picture': profileImage,
      'rating': rating,
      'distance': distance,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'is_online': isOnline,
      'category_id': categoryId,
      'category_name': categoryName,
      'per_hour_rate': perHourRate,
      'completed_jobs': completedJobs,
    };
  }

  NearbyWorkerModel copyWith({
    String? id,
    String? name,
    String? profileImage,
    double? rating,
    double? distance,
    LatLng? location,
    bool? isOnline,
    String? categoryId,
    String? categoryName,
    double? perHourRate,
    int? completedJobs,
  }) {
    return NearbyWorkerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      rating: rating ?? this.rating,
      distance: distance ?? this.distance,
      location: location ?? this.location,
      isOnline: isOnline ?? this.isOnline,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      perHourRate: perHourRate ?? this.perHourRate,
      completedJobs: completedJobs ?? this.completedJobs,
    );
  }
}
