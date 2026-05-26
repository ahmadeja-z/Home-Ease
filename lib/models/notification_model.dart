class NotificationModel {
  final String? id;
  final String? userId;
  final String? title;
  final String? body;
  final String? type;
  final bool isRead;
  final DateTime? createdAt;

  NotificationModel({
    this.id,
    this.userId,
    this.title,
    this.body,
    this.type,
    this.isRead = false,
    this.createdAt,
  });

  /// 🔹 From JSON (Supabase → Flutter)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      type: json['type'] as String?,
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  /// 🔹 To JSON (Flutter → Supabase)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// 🔹 CopyWith (very useful for Bloc/GetX)
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
