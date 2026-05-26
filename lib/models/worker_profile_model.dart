/// Latest worker row from [profiles], merged with map [NearbyWorkerModel] in the UI.
class WorkerProfileModel {
  final String id;
  final String? name;
  final String? profilePicture;
  final String? phoneNumber;
  final double? rating;
  final String? categoryId;
  final String? status;
  final String? role;
  final bool? isActive;

  const WorkerProfileModel({
    required this.id,
    this.name,
    this.profilePicture,
    this.phoneNumber,
    this.rating,
    this.categoryId,
    this.status,
    this.role,
    this.isActive,
  });

  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      throw FormatException('WorkerProfileModel requires id');
    }
    return WorkerProfileModel(
      id: id,
      name: json['name']?.toString(),
      profilePicture: json['profile_picture']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      categoryId: json['category_id']?.toString(),
      status: json['status']?.toString(),
      role: json['role']?.toString(),
      isActive: json['is_active'] as bool?,
    );
  }
}
