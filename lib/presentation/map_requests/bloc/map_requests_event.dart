import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homeease/models/customer_worker_offer_display.dart';
import 'package:homeease/models/nearby_worker_model.dart';
import 'package:homeease/models/service_request_model.dart';

abstract class MapRequestsEvent extends Equatable {
  const MapRequestsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNearbyWorkersEvent extends MapRequestsEvent {
  final LatLng? userLocation;
  final double radius;

  const LoadNearbyWorkersEvent({
    this.userLocation,
    this.radius = 10.0,
  });

  @override
  List<Object?> get props => [userLocation, radius];
}

class ListenNearbyWorkersEvent extends MapRequestsEvent {
  final LatLng? userLocation;

  const ListenNearbyWorkersEvent({this.userLocation});

  @override
  List<Object?> get props => [userLocation];
}

class SelectWorkerEvent extends MapRequestsEvent {
  final NearbyWorkerModel? worker;

  const SelectWorkerEvent(this.worker);

  @override
  List<Object?> get props => [worker];
}

class CreateServiceRequestEvent extends MapRequestsEvent {
  final String categoryId;
  final String categoryName;
  final LatLng customerLocation;
  final String customerAddress;
  final String? description;
  final RequestType requestType;
  final double perHourPrice;

  const CreateServiceRequestEvent({
    required this.categoryId,
    required this.categoryName,
    required this.customerLocation,
    required this.customerAddress,
    required this.perHourPrice,
    this.description,
    this.requestType = RequestType.instant,
  });

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        customerLocation,
        customerAddress,
        description,
        requestType,
        perHourPrice,
      ];
}

class ListenWorkerOffersEvent extends MapRequestsEvent {
  final String requestId;

  const ListenWorkerOffersEvent(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class WorkerOffersUpdatedEvent extends MapRequestsEvent {
  final List<CustomerWorkerOfferDisplay> offers;

  const WorkerOffersUpdatedEvent(this.offers);

  @override
  List<Object?> get props => [offers];
}

class AcceptWorkerOfferEvent extends MapRequestsEvent {
  final String offerId;
  final String requestId;

  const AcceptWorkerOfferEvent({
    required this.offerId,
    required this.requestId,
  });

  @override
  List<Object?> get props => [offerId, requestId];
}

class PayInvoiceEvent extends MapRequestsEvent {
  final String requestId;

  const PayInvoiceEvent(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class ClearActiveRequestEvent extends MapRequestsEvent {}

/// Clears completed job UI, refreshes map workers, and allows a new request.
class ReloadMapAfterCompletionEvent extends MapRequestsEvent {}

class WorkerAcceptedRequestEvent extends MapRequestsEvent {}

class TrackWorkerLocationEvent extends MapRequestsEvent {
  final String requestId;
  final String workerId;

  const TrackWorkerLocationEvent({
    required this.requestId,
    required this.workerId,
  });

  @override
  List<Object?> get props => [requestId, workerId];
}

class StartJobTrackingEvent extends MapRequestsEvent {
  final String requestId;

  const StartJobTrackingEvent(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class CompleteJobEvent extends MapRequestsEvent {
  final String requestId;
  final String? review;
  final double? rating;

  const CompleteJobEvent({
    required this.requestId,
    this.review,
    this.rating,
  });

  @override
  List<Object?> get props => [requestId, review, rating];
}

class CancelJobEvent extends MapRequestsEvent {
  final String requestId;
  final String? reason;

  const CancelJobEvent({
    required this.requestId,
    this.reason,
  });

  @override
  List<Object?> get props => [requestId, reason];
}

class UpdateMapCameraEvent extends MapRequestsEvent {
  final LatLng target;
  final double zoom;

  const UpdateMapCameraEvent({
    required this.target,
    this.zoom = 14.0,
  });

  @override
  List<Object?> get props => [target, zoom];
}

class RefreshNearbyWorkersEvent extends MapRequestsEvent {}

class ClearSelectedWorkerEvent extends MapRequestsEvent {}

class ListenActiveRequestEvent extends MapRequestsEvent {}

class StopListeningEvent extends MapRequestsEvent {}

class GetUserLocationEvent extends MapRequestsEvent {
  final bool recenterMap;

  const GetUserLocationEvent({this.recenterMap = false});

  @override
  List<Object?> get props => [recenterMap];
}

class StartUserLocationTrackingEvent extends MapRequestsEvent {}

class UserLocationUpdatedEvent extends MapRequestsEvent {
  final LatLng location;

  const UserLocationUpdatedEvent(this.location);

  @override
  List<Object?> get props => [location];
}

class UpdateWorkerLocationBroadcastEvent extends MapRequestsEvent {
  final LatLng location;

  const UpdateWorkerLocationBroadcastEvent(this.location);

  @override
  List<Object?> get props => [location];
}
