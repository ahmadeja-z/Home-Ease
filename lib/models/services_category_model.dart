import 'package:uuid/uuid.dart';

class ServicesCategoriesModel {
  final String id;
  final String name;
  final String? description;
  final String? picture;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServicesCategoriesModel({
    String? id,
    required this.name,
    this.description,
    this.picture,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Convert a Map from Supabase / JSON to CategoryModel object
  factory ServicesCategoriesModel.fromMap(Map<String, dynamic> map) {
    return ServicesCategoriesModel(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      picture: map['picture'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  // Convert CategoryModel object to Map for inserting/updating in Supabase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'picture': picture,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ServicesCategoriesModel copyWith({
    String? id,
    String? name,
    String? description,
    String? picture,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServicesCategoriesModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      picture: picture ?? this.picture,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
