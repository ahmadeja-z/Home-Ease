import 'package:google_maps_flutter/google_maps_flutter.dart';

enum RequestStatus {
  pending,
  pendingAdminApproval,
  approved,
  assigned,
  accepted,
  workerOnTheWay,
  arrived,
  inProgress,
  workSubmitted,
  billGenerated,
  paid,
  completed,
  cancelled,
  rejected,
  overdue,
  workerNoShow,
  reassigned,
}

enum RequestType {
  instant,
  scheduled,
}

enum RequestFlow {
  directWorker,
  adminAssign,
}

enum PaymentStatus {
  unpaid,
  paid,
  refunded,
}

enum CommissionStatus {
  none,
  pending,
  settled,
}

enum PaymentMethod {
  cash,
  card,
  wallet,
}

enum PricingType {
  hourly,
  fixed,
  unknown,
}

class ServiceRequestModel {
  final String id;
  final String customerId;
  final String? workerId;

  final String? categoryId;
  final String? categoryName;
  final int? serviceId;
  final String? serviceTitle;
  final String? serviceMainImage;
  final List<String> customerRequestImages;

  final RequestStatus status;
  final RequestType bookingType;
  final RequestFlow requestFlow;

  final LatLng? customerLocation;
  final LatLng? workerLocation;

  final String? customerAddress;
  final String? description;

  final double? estimatedPrice;
  final PricingType pricingType;
  final double? basePrice;
  final double? acceptedPrice;
  final double? totalHours;
  final double laborCharges;
  final double materialCharges;
  final double platformFee;
  final double finalAmount;
  final String? workerCompletionNote;
  final List<String> completionImages;
  final DateTime? billGeneratedAt;

  final DateTime? scheduledTime;
  final DateTime? preferredDate;
  final String? preferredTime;

  final DateTime? acceptedAt;
  final DateTime? arrivedAt;
  final DateTime? startedAt;

  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  final String? review;
  final double? rating;
  final String? cancellationReason;

  final PaymentStatus paymentStatus;
  final PaymentMethod? paymentMethod;
  final double? customerPaidAmount;
  final DateTime? customerPaidAt;
  final double? commissionPercentage;
  final double? commissionBaseAmount;
  final double? platformCommission;
  final double? workerEarning;
  final CommissionStatus commissionStatus;

  final WorkerInfo? workerInfo;

  ServiceRequestModel({
    required this.id,
    required this.customerId,
    this.workerId,
    this.categoryId,
    this.categoryName,
    this.serviceId,
    this.serviceTitle,
    this.serviceMainImage,
    this.customerRequestImages = const [],
    this.status = RequestStatus.pending,
    this.bookingType = RequestType.instant,
    this.requestFlow = RequestFlow.directWorker,
    this.customerLocation,
    this.workerLocation,
    this.customerAddress,
    this.description,
    this.estimatedPrice,
    this.pricingType = PricingType.unknown,
    this.basePrice,
    this.acceptedPrice,
    this.totalHours,
    this.laborCharges = 0,
    this.materialCharges = 0,
    this.platformFee = 0,
    this.finalAmount = 0,
    this.workerCompletionNote,
    this.completionImages = const [],
    this.billGeneratedAt,
    this.scheduledTime,
    this.preferredDate,
    this.preferredTime,
    this.acceptedAt,
    this.arrivedAt,
    this.startedAt,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.review,
    this.rating,
    this.cancellationReason,
    this.paymentStatus = PaymentStatus.unpaid,
    this.paymentMethod,
    this.customerPaidAmount,
    this.customerPaidAt,
    this.commissionPercentage,
    this.commissionBaseAmount,
    this.platformCommission,
    this.workerEarning,
    this.commissionStatus = CommissionStatus.none,
    this.workerInfo,
  });

  /// Bill issued and awaiting customer payment.
  bool get hasPendingInvoice =>
      status == RequestStatus.billGenerated &&
      paymentStatus == PaymentStatus.unpaid;

  /// Customer may confirm direct payment to worker (outside app gateway).
  bool get canCustomerConfirmPayment =>
      hasPendingInvoice && finalAmount > 0;

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      workerId: json['worker_id'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      serviceId: (json['service_id'] as num?)?.toInt(),
      serviceTitle: json['service_title'] as String?,
      serviceMainImage: json['service_main_image'] as String?,
      customerRequestImages:
          _parseCompletionImages(json['customer_request_images']),
      status: _parseStatus(json['status'] as String?),
      bookingType: _parseType(
        json['booking_type'] as String? ?? json['type'] as String?,
      ),
      requestFlow: _parseRequestFlow(json['request_flow'] as String?),
      customerLocation:
          json['customer_latitude'] != null && json['customer_longitude'] != null
              ? LatLng(
                  (json['customer_latitude'] as num).toDouble(),
                  (json['customer_longitude'] as num).toDouble(),
                )
              : null,
      workerLocation:
          json['worker_latitude'] != null && json['worker_longitude'] != null
              ? LatLng(
                  (json['worker_latitude'] as num).toDouble(),
                  (json['worker_longitude'] as num).toDouble(),
                )
              : null,
      customerAddress: json['customer_address'] as String?,
      description: json['description'] as String?,
      estimatedPrice: (json['estimated_price'] as num?)?.toDouble(),
      pricingType: _parsePricingType(json['pricing_type'] as String?),
      basePrice: (json['base_price'] as num?)?.toDouble(),
      acceptedPrice: (json['accepted_price'] as num?)?.toDouble(),
      totalHours: (json['total_hours'] as num?)?.toDouble(),
      laborCharges: (json['labor_charges'] as num?)?.toDouble() ?? 0,
      materialCharges: (json['material_charges'] as num?)?.toDouble() ?? 0,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0,
      finalAmount: (json['final_amount'] as num?)?.toDouble() ?? 0,
      workerCompletionNote: json['worker_completion_note'] as String?,
      completionImages: _parseCompletionImages(json['completion_images']),
      billGeneratedAt: _parseDateTime(json['bill_generated_at']),
      scheduledTime: _parseDateTime(json['scheduled_time']),
      preferredDate: _parseDateTime(json['preferred_date']),
      preferredTime: json['preferred_time'] as String?,
      acceptedAt: _parseDateTime(json['accepted_at']),
      arrivedAt: _parseDateTime(json['arrived_at']),
      startedAt: _parseDateTime(json['started_at']),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updated_at']),
      completedAt: _parseDateTime(json['completed_at']),
      review: json['review'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      cancellationReason: json['cancellation_reason'] as String?,
      paymentStatus: _parsePaymentStatus(json['payment_status'] as String?),
      paymentMethod: _parsePaymentMethod(json['payment_method'] as String?),
      customerPaidAmount: (json['customer_paid_amount'] as num?)?.toDouble(),
      customerPaidAt: _parseDateTime(json['customer_paid_at']),
      commissionPercentage:
          (json['commission_percentage'] as num?)?.toDouble(),
      commissionBaseAmount:
          (json['commission_base_amount'] as num?)?.toDouble(),
      platformCommission: (json['platform_commission'] as num?)?.toDouble(),
      workerEarning: (json['worker_earning'] as num?)?.toDouble(),
      commissionStatus:
          _parseCommissionStatus(json['commission_status'] as String?),
      workerInfo: json['worker_info'] != null
          ? WorkerInfo.fromJson(json['worker_info'] as Map<String, dynamic>)
          : WorkerInfo.fromFlatJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'worker_id': workerId,
      'category_id': categoryId,
      'category_name': categoryName,
      'service_id': serviceId,
      'service_title': serviceTitle,
      'service_main_image': serviceMainImage,
      'customer_request_images': customerRequestImages,
      'status': status.value,
      'booking_type': bookingType.value,
      'request_flow': requestFlow.value,
      'customer_latitude': customerLocation?.latitude,
      'customer_longitude': customerLocation?.longitude,
      'worker_latitude': workerLocation?.latitude,
      'worker_longitude': workerLocation?.longitude,
      'customer_address': customerAddress,
      'description': description,
      'estimated_price': estimatedPrice,
      'pricing_type': pricingType == PricingType.unknown ? null : pricingType.value,
      'base_price': basePrice,
      'accepted_price': acceptedPrice,
      'total_hours': totalHours,
      'labor_charges': laborCharges,
      'material_charges': materialCharges,
      'platform_fee': platformFee,
      'final_amount': finalAmount,
      'worker_completion_note': workerCompletionNote,
      'completion_images': completionImages,
      'bill_generated_at': billGeneratedAt?.toIso8601String(),
      'scheduled_time': scheduledTime?.toIso8601String(),
      'preferred_date': preferredDate?.toIso8601String().split('T').first,
      'preferred_time': preferredTime,
      'accepted_at': acceptedAt?.toIso8601String(),
      'arrived_at': arrivedAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'review': review,
      'rating': rating,
      'cancellation_reason': cancellationReason,
      'payment_status': paymentStatus.value,
      'payment_method': paymentMethod?.value,
      'customer_paid_amount': customerPaidAmount,
      'customer_paid_at': customerPaidAt?.toIso8601String(),
      'commission_percentage': commissionPercentage,
      'commission_base_amount': commissionBaseAmount,
      'platform_commission': platformCommission,
      'worker_earning': workerEarning,
      'commission_status': commissionStatus.value,
      'worker_info': workerInfo?.toJson(),
    };
  }

  ServiceRequestModel copyWith({
    String? id,
    String? customerId,
    String? workerId,
    String? categoryId,
    String? categoryName,
    int? serviceId,
    String? serviceTitle,
    String? serviceMainImage,
    List<String>? customerRequestImages,
    RequestStatus? status,
    RequestType? bookingType,
    RequestFlow? requestFlow,
    LatLng? customerLocation,
    LatLng? workerLocation,
    String? customerAddress,
    String? description,
    double? estimatedPrice,
    PricingType? pricingType,
    double? basePrice,
    double? acceptedPrice,
    double? totalHours,
    double? laborCharges,
    double? materialCharges,
    double? platformFee,
    double? finalAmount,
    String? workerCompletionNote,
    List<String>? completionImages,
    DateTime? billGeneratedAt,
    DateTime? scheduledTime,
    DateTime? preferredDate,
    String? preferredTime,
    DateTime? acceptedAt,
    DateTime? arrivedAt,
    DateTime? startedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? review,
    double? rating,
    String? cancellationReason,
    PaymentStatus? paymentStatus,
    PaymentMethod? paymentMethod,
    double? customerPaidAmount,
    DateTime? customerPaidAt,
    double? commissionPercentage,
    double? commissionBaseAmount,
    double? platformCommission,
    double? workerEarning,
    CommissionStatus? commissionStatus,
    WorkerInfo? workerInfo,
  }) {
    return ServiceRequestModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      workerId: workerId ?? this.workerId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      serviceId: serviceId ?? this.serviceId,
      serviceTitle: serviceTitle ?? this.serviceTitle,
      serviceMainImage: serviceMainImage ?? this.serviceMainImage,
      customerRequestImages:
          customerRequestImages ?? this.customerRequestImages,
      status: status ?? this.status,
      bookingType: bookingType ?? this.bookingType,
      requestFlow: requestFlow ?? this.requestFlow,
      customerLocation: customerLocation ?? this.customerLocation,
      workerLocation: workerLocation ?? this.workerLocation,
      customerAddress: customerAddress ?? this.customerAddress,
      description: description ?? this.description,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      pricingType: pricingType ?? this.pricingType,
      basePrice: basePrice ?? this.basePrice,
      acceptedPrice: acceptedPrice ?? this.acceptedPrice,
      totalHours: totalHours ?? this.totalHours,
      laborCharges: laborCharges ?? this.laborCharges,
      materialCharges: materialCharges ?? this.materialCharges,
      platformFee: platformFee ?? this.platformFee,
      finalAmount: finalAmount ?? this.finalAmount,
      workerCompletionNote: workerCompletionNote ?? this.workerCompletionNote,
      completionImages: completionImages ?? this.completionImages,
      billGeneratedAt: billGeneratedAt ?? this.billGeneratedAt,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTime: preferredTime ?? this.preferredTime,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      startedAt: startedAt ?? this.startedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      review: review ?? this.review,
      rating: rating ?? this.rating,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      customerPaidAmount: customerPaidAmount ?? this.customerPaidAmount,
      customerPaidAt: customerPaidAt ?? this.customerPaidAt,
      commissionPercentage: commissionPercentage ?? this.commissionPercentage,
      commissionBaseAmount: commissionBaseAmount ?? this.commissionBaseAmount,
      platformCommission: platformCommission ?? this.platformCommission,
      workerEarning: workerEarning ?? this.workerEarning,
      commissionStatus: commissionStatus ?? this.commissionStatus,
      workerInfo: workerInfo ?? this.workerInfo,
    );
  }

  String getStatusString() {
    switch (status) {
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.pendingAdminApproval:
        return 'Pending admin approval';
      case RequestStatus.approved:
        return 'Approved';
      case RequestStatus.assigned:
        return 'Assigned';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.workerOnTheWay:
        return 'On the way';
      case RequestStatus.arrived:
        return 'Arrived';
      case RequestStatus.inProgress:
        return 'In Progress';
      case RequestStatus.workSubmitted:
        return 'Work Submitted';
      case RequestStatus.billGenerated:
        return 'Bill Generated';
      case RequestStatus.paid:
        return 'Paid';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.cancelled:
        return 'Cancelled';
      case RequestStatus.rejected:
        return 'Rejected';
      case RequestStatus.overdue:
        return 'Overdue';
      case RequestStatus.workerNoShow:
        return 'Worker no-show';
      case RequestStatus.reassigned:
        return 'Reassigned';
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static RequestStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return RequestStatus.pending;
      case 'pending_admin_approval':
        return RequestStatus.pendingAdminApproval;
      case 'approved':
        return RequestStatus.approved;
      case 'assigned':
        return RequestStatus.assigned;
      case 'accepted':
      case 'worker_accepted':
        return RequestStatus.accepted;
      case 'worker_on_the_way':
        return RequestStatus.workerOnTheWay;
      case 'arrived':
      case 'worker_arrived':
        return RequestStatus.arrived;
      case 'in_progress':
      case 'job_started':
        return RequestStatus.inProgress;
      case 'work_submitted':
        return RequestStatus.workSubmitted;
      case 'bill_generated':
        return RequestStatus.billGenerated;
      case 'paid':
        return RequestStatus.paid;
      case 'completed':
        return RequestStatus.completed;
      case 'cancelled':
        return RequestStatus.cancelled;
      case 'rejected':
        return RequestStatus.rejected;
      case 'overdue':
        return RequestStatus.overdue;
      case 'worker_no_show':
        return RequestStatus.workerNoShow;
      case 'reassigned':
        return RequestStatus.reassigned;
      default:
        return RequestStatus.pending;
    }
  }

  static RequestType _parseType(String? type) {
    switch (type?.toLowerCase()) {
      case 'scheduled':
        return RequestType.scheduled;
      case 'immediate':
      case 'instant':
        return RequestType.instant;
      default:
        return RequestType.instant;
    }
  }

  static RequestFlow _parseRequestFlow(String? value) {
    switch (value?.toLowerCase()) {
      case 'admin_assign':
        return RequestFlow.adminAssign;
      case 'direct_worker':
      default:
        return RequestFlow.directWorker;
    }
  }

  static PaymentStatus _parsePaymentStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'paid':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'unpaid':
      default:
        return PaymentStatus.unpaid;
    }
  }

  static CommissionStatus _parseCommissionStatus(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return CommissionStatus.pending;
      case 'settled':
        return CommissionStatus.settled;
      case 'none':
      default:
        return CommissionStatus.none;
    }
  }

  static List<String> _parseCompletionImages(dynamic value) {
    if (value == null) return const [];
    if (value is List) {
      return value.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    return const [];
  }

  static PricingType _parsePricingType(String? value) {
    switch (value?.toLowerCase()) {
      case 'hourly':
        return PricingType.hourly;
      case 'fixed':
        return PricingType.fixed;
      default:
        return PricingType.unknown;
    }
  }

  static PaymentMethod? _parsePaymentMethod(String? value) {
    switch (value?.toLowerCase()) {
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      case 'wallet':
        return PaymentMethod.wallet;
      default:
        return null;
    }
  }
}

extension RequestStatusX on RequestStatus {
  String get value {
    switch (this) {
      case RequestStatus.pendingAdminApproval:
        return 'pending_admin_approval';
      case RequestStatus.workerOnTheWay:
        return 'worker_on_the_way';
      case RequestStatus.inProgress:
        return 'in_progress';
      case RequestStatus.workSubmitted:
        return 'work_submitted';
      case RequestStatus.billGenerated:
        return 'bill_generated';
      case RequestStatus.workerNoShow:
        return 'worker_no_show';
      default:
        return name;
    }
  }
}

extension RequestTypeX on RequestType {
  String get value {
    switch (this) {
      case RequestType.instant:
        return 'instant';
      case RequestType.scheduled:
        return 'scheduled';
    }
  }
}

extension RequestFlowX on RequestFlow {
  String get value {
    switch (this) {
      case RequestFlow.directWorker:
        return 'direct_worker';
      case RequestFlow.adminAssign:
        return 'admin_assign';
    }
  }
}

extension PaymentStatusX on PaymentStatus {
  String get value => name;

  String get displayLabel {
    switch (this) {
      case PaymentStatus.paid:
        return 'Paid';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.unpaid:
        return 'Unpaid';
    }
  }
}

extension CommissionStatusX on CommissionStatus {
  String get value => name;
}

extension PaymentMethodX on PaymentMethod {
  String get value => name;
}

extension PricingTypeX on PricingType {
  String get value {
    switch (this) {
      case PricingType.hourly:
        return 'hourly';
      case PricingType.fixed:
        return 'fixed';
      case PricingType.unknown:
        return 'unknown';
    }
  }
}

class WorkerInfo {
  final String id;
  final String name;
  final String? profileImage;
  final double? rating;
  final String? phoneNumber;
  final LatLng? location;

  WorkerInfo({
    required this.id,
    required this.name,
    this.profileImage,
    this.rating,
    this.phoneNumber,
    this.location,
  });

  factory WorkerInfo.fromJson(Map<String, dynamic> json) {
    return WorkerInfo(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      profileImage: json['profile_picture'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      phoneNumber: json['phone_number'] as String?,
      location: json['latitude'] != null && json['longitude'] != null
          ? LatLng(
              (json['latitude'] as num).toDouble(),
              (json['longitude'] as num).toDouble(),
            )
          : null,
    );
  }

  static WorkerInfo? fromFlatJson(Map<String, dynamic> json) {
    final workerId = json['worker_id'] as String?;
    if (workerId == null) return null;

    return WorkerInfo(
      id: workerId,
      name: json['worker_name'] as String? ?? '',
      profileImage: json['worker_profile_picture'] as String?,
      rating: (json['worker_rating'] as num?)?.toDouble(),
      phoneNumber: json['worker_phone'] as String?,
      location: json['worker_latitude'] != null && json['worker_longitude'] != null
          ? LatLng(
              (json['worker_latitude'] as num).toDouble(),
              (json['worker_longitude'] as num).toDouble(),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profile_picture': profileImage,
      'rating': rating,
      'phone_number': phoneNumber,
      'latitude': location?.latitude,
      'longitude': location?.longitude,
    };
  }
}
