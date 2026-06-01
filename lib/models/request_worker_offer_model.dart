import 'package:homeease/models/service_request_model.dart';

enum OfferStatus {
  sent,
  accepted,
  acceptedByWorker,
  counterOffer,
  customerAccepted,
  rejected,
  expired,
  customerCancelled,
}

enum OfferType {
  basePrice,
  counter,
  unknown,
}

class RequestWorkerOfferModel {
  final String id;
  final String requestId;
  final String workerId;
  final OfferStatus status;
  final double? offeredPrice;
  final String? workerMessage;
  final OfferType offerType;
  final DateTime offeredAt;
  final DateTime? respondedAt;
  final DateTime createdAt;
  final ServiceRequestModel? request;

  const RequestWorkerOfferModel({
    required this.id,
    required this.requestId,
    required this.workerId,
    required this.status,
    this.offeredPrice,
    this.workerMessage,
    this.offerType = OfferType.unknown,
    required this.offeredAt,
    this.respondedAt,
    required this.createdAt,
    this.request,
  });

  factory RequestWorkerOfferModel.fromJson(Map<String, dynamic> json) {
    return RequestWorkerOfferModel(
      id: json['id'] as String,
      requestId: json['request_id'] as String,
      workerId: json['worker_id'] as String,
      status: _parseStatus(json['status'] as String?),
      offeredPrice: (json['offered_price'] as num?)?.toDouble(),
      workerMessage: json['worker_message'] as String?,
      offerType: _parseOfferType(json['offer_type'] as String?),
      offeredAt: DateTime.parse(json['offered_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.tryParse(json['responded_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      request: json['service_requests'] != null
          ? ServiceRequestModel.fromJson(
              json['service_requests'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  bool get isActionable =>
      status == OfferStatus.acceptedByWorker ||
      status == OfferStatus.counterOffer;

  bool get isPendingCustomerResponse =>
      status == OfferStatus.acceptedByWorker ||
      status == OfferStatus.counterOffer;

  bool get isTerminal =>
      status == OfferStatus.rejected ||
      status == OfferStatus.expired ||
      status == OfferStatus.customerAccepted ||
      status == OfferStatus.customerCancelled;

  static OfferType _parseOfferType(String? value) {
    switch (value) {
      case 'base_price':
        return OfferType.basePrice;
      case 'counter':
        return OfferType.counter;
      default:
        return OfferType.unknown;
    }
  }

  static OfferStatus _parseStatus(String? value) {
    switch (value) {
      case 'accepted':
        return OfferStatus.accepted;
      case 'accepted_by_worker':
        return OfferStatus.acceptedByWorker;
      case 'counter_offer':
        return OfferStatus.counterOffer;
      case 'customer_accepted':
        return OfferStatus.customerAccepted;
      case 'rejected':
        return OfferStatus.rejected;
      case 'expired':
        return OfferStatus.expired;
      case 'customer_cancelled':
        return OfferStatus.customerCancelled;
      case 'sent':
      default:
        return OfferStatus.sent;
    }
  }

  String get statusValue {
    switch (status) {
      case OfferStatus.accepted:
        return 'accepted';
      case OfferStatus.acceptedByWorker:
        return 'accepted_by_worker';
      case OfferStatus.counterOffer:
        return 'counter_offer';
      case OfferStatus.customerAccepted:
        return 'customer_accepted';
      case OfferStatus.rejected:
        return 'rejected';
      case OfferStatus.expired:
        return 'expired';
      case OfferStatus.customerCancelled:
        return 'customer_cancelled';
      case OfferStatus.sent:
        return 'sent';
    }
  }
}
