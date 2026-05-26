import 'package:equatable/equatable.dart';

class BannerModel extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String redirectType;
  final String? redirectId;
  final int priority;
  final bool isActive;

  const BannerModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.redirectType,
    this.redirectId,
    required this.priority,
    required this.isActive,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['image_url'] ?? '',
      redirectType: json['redirect_type'] ?? '',
      redirectId: json['redirect_id']?.toString(),
      priority: json['priority'] ?? 2,
      isActive: json['is_active'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'redirect_type': redirectType,
      'redirect_id': redirectId,
      'priority': priority,
      'is_active': isActive,
    };
  }

  BannerModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? redirectType,
    String? redirectId,
    int? priority,
    bool? isActive,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      redirectType: redirectType ?? this.redirectType,
      redirectId: redirectId ?? this.redirectId,
      priority: priority ?? this.priority,
      isActive: isActive ?? this.isActive,
    );
  }

  String getPriorityLabel() {
    switch (priority) {
      case 4:
        return 'Very High';
      case 3:
        return 'High';
      case 2:
        return 'Medium';
      case 1:
        return 'Low';
      default:
        return 'Medium';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        imageUrl,
        redirectType,
        redirectId,
        priority,
        isActive,
      ];
}
