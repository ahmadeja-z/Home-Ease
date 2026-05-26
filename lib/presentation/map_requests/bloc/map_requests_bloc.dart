import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:homeease/core/services/permission_service.dart';
import 'package:homeease/models/customer_worker_offer_display.dart';
import 'package:homeease/models/nearby_worker_model.dart';
import 'package:homeease/models/request_worker_offer_model.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_event.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_state.dart';
import 'package:homeease/repositories/map_requests_repository.dart';

class MapRequestsBloc
    extends Bloc<MapRequestsEvent, MapRequestsState> {
  final MapRequestsRepository repository;

  StreamSubscription<void>? _workersSubscription;
  StreamSubscription<ServiceRequestModel?>? _requestSubscription;
  StreamSubscription<ServiceRequestModel?>? _activeRequestSubscription;
  StreamSubscription<List<RequestWorkerOfferModel>>? _offersSubscription;
  StreamSubscription<LatLng>? _broadcastSubscription;
  StreamSubscription<Position>? _userLocationSubscription;
  String? _currentBroadcastRequestId;
  String? _listeningOffersRequestId;
  String? _dismissedCompletedRequestId;

  MapRequestsBloc({required this.repository})
      : super(const MapRequestsState()) {
    on<LoadNearbyWorkersEvent>(_onLoadNearbyWorkers);
    on<ListenNearbyWorkersEvent>(_onListenNearbyWorkers);
    on<SelectWorkerEvent>(_onSelectWorker);
    on<CreateServiceRequestEvent>(_onCreateServiceRequest);
    on<ListenWorkerOffersEvent>(_onListenWorkerOffers);
    on<WorkerOffersUpdatedEvent>(_onWorkerOffersUpdated);
    on<AcceptWorkerOfferEvent>(_onAcceptWorkerOffer);
    on<PayInvoiceEvent>(_onPayInvoice);
    on<ClearActiveRequestEvent>(_onClearActiveRequest);
    on<ReloadMapAfterCompletionEvent>(_onReloadAfterCompletion);
    on<WorkerAcceptedRequestEvent>(_onWorkerAcceptedRequest);
    on<TrackWorkerLocationEvent>(_onTrackWorkerLocation);
    on<StartJobTrackingEvent>(_onStartJobTracking);
    on<CompleteJobEvent>(_onCompleteJob);
    on<CancelJobEvent>(_onCancelJob);
    on<UpdateMapCameraEvent>(_onUpdateMapCamera);
    on<RefreshNearbyWorkersEvent>(_onRefreshNearbyWorkers);
    on<ClearSelectedWorkerEvent>(_onClearSelectedWorker);
    on<ListenActiveRequestEvent>(_onListenActiveRequest);
    on<StopListeningEvent>(_onStopListening);
    on<GetUserLocationEvent>(_onGetUserLocation);
    on<StartUserLocationTrackingEvent>(_onStartUserLocationTracking);
    on<UserLocationUpdatedEvent>(_onUserLocationUpdated);
    on<UpdateWorkerLocationBroadcastEvent>(_onUpdateWorkerLocationBroadcast);
  }

  Future<void> _onLoadNearbyWorkers(
    LoadNearbyWorkersEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    emit(state.copyWith(
      status: MapRequestStatus.loadingNearby,
      errorMessage: null,
    ));

    try {
      LatLng location = event.userLocation ??
          (state.userLocation ??
              const LatLng(37.7749, -122.4194));

      final workers = await repository.fetchNearbyWorkers(
        userLocation: location,
        radius: event.radius,
      );

      if (kDebugMode) {
        print(
          'MapRequestsBloc - LoadNearbyWorkersEvent: ${workers.length} workers on map',
        );
        for (final w in workers) {
          print(
            '  marker: ${w.name} (${w.id}) | '
            '${w.categoryName ?? "no category"} | '
            '${w.distance.toStringAsFixed(1)} km',
          );
        }
      }

      final markers = _buildWorkerMarkers(
        workers: workers,
        activeRequest: state.activeRequest,
        activeWorkerLocation: state.activeWorkerLocation,
        activeWorkerHeading: state.activeWorkerHeading,
      );

      emit(state.copyWith(
        status: MapRequestStatus.workersLoaded,
        nearbyWorkers: workers,
        workerMarkers: markers,
        userLocation: location,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('MapRequestsBloc - LoadNearbyWorkersEvent failed: $e');
      }
      emit(state.copyWith(
        status: MapRequestStatus.workersLoaded,
        nearbyWorkers: [],
        workerMarkers: {},
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onListenNearbyWorkers(
    ListenNearbyWorkersEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    try {
      await _workersSubscription?.cancel();

      LatLng location = event.userLocation ??
          (state.userLocation ??
              const LatLng(37.7749, -122.4194));

      _workersSubscription = repository.listenNearbyWorkers().listen(
            (_) {
              add(LoadNearbyWorkersEvent(userLocation: location));
            },
            onError: (error) {
              emit(state.copyWith(
                status: MapRequestStatus.error,
                errorMessage: error.toString(),
              ));
            },
          );

      emit(state.copyWith(isListening: true));
    } catch (e) {
      emit(state.copyWith(
        status: MapRequestStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSelectWorker(
    SelectWorkerEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    emit(state.copyWith(selectedWorker: event.worker));
  }

  Future<void> _onCreateServiceRequest(
    CreateServiceRequestEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    emit(state.copyWith(
      status: MapRequestStatus.requestSending,
      errorMessage: null,
    ));

    try {
      final location = event.customerLocation;
      final matchedWorkers = await repository.fetchNearbyWorkersByCategory(
        userLocation: location,
        categoryId: event.categoryId,
      );

      if (kDebugMode) {
        print(
          'MapRequestsBloc - CreateServiceRequestEvent category: '
          '${event.categoryName} (${event.categoryId})',
        );
        print('  offer targets: ${matchedWorkers.length} workers');
      }

      if (matchedWorkers.isEmpty) {
        emit(state.copyWith(
          status: MapRequestStatus.error,
          errorMessage:
              'No online workers for this service category nearby.',
        ));
        return;
      }

      final workerIds = matchedWorkers.map((w) => w.id).toList();

      if (kDebugMode) {
        print(
          'MapRequestsBloc - customer base price entered: '
          '${event.perHourPrice}/hr',
        );
      }

      final request = await repository.createInstantRequestWithOffers(
        categoryId: event.categoryId,
        categoryName: event.categoryName,
        customerLocation: event.customerLocation,
        customerAddress: event.customerAddress,
        description: event.description,
        matchedWorkerIds: workerIds,
        perHourPrice: event.perHourPrice,
      );

      if (kDebugMode) {
        print('MapRequestsBloc - request created: ${request.id}');
        print('  worker offers created for ${workerIds.length} workers');
      }

      emit(state.copyWith(
        status: MapRequestStatus.waitingForOffers,
        activeRequest: request,
        clearWorkerOffers: true,
        errorMessage: null,
      ));

      add(ListenWorkerOffersEvent(request.id));
      add(ListenActiveRequestEvent());
    } catch (e) {
      emit(state.copyWith(
        status: MapRequestStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onListenWorkerOffers(
    ListenWorkerOffersEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    if (_listeningOffersRequestId == event.requestId &&
        _offersSubscription != null) {
      return;
    }
    _listeningOffersRequestId = event.requestId;

    await _offersSubscription?.cancel();

    _offersSubscription =
        repository.subscribeToWorkerOfferUpdates(event.requestId).listen(
      (offers) async {
        final displays = await _enrichOffers(offers);
        add(WorkerOffersUpdatedEvent(displays));
      },
      onError: (Object error) {
        if (kDebugMode) {
          print('MapRequestsBloc - worker offers stream error: $error');
        }
      },
    );
  }

  void _onWorkerOffersUpdated(
    WorkerOffersUpdatedEvent event,
    Emitter<MapRequestsState> emit,
  ) {
    final newStatus = event.offers.isNotEmpty
        ? MapRequestStatus.workerOffersReceived
        : MapRequestStatus.waitingForOffers;

    emit(state.copyWith(
      workerOffers: event.offers,
      status: state.activeRequest?.status == RequestStatus.pending
          ? newStatus
          : state.status,
    ));
  }

  Future<List<CustomerWorkerOfferDisplay>> _enrichOffers(
    List<RequestWorkerOfferModel> offers,
  ) async {
    final displays = <CustomerWorkerOfferDisplay>[];

    for (final offer in offers) {
      final nearbyMatches =
          state.nearbyWorkers.where((w) => w.id == offer.workerId);
      final nearby =
          nearbyMatches.isNotEmpty ? nearbyMatches.first : null;

      if (nearby != null) {
        displays.add(
          CustomerWorkerOfferDisplay(
            offer: offer,
            workerName: nearby.name,
            profileImage: nearby.profileImage,
            rating: nearby.rating,
          ),
        );
        continue;
      }

      try {
        final profile =
            await repository.getWorkerProfileById(offer.workerId);
        displays.add(
          CustomerWorkerOfferDisplay(
            offer: offer,
            workerName: profile?.name ?? 'Worker',
            profileImage: profile?.profilePicture,
            rating: profile?.rating,
            phoneNumber: profile?.phoneNumber,
          ),
        );
      } catch (_) {
        displays.add(
          CustomerWorkerOfferDisplay(
            offer: offer,
            workerName: 'Worker',
          ),
        );
      }
    }

    return displays;
  }

  Future<void> _onAcceptWorkerOffer(
    AcceptWorkerOfferEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    emit(state.copyWith(
      status: MapRequestStatus.acceptingOffer,
      errorMessage: null,
    ));

    try {
      final request = await repository.acceptWorkerOffer(
        offerId: event.offerId,
        requestId: event.requestId,
      );

      if (kDebugMode) {
        print('MapRequestsBloc - customer accepted offer: ${event.offerId}');
      }

      await _offersSubscription?.cancel();
      _listeningOffersRequestId = null;

      emit(state.copyWith(
        status: MapRequestStatus.workerAssigned,
        activeRequest: request,
        clearWorkerOffers: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: state.workerOffers.isNotEmpty
            ? MapRequestStatus.workerOffersReceived
            : MapRequestStatus.waitingForOffers,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onClearActiveRequest(
    ClearActiveRequestEvent event,
    Emitter<MapRequestsState> emit,
  ) {
    _resetAfterCompletion(emit);
  }

  Future<void> _onReloadAfterCompletion(
    ReloadMapAfterCompletionEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    if (kDebugMode) {
      print('MapRequestsBloc - reload after completion');
    }
    final location = state.userLocation;
    _resetAfterCompletion(emit);
    add(RefreshNearbyWorkersEvent());
    if (location != null) {
      add(LoadNearbyWorkersEvent(userLocation: location));
    }
  }

  void _resetAfterCompletion(Emitter<MapRequestsState> emit) {
    final completedId = state.activeRequest?.id;
    if (state.isCompletedPaid && completedId != null) {
      _dismissedCompletedRequestId = completedId;
    }
    _cancelBroadcastSubscription();
    _offersSubscription?.cancel();
    _listeningOffersRequestId = null;
    emit(state.copyWith(
      status: MapRequestStatus.workersLoaded,
      clearActiveRequest: true,
      clearWorkerOffers: true,
      activeWorkerLocation: null,
      activeWorkerHeading: 0,
      workerMarkers: _buildWorkerMarkers(workers: state.nearbyWorkers),
      errorMessage: null,
    ));
  }

  Future<void> _onPayInvoice(
    PayInvoiceEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    final active = state.activeRequest;
    if (active == null || !active.canCustomerConfirmPayment) {
      if (kDebugMode) {
        print(
          'MapRequestsBloc - pay blocked: request not eligible '
          '(status=${active?.status}, payment=${active?.paymentStatus}, '
          'final=${active?.finalAmount})',
        );
      }
      return;
    }

    if (kDebugMode) {
      print('MapRequestsBloc - customer confirmed paid worker: ${event.requestId}');
    }

    emit(state.copyWith(
      status: MapRequestStatus.paymentProcessing,
      errorMessage: null,
    ));

    try {
      final request = await repository.payInvoice(event.requestId);

      if (kDebugMode) {
        print('MapRequestsBloc - payment success: ${event.requestId}');
      }

      emit(state.copyWith(
        status: MapRequestStatus.paymentSuccess,
        activeRequest: request,
      ));

      emit(state.copyWith(
        status: MapRequestStatus.completed,
        activeRequest: request,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('MapRequestsBloc - payment failed: ${event.requestId} — $e');
      }
      emit(state.copyWith(
        status: MapRequestStatus.paymentError,
        errorMessage: _paymentErrorMessage(e),
      ));
    }
  }

  String _paymentErrorMessage(Object error) {
    final message = error.toString();
    if (message.contains('invalid_request_for_payment')) {
      return 'This invoice cannot be marked as paid. Refresh and try again.';
    }
    if (message.contains('not_authenticated')) {
      return 'Please sign in again to confirm payment.';
    }
    return 'Could not confirm payment. Please try again.';
  }

  Future<void> _onWorkerAcceptedRequest(
    WorkerAcceptedRequestEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    emit(state.copyWith(status: MapRequestStatus.workerAssigned));
  }

  Future<void> _onTrackWorkerLocation(
    TrackWorkerLocationEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    emit(state.copyWith(status: MapRequestStatus.trackingWorker));

    await emit.forEach<ServiceRequestModel?>(
      repository.listenRequestUpdates(event.requestId),
      onData: (request) {
        if (request == null) return state;

        final location = request.workerInfo?.location;
        return state.copyWith(
          activeRequest: request,
          status: _getStatusFromRequest(request),
          activeWorkerLocation: location,
          workerMarkers: _buildWorkerMarkers(
            workers: state.nearbyWorkers,
            activeRequest: request,
            activeWorkerLocation: location,
            activeWorkerHeading: state.activeWorkerHeading,
          ),
        );
      },
    );
  }

  Future<void> _onStartJobTracking(
    StartJobTrackingEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    emit(state.copyWith(status: MapRequestStatus.jobStarted));
    await repository.startJob(event.requestId);
  }

  Future<void> _onCompleteJob(
    CompleteJobEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    try {
      await repository.completeJob(
        requestId: event.requestId,
        review: event.review,
        rating: event.rating,
      );

      emit(state.copyWith(
        status: MapRequestStatus.completed,
        activeRequest: state.activeRequest?.copyWith(
          review: event.review,
          rating: event.rating,
        ),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MapRequestStatus.paymentError,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCancelJob(
    CancelJobEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    try {
      await repository.cancelJob(
        requestId: event.requestId,
        reason: event.reason,
      );

      _cancelBroadcastSubscription();
      await _offersSubscription?.cancel();
      _listeningOffersRequestId = null;

      emit(state.copyWith(
        status: MapRequestStatus.jobCompleted,
        activeRequest: null,
        clearActiveRequest: true,
        clearWorkerOffers: true,
        activeWorkerLocation: null,
        activeWorkerHeading: 0,
        workerMarkers: _buildWorkerMarkers(workers: state.nearbyWorkers),
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MapRequestStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onUpdateMapCamera(
    UpdateMapCameraEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    emit(state.copyWith(
      cameraPosition: event.target,
      zoomLevel: event.zoom,
    ));
  }

  Future<void> _onRefreshNearbyWorkers(
    RefreshNearbyWorkersEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    add(LoadNearbyWorkersEvent(userLocation: state.userLocation));
  }

  Future<void> _onClearSelectedWorker(
    ClearSelectedWorkerEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    emit(state.copyWith(clearSelectedWorker: true));
  }

  Future<void> _onListenActiveRequest(
    ListenActiveRequestEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    final userId = repository.supabase.auth.currentUser?.id;
    if (userId == null) return;

    await emit.forEach<ServiceRequestModel?>(
      repository.subscribeToCustomerRequestUpdates(userId),
      onData: (request) {
        if (request == null) {
          _cancelBroadcastSubscription();
          _offersSubscription?.cancel();
          _listeningOffersRequestId = null;
          return state.copyWith(
            activeRequest: null,
            clearActiveRequest: true,
            clearWorkerOffers: true,
            activeWorkerLocation: null,
            activeWorkerHeading: 0,
            workerMarkers: _buildWorkerMarkers(workers: state.nearbyWorkers),
            status: MapRequestStatus.workersLoaded,
          );
        }

        if (request.id == _dismissedCompletedRequestId &&
            request.status == RequestStatus.completed) {
          return state.copyWith(
            activeRequest: null,
            clearActiveRequest: true,
            status: MapRequestStatus.workersLoaded,
            workerMarkers: _buildWorkerMarkers(workers: state.nearbyWorkers),
          );
        }

        if (request.status != RequestStatus.completed) {
          _dismissedCompletedRequestId = null;
        }

        if (request.status == RequestStatus.pending &&
            _listeningOffersRequestId != request.id) {
          add(ListenWorkerOffersEvent(request.id));
        }

        if (_currentBroadcastRequestId != request.id) {
          _cancelBroadcastSubscription();
          _currentBroadcastRequestId = request.id;
          _broadcastSubscription = repository
              .listenWorkerLocationBroadcast(request.id)
              .listen((location) {
            add(UpdateWorkerLocationBroadcastEvent(location));
          });
        }

        LatLng? newLocation;
        double newHeading = state.activeWorkerHeading;

        if (request.workerInfo?.location != null) {
          newLocation = request.workerInfo!.location!;

          if (state.activeWorkerLocation != null) {
            newHeading = _computeHeading(state.activeWorkerLocation!, newLocation);
          }
        }

        final preservePaymentUi = state.status == MapRequestStatus.paymentProcessing;

        return state.copyWith(
          activeRequest: request,
          status: preservePaymentUi
              ? MapRequestStatus.paymentProcessing
              : _getStatusFromRequest(request),
          workerMarkers: _buildWorkerMarkers(
            workers: state.nearbyWorkers,
            activeRequest: request,
            activeWorkerLocation: newLocation,
            activeWorkerHeading: newHeading,
          ),
          activeWorkerLocation: newLocation,
          activeWorkerHeading: newHeading,
        );
      },
      onError: (error, stackTrace) {
        if (kDebugMode) {
          print('Error in _onListenActiveRequest stream: $error');
        }
        return state.copyWith(
          activeRequest: null,
          clearActiveRequest: true,
        );
      },
    );
  }

  void _cancelBroadcastSubscription() {
    _broadcastSubscription?.cancel();
    _broadcastSubscription = null;
    _currentBroadcastRequestId = null;
  }

  Future<void> _onUpdateWorkerLocationBroadcast(
    UpdateWorkerLocationBroadcastEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    if (state.activeRequest == null || state.activeRequest?.workerInfo == null) {
      return;
    }

    final newLocation = event.location;
    double newHeading = state.activeWorkerHeading;
    
    if (state.activeWorkerLocation != null) {
      newHeading = _computeHeading(state.activeWorkerLocation!, newLocation);
    }

    emit(state.copyWith(
      workerMarkers: _buildWorkerMarkers(
        workers: state.nearbyWorkers,
        activeRequest: state.activeRequest,
        activeWorkerLocation: newLocation,
        activeWorkerHeading: newHeading,
      ),
      activeWorkerLocation: newLocation,
      activeWorkerHeading: newHeading,
    ));
  }

  Future<void> _onStopListening(
    StopListeningEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    await _workersSubscription?.cancel();
    await _requestSubscription?.cancel();
    await _activeRequestSubscription?.cancel();
    _cancelBroadcastSubscription();

    emit(state.copyWith(isListening: false));
  }
  
  Future<void> _onGetUserLocation(
    GetUserLocationEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    try {
      final position = await repository.getCurrentLocation();
      final location = LatLng(position.latitude, position.longitude);

      if (kDebugMode) {
        print(
          'MapRequestsBloc - GetUserLocationEvent: '
          '${location.latitude}, ${location.longitude}',
        );
      }

      emit(state.copyWith(
        userLocation: location,
        status: MapRequestStatus.loadingNearby,
        recenterMapToken: event.recenterMap
            ? state.recenterMapToken + 1
            : state.recenterMapToken,
      ));

      add(LoadNearbyWorkersEvent(userLocation: location));
      add(ListenNearbyWorkersEvent(userLocation: location));
    } catch (e) {
      if (kDebugMode) {
        print('MapRequestsBloc - GetUserLocationEvent failed: $e');
      }
      emit(state.copyWith(
        status: MapRequestStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onStartUserLocationTracking(
    StartUserLocationTrackingEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    await _userLocationSubscription?.cancel();

    final granted = await PermissionService.requestLocationPermission();
    if (!granted) {
      emit(state.copyWith(
        errorMessage:
            'Location permission is required to show your live position.',
      ));
      return;
    }

    _userLocationSubscription = repository.watchUserLocation().listen(
      (position) {
        add(
          UserLocationUpdatedEvent(
            LatLng(position.latitude, position.longitude),
          ),
        );
      },
      onError: (Object error) {
        if (kDebugMode) {
          print('MapRequestsBloc - watchUserLocation error: $error');
        }
      },
    );
  }

  Future<void> _onUserLocationUpdated(
    UserLocationUpdatedEvent event,
    Emitter<MapRequestsState> emit,
  ) async {
    final previous = state.userLocation;
    final location = event.location;

    if (previous != null &&
        (previous.latitude - location.latitude).abs() < 0.00001 &&
        (previous.longitude - location.longitude).abs() < 0.00001) {
      return;
    }

    if (kDebugMode && previous == null) {
      print(
        'MapRequestsBloc - live location started: '
        '${location.latitude}, ${location.longitude}',
      );
    }

    emit(state.copyWith(userLocation: location));
  }

  /// All online nearby workers (green) + assigned worker during active job (blue, rotated).
  Set<Marker> _buildWorkerMarkers({
    required List<NearbyWorkerModel> workers,
    ServiceRequestModel? activeRequest,
    LatLng? activeWorkerLocation,
    double activeWorkerHeading = 0,
  }) {
    final assignedId = activeRequest?.workerInfo?.id;
    final markers = <Marker>{};

    for (final worker in workers) {
      final isAssigned = worker.id == assignedId;
      final position = isAssigned && activeWorkerLocation != null
          ? activeWorkerLocation
          : worker.location;

      markers.add(
        Marker(
          markerId: MarkerId(worker.id),
          position: position,
          rotation: isAssigned ? activeWorkerHeading : 0,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isAssigned
                ? BitmapDescriptor.hueAzure
                : BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: worker.name,
            snippet: _workerMarkerSnippet(worker, isAssigned: isAssigned),
          ),
        ),
      );
    }

    // Assigned worker not in nearby list (e.g. moved out of radius) — still show pin
    if (assignedId != null &&
        activeWorkerLocation != null &&
        !workers.any((w) => w.id == assignedId)) {
      final info = activeRequest!.workerInfo!;
      markers.add(
        Marker(
          markerId: MarkerId(assignedId),
          position: activeWorkerLocation,
          rotation: activeWorkerHeading,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: info.name,
            snippet: 'On the way',
          ),
        ),
      );
    }

    return markers;
  }

  String _workerMarkerSnippet(NearbyWorkerModel worker, {bool isAssigned = false}) {
    if (isAssigned) return 'On the way';
    final parts = <String>[
      if (worker.categoryName != null && worker.categoryName!.isNotEmpty)
        worker.categoryName!,
      '${worker.distance.toStringAsFixed(1)} km',
      '★ ${worker.rating.toStringAsFixed(1)}',
    ];
    return parts.join(' · ');
  }


  MapRequestStatus _getStatusFromRequest(ServiceRequestModel request) {
    switch (request.status) {
      case RequestStatus.pending:
        if (state.workerOffers.isNotEmpty) {
          return MapRequestStatus.workerOffersReceived;
        }
        return MapRequestStatus.waitingForOffers;
      case RequestStatus.pendingAdminApproval:
        return MapRequestStatus.waitingForOffers;
      case RequestStatus.overdue:
      case RequestStatus.workerNoShow:
      case RequestStatus.reassigned:
        return MapRequestStatus.workerAssigned;
      case RequestStatus.accepted:
        return MapRequestStatus.workerAssigned;
      case RequestStatus.workerOnTheWay:
      case RequestStatus.arrived:
        return MapRequestStatus.trackingWorker;
      case RequestStatus.inProgress:
        return MapRequestStatus.jobStarted;
      case RequestStatus.billGenerated:
        return MapRequestStatus.billGenerated;
      case RequestStatus.completed:
        return MapRequestStatus.completed;
      case RequestStatus.cancelled:
      case RequestStatus.rejected:
        return MapRequestStatus.jobCompleted;
      case RequestStatus.approved:
      case RequestStatus.assigned:
      case RequestStatus.workSubmitted:
      case RequestStatus.paid:
        return MapRequestStatus.workerAssigned;
    }
  }

  double _computeHeading(LatLng from, LatLng to) {
    final lat1 = from.latitude * math.pi / 180.0;
    final lng1 = from.longitude * math.pi / 180.0;
    final lat2 = to.latitude * math.pi / 180.0;
    final lng2 = to.longitude * math.pi / 180.0;

    final dLng = lng2 - lng1;

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final heading = math.atan2(y, x);
    return (heading * 180.0 / math.pi + 360.0) % 360.0;
  }

  @override
  Future<void> close() {
    _workersSubscription?.cancel();
    _requestSubscription?.cancel();
    _activeRequestSubscription?.cancel();
    _offersSubscription?.cancel();
    _userLocationSubscription?.cancel();
    _cancelBroadcastSubscription();
    repository.dispose();
    return super.close();
  }
}
