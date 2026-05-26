// ─────────────────────────────────────────────────────────────────────────────
// ExtraImage (stored as JSON inside services table)
// ─────────────────────────────────────────────────────────────────────────────

class ExtraImage {
  final String url;
  final String? serviceId;

  ExtraImage({required this.url, this.serviceId});

  factory ExtraImage.fromJson(Map<String, dynamic> json) {
    return ExtraImage(url: json['url'] ?? '', serviceId: json['service_id']);
  }

  Map<String, dynamic> toJson() {
    return {'url': url, if (serviceId != null) 'service_id': serviceId};
  }

  ExtraImage copyWith({String? url, String? serviceId}) {
    return ExtraImage(
      url: url ?? this.url,
      serviceId: serviceId ?? this.serviceId,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tool (stored as JSON)
// ─────────────────────────────────────────────────────────────────────────────

class Tool {
  final String name;
  final int quantity;
  final bool isIncluded;

  Tool({required this.name, this.quantity = 1, this.isIncluded = true});

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      name: json['name'] ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      isIncluded: json['is_included'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'quantity': quantity, 'is_included': isIncluded};
  }

  Tool copyWith({String? name, int? quantity, bool? isIncluded}) {
    return Tool(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isIncluded: isIncluded ?? this.isIncluded,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ServicesModel
// ─────────────────────────────────────────────────────────────────────────────

class ServicesModel {
  final int? id;
  final String title;
  final String? mainImage;
  final List<ExtraImage> extraImages;
  final String categoryId;
  final String description;
  final double perHourRate;
  final double minimumHours;
  final double rating;
  final String? location;
  final List<Tool> toolsIncluded;
  final String? note;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? categoryTitle;
  final bool? isFixedJob;
  final double? fixedJobRate;

  bool get usesFixedJobPricing => isFixedJob == true;

  /// True when UI should show [fixedJobRate] instead of hourly pricing.
  bool get showFixedPrice =>
      usesFixedJobPricing && fixedJobRate != null && fixedJobRate! > 0;

  ServicesModel({
    this.id,
    required this.title,
    this.mainImage,
    List<ExtraImage>? extraImages,
    required this.categoryId,
    required this.description,
    required this.perHourRate,
    required this.minimumHours,
    this.rating = 0.0,
    this.location,
    List<Tool>? toolsIncluded,
    this.note,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.categoryTitle,
    this.isFixedJob = false,
    this.fixedJobRate,
  }) : extraImages = extraImages ?? [],
       toolsIncluded = toolsIncluded ?? [];

  // ───────────── FROM JSON ─────────────

  factory ServicesModel.fromJson(Map<String, dynamic> json) {
    return ServicesModel(
      id: json['id'] as int?,
      title: json['title'] ?? '',
      mainImage: json['main_image'],
      extraImages:
          (json['extra_images'] as List?)
              ?.map((e) => ExtraImage.fromJson(e))
              .toList() ??
          [],
      categoryId: json['category_id'] ?? '',
      description: json['description'] ?? '',
      perHourRate: (json['per_hour_rate'] as num?)?.toDouble() ?? 0.0,
      minimumHours: (json['minimum_hours'] as num?)?.toDouble() ?? 1,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      location: json['location'],
      toolsIncluded:
          (json['tools_included'] as List?)
              ?.map((e) => Tool.fromJson(e))
              .toList() ??
          [],
      categoryTitle: json['categoryTitle'] ?? '',
      note: json['note'],
      isActive: json['is_active'] ?? true,
      isFixedJob: json['is_fixed_job'] ?? false,
      fixedJobRate: json['fixed_job_rate'] != null
          ? (json['fixed_job_rate'] as num).toDouble()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // ───────────── TO JSON (FOR INSERT) ─────────────

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'main_image': mainImage,
      'extra_images': extraImages.map((e) => e.toJson()).toList(),
      'category_id': categoryId,
      'description': description,
      'per_hour_rate': perHourRate,
      'minimum_hours': minimumHours,
      'rating': rating,
      'location': location,
      'tools_included': toolsIncluded.map((t) => t.toJson()).toList(),
      'note': note,
      'is_active': isActive,
      'is_fixed_job': isFixedJob,
      'fixed_job_rate': fixedJobRate,
    };
  }

  // ───────────── COPY WITH ─────────────

  ServicesModel copyWith({
    int? id,
    String? title,
    String? mainImage,
    List<ExtraImage>? extraImages,
    String? categoryId,
    String? description,
    double? perHourRate,
    double? minimumHours,
    double? rating,
    String? location,
    List<Tool>? toolsIncluded,
    String? note,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryTitle,
    bool? isFixedJob,
    double? fixedJobRate,
  }) {
    return ServicesModel(
      id: id ?? this.id,
      title: title ?? this.title,
      mainImage: mainImage ?? this.mainImage,
      extraImages: extraImages ?? this.extraImages,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      perHourRate: perHourRate ?? this.perHourRate,
      minimumHours: minimumHours ?? this.minimumHours,
      rating: rating ?? this.rating,
      location: location ?? this.location,
      toolsIncluded: toolsIncluded ?? this.toolsIncluded,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      isFixedJob: isFixedJob ?? this.isFixedJob,
      fixedJobRate: fixedJobRate ?? this.fixedJobRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryTitle: categoryTitle ?? this.categoryTitle,
    );
  }

  @override
  String toString() {
    return 'ServicesModel(id: $id, title: $title, categoryId: $categoryId, categoryTitle: $categoryTitle, description: $description, perHourRate: $perHourRate, minimumHours: $minimumHours, rating: $rating, location: $location, isActive: $isActive, toolsIncluded: ${toolsIncluded.length} items, extraImages: ${extraImages.length} images, note: $note, isFixedJob: $isFixedJob, fixedJobRate: $fixedJobRate)';
  }
}
