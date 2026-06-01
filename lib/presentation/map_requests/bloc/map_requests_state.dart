import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homeease/models/customer_worker_offer_display.dart';
import 'package:homeease/models/nearby_worker_model.dart';
import 'package:homeease/models/service_request_model.dart';

enum MapRequestStatus {
  initial,
  loading,
  workersLoaded,
  loadingNearby,
  requestSending,
  waitingForOffers,
  workerOffersReceived,
  acceptingOffer,
  workerAssigned,
  trackingWorker,
  jobStarted,
  billGenerated,
  paymentProcessing,
  paymentSuccess,
  paymentError,
  completed,
  jobCompleted,
  requestCancelled,
  cancellingRequest,
  error,
}

class MapRequestsState extends Equatable {
  final MapRequestStatus status;
  final String? errorMessage;
  final List<NearbyWorkerModel> nearbyWorkers;
  final NearbyWorkerModel? selectedWorker;
  final ServiceRequestModel? activeRequest;
  final List<CustomerWorkerOfferDisplay> workerOffers;
  final LatLng? userLocation;
  final LatLng? cameraPosition;
  final double zoomLevel;
  final bool isListening;
  final Set<Marker> workerMarkers;
  final Set<Polyline> routePolylines;
  final Map<PolylineId, Polyline> polylines;
  final LatLng? activeWorkerLocation;
  final double activeWorkerHeading;
  final int recenterMapToken;
  final bool invoiceDialogShown;
  final bool isInvoiceOpening;
  final bool isPayingInvoice;
  final bool showInvoiceDialog;
  final DateTime? lastAutoShownBillGeneratedAt;
  final int invoicePresentationToken;

  const MapRequestsState({
    this.status = MapRequestStatus.initial,
    this.errorMessage,
    this.nearbyWorkers = const [],
    this.selectedWorker,
    this.activeRequest,
    this.workerOffers = const [],
    this.userLocation,
    this.cameraPosition,
    this.zoomLevel = 14.0,
    this.isListening = false,
    this.workerMarkers = const {},
    this.routePolylines = const {},
    this.polylines = const {},
    this.activeWorkerLocation,
    this.activeWorkerHeading = 0.0,
    this.recenterMapToken = 0,
    this.invoiceDialogShown = false,
    this.isInvoiceOpening = false,
    this.isPayingInvoice = false,
    this.showInvoiceDialog = false,
    this.lastAutoShownBillGeneratedAt,
    this.invoicePresentationToken = 0,
  });

  MapRequestsState copyWith({
    MapRequestStatus? status,
    String? errorMessage,
    List<NearbyWorkerModel>? nearbyWorkers,
    NearbyWorkerModel? selectedWorker,
    ServiceRequestModel? activeRequest,
    List<CustomerWorkerOfferDisplay>? workerOffers,
    LatLng? userLocation,
    LatLng? cameraPosition,
    double? zoomLevel,
    bool? isListening,
    Set<Marker>? workerMarkers,
    Set<Polyline>? routePolylines,
    Map<PolylineId, Polyline>? polylines,
    LatLng? activeWorkerLocation,
    double? activeWorkerHeading,
    int? recenterMapToken,
    bool? invoiceDialogShown,
    bool? isInvoiceOpening,
    bool? isPayingInvoice,
    bool? showInvoiceDialog,
    DateTime? lastAutoShownBillGeneratedAt,
    int? invoicePresentationToken,
    bool clearSelectedWorker = false,
    bool clearActiveRequest = false,
    bool clearWorkerOffers = false,
    bool clearShowInvoiceDialog = false,
    bool clearLastAutoShownBillGeneratedAt = false,
  }) {
    return MapRequestsState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      nearbyWorkers: nearbyWorkers ?? this.nearbyWorkers,
      selectedWorker:
          clearSelectedWorker ? null : (selectedWorker ?? this.selectedWorker),
      activeRequest:
          clearActiveRequest ? null : (activeRequest ?? this.activeRequest),
      workerOffers: clearWorkerOffers
          ? const []
          : (workerOffers ?? this.workerOffers),
      userLocation: userLocation ?? this.userLocation,
      cameraPosition: cameraPosition ?? this.cameraPosition,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      isListening: isListening ?? this.isListening,
      workerMarkers: workerMarkers ?? this.workerMarkers,
      routePolylines: routePolylines ?? this.routePolylines,
      polylines: polylines ?? this.polylines,
      activeWorkerLocation:
          activeWorkerLocation ?? this.activeWorkerLocation,
      activeWorkerHeading: activeWorkerHeading ?? this.activeWorkerHeading,
      recenterMapToken: recenterMapToken ?? this.recenterMapToken,
      invoiceDialogShown: invoiceDialogShown ?? this.invoiceDialogShown,
      isInvoiceOpening: isInvoiceOpening ?? this.isInvoiceOpening,
      isPayingInvoice: isPayingInvoice ?? this.isPayingInvoice,
      showInvoiceDialog: clearShowInvoiceDialog
          ? false
          : (showInvoiceDialog ?? this.showInvoiceDialog),
      lastAutoShownBillGeneratedAt: clearLastAutoShownBillGeneratedAt
          ? null
          : (lastAutoShownBillGeneratedAt ?? this.lastAutoShownBillGeneratedAt),
      invoicePresentationToken:
          invoicePresentationToken ?? this.invoicePresentationToken,
    );
  }

  bool get isLoading =>
      status == MapRequestStatus.loading ||
      status == MapRequestStatus.loadingNearby ||
      status == MapRequestStatus.requestSending ||
      status == MapRequestStatus.acceptingOffer ||
      status == MapRequestStatus.cancellingRequest;

  bool get isCompletedPaid =>
      activeRequest != null &&
      activeRequest!.status == RequestStatus.completed &&
      activeRequest!.paymentStatus == PaymentStatus.paid;

  /// In-progress jobs block a new request; completed paid jobs do not.
  bool get hasActiveRequest =>
      activeRequest != null && !isCompletedPaid;

  bool get isWaitingForOffers =>
      status == MapRequestStatus.waitingForOffers ||
      (activeRequest?.status == RequestStatus.pending &&
          workerOffers.isEmpty);

  bool get hasWorkerOffers =>
      workerOffers.isNotEmpty &&
      activeRequest?.status == RequestStatus.pending;

  bool get isTrackingWorker =>
      status == MapRequestStatus.trackingWorker ||
      status == MapRequestStatus.jobStarted;

  bool get hasPendingInvoice => activeRequest?.canCustomerConfirmPayment ?? false;

  bool get showCompleted =>
      activeRequest != null &&
      activeRequest!.status == RequestStatus.completed &&
      activeRequest!.paymentStatus == PaymentStatus.paid &&
      (status == MapRequestStatus.completed ||
          status == MapRequestStatus.paymentSuccess);

  bool get showCancelled =>
      status == MapRequestStatus.requestCancelled;

  bool get canCancelInstantRequest =>
      activeRequest?.status == RequestStatus.pending;

  bool get canSubmitPayment => hasPendingInvoice;

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        nearbyWorkers,
        selectedWorker,
        activeRequest,
        workerOffers,
        userLocation,
        cameraPosition,
        zoomLevel,
        isListening,
        workerMarkers,
        routePolylines,
        polylines,
        activeWorkerLocation,
        activeWorkerHeading,
        recenterMapToken,
        invoiceDialogShown,
        isInvoiceOpening,
        isPayingInvoice,
        showInvoiceDialog,
        lastAutoShownBillGeneratedAt,
        invoicePresentationToken,
      ];
}
