import 'package:homeease/models/request_worker_offer_model.dart';

/// Offer row enriched with worker profile for the customer offers list.
class CustomerWorkerOfferDisplay {
  final RequestWorkerOfferModel offer;
  final String workerName;
  final String? profileImage;
  final double? rating;
  final String? phoneNumber;

  const CustomerWorkerOfferDisplay({
    required this.offer,
    required this.workerName,
    this.profileImage,
    this.rating,
    this.phoneNumber,
  });

  bool get canAccept => offer.isActionable;
}
