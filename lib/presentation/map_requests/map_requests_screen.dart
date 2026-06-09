import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homeease/core/network/connectivity_service.dart';
import 'package:homeease/core/network/network_failure.dart';
import 'package:homeease/core/widgets/customer_offline_gate.dart';
import 'package:homeease/core/widgets/customer_reconnect_listener.dart';
import 'package:homeease/core/utils/map_worker_marker_icons.dart';
import 'package:homeease/core/utils/snackbar_helper.dart';
import 'package:homeease/models/nearby_worker_model.dart';
import 'package:homeease/models/services_category_model.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_bloc.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_event.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_state.dart';
import 'package:homeease/presentation/map_requests/widgets/completed_request_cards.dart';
import 'package:homeease/presentation/map_requests/widgets/dialogs/cancel_instant_request_dialog.dart';
import 'package:homeease/presentation/map_requests/widgets/instant_request_invoice_card.dart';
import 'package:homeease/presentation/map_requests/widgets/map_empty_state_banner.dart';
import 'package:homeease/presentation/map_requests/widgets/map_loading_overlay.dart';
import 'package:homeease/presentation/map_requests/widgets/map_top_controls.dart';
import 'package:homeease/presentation/map_requests/widgets/request_service_button.dart';
import 'package:homeease/presentation/map_requests/widgets/request_tracking_card.dart';
import 'package:homeease/presentation/map_requests/widgets/sheets/instant_invoice_sheet.dart';
import 'package:homeease/presentation/map_requests/widgets/request_bottom_sheet.dart';
import 'package:homeease/presentation/map_requests/widgets/worker_details_bottom_sheet.dart';
import 'package:homeease/presentation/map_requests/widgets/worker_offer_card.dart';
import 'package:homeease/core/services/geocoding_service.dart';
import 'package:homeease/repositories/home_repository.dart';
import 'package:homeease/repositories/map_requests_repository.dart';

class MapRequestsScreen extends StatelessWidget {
  const MapRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MapRequestsBloc(
            repository: MapRequestsRepository(),
            connectivityService: context.read<ConnectivityService>(),
          )
            ..add(const GetUserLocationEvent())
            ..add(StartUserLocationTrackingEvent()),
      child: const MapRequestsView(),
    );
  }
}

class MapRequestsView extends StatefulWidget {
  const MapRequestsView({super.key});

  @override
  State<MapRequestsView> createState() => _MapRequestsViewState();
}

class _MapRequestsViewState extends State<MapRequestsView>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  final HomeRepository _homeRepository = HomeRepository();
  final GeocodingService _geocodingService = GeocodingService();
  List<ServicesCategoriesModel> _categories = [];

  // Animation controller for smooth marker interpolation
  late AnimationController _markerAnimationController;
  LatLng? _oldWorkerLocation;
  LatLng? _currentWorkerLocation;
  double _oldHeading = 0.0;
  double _currentHeading = 0.0;
  bool _markerIconsReady = false;
  bool _invoiceSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _checkForActiveRequest();
    _loadMarkerIcons();

    // Initialize animation controller
    _markerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _markerAnimationController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadCategories() async {
    try {
      final result = await _homeRepository.getServicesCategories();
      setState(() {
        _categories = result.categories;
      });
    } catch (e) {
      // categories remain empty; bottom sheet will show no options
    }
  }

  Future<void> _checkForActiveRequest() async {
    final bloc = context.read<MapRequestsBloc>();
    bloc.add(const LoadActiveRequestById());
    bloc.add(ListenActiveRequestEvent());
  }

  Future<void> _loadMarkerIcons() async {
    await MapWorkerMarkerIcons.load(context);
    if (mounted) {
      setState(() => _markerIconsReady = true);
    }
  }

  void _showWorkerDetailsBottomSheet(NearbyWorkerModel worker) {
    final bloc = context.read<MapRequestsBloc>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => WorkerDetailsBottomSheet(
        worker: worker,
        fetchProfile: () => bloc.repository.getWorkerProfileById(worker.id),
      ),
    );
  }

  Set<Marker> _buildMapMarkers(MapRequestsState state) {
    final assignedId = state.activeRequest?.workerInfo?.id;
    final onlineIcon = MapWorkerMarkerIcons.online;
    final assignedIcon = MapWorkerMarkerIcons.assigned;
    final markers = <Marker>{};

    for (final worker in state.nearbyWorkers) {
      final isAssigned = worker.id == assignedId;
      final position = isAssigned && state.activeWorkerLocation != null
          ? state.activeWorkerLocation!
          : worker.location;

      BitmapDescriptor icon;
      if (_markerIconsReady) {
        icon = isAssigned
            ? (assignedIcon ??
                onlineIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ))
            : (onlineIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ));
      } else {
        icon = BitmapDescriptor.defaultMarkerWithHue(
          isAssigned
              ? BitmapDescriptor.hueAzure
              : BitmapDescriptor.hueGreen,
        );
      }

      markers.add(
        Marker(
          markerId: MarkerId(worker.id),
          position: position,
          rotation: isAssigned ? state.activeWorkerHeading : 0,
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          onTap: () => _showWorkerDetailsBottomSheet(worker),
        ),
      );
    }

    if (assignedId != null &&
        state.activeWorkerLocation != null &&
        !state.nearbyWorkers.any((w) => w.id == assignedId)) {
      final info = state.activeRequest!.workerInfo!;
      final fallbackWorker = NearbyWorkerModel(
        id: info.id,
        name: info.name,
        profileImage: info.profileImage,
        rating: info.rating ?? 0,
        distance: 0,
        location: state.activeWorkerLocation!,
        isOnline: true,
        categoryName: state.activeRequest!.categoryName,
      );

      markers.add(
        Marker(
          markerId: MarkerId(assignedId),
          position: state.activeWorkerLocation!,
          rotation: state.activeWorkerHeading,
          icon: _markerIconsReady && assignedIcon != null
              ? assignedIcon
              : BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
          anchor: const Offset(0.5, 0.5),
          onTap: () => _showWorkerDetailsBottomSheet(fallbackWorker),
        ),
      );
    }

    return markers;
  }

  Set<Circle> _buildUserLocationCircles(
    BuildContext context,
    LatLng? userLocation,
  ) {
    if (userLocation == null) return {};

    final primary = Theme.of(context).colorScheme.primary;

    return {
      Circle(
        circleId: const CircleId('customer_location_area'),
        center: userLocation,
        radius: 150,
        fillColor: primary.withValues(alpha: 0.12),
        strokeColor: primary.withValues(alpha: 0.45),
        strokeWidth: 2,
        zIndex: 0,
      ),
      Circle(
        circleId: const CircleId('customer_location_core'),
        center: userLocation,
        radius: 35,
        fillColor: primary.withValues(alpha: 0.22),
        strokeColor: primary,
        strokeWidth: 3,
        zIndex: 1,
      ),
    };
  }

  Set<Marker> _buildAllMapMarkers(MapRequestsState state) {
    return _buildMapMarkers(state);
  }

  Future<void> _animateToUserLocation(LatLng location) async {
    if (_mapController == null) return;
    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(location, 15),
    );
  }

  Future<void> _onLocatePressed() async {
    context.read<MapRequestsBloc>().add(
          const GetUserLocationEvent(recenterMap: true),
        );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _markerAnimationController.dispose();
    super.dispose();
  }

  void _fitCameraToBounds(LatLng p1, LatLng p2) {
    if (_mapController == null) return;
    final LatLngBounds bounds;
    if (p1.latitude > p2.latitude && p1.longitude > p2.longitude) {
      bounds = LatLngBounds(southwest: p2, northeast: p1);
    } else if (p1.longitude > p2.longitude) {
      bounds = LatLngBounds(
        southwest: LatLng(p1.latitude, p2.longitude),
        northeast: LatLng(p2.latitude, p1.longitude),
      );
    } else if (p1.latitude > p2.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(p2.latitude, p1.longitude),
        northeast: LatLng(p1.latitude, p2.longitude),
      );
    } else {
      bounds = LatLngBounds(southwest: p1, northeast: p2);
    }
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final state = context.read<MapRequestsBloc>().state;
    if (state.userLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(state.userLocation!, 15),
      );
    }
  }

  /// Clears the parent [NavbarScreen] floating bottom nav (extendBody: true).
  double _bottomOverlayInset(BuildContext context) {
    const premiumNavBarHeight = 68.0;
    const navBarOuterMargin = 12.0;
    const gapAboveNavBar = 12.0;
    return MediaQuery.paddingOf(context).bottom +
        navBarOuterMargin +
        premiumNavBarHeight +
        gapAboveNavBar;
  }

  void _refreshMapData() {
    final bloc = context.read<MapRequestsBloc>();
    bloc.add(RefreshNearbyWorkersEvent());
    bloc.add(LoadActiveRequestById());
    bloc.add(ListenActiveRequestEvent());
  }

  @override
  Widget build(BuildContext context) {
    return CustomerReconnectListener(
      onReconnect: _refreshMapData,
      child: BlocBuilder<MapRequestsBloc, MapRequestsState>(
        builder: (context, state) {
          final hasCachedData =
              state.nearbyWorkers.isNotEmpty || state.hasActiveRequest;

          return CustomerOfflineGate(
            hasCachedData: hasCachedData,
            onRetry: _refreshMapData,
            child: _buildMapScaffold(context),
          );
        },
      ),
    );
  }

  Widget _buildMapScaffold(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: MultiBlocListener(
        listeners: [
          BlocListener<MapRequestsBloc, MapRequestsState>(
            listenWhen: (previous, current) =>
                previous.errorMessage != current.errorMessage &&
                current.errorMessage != null,
            listener: (context, state) {
              if (isNetworkFailureMessage(state.errorMessage)) return;
              SnackBarHelper.showError(
                context,
                title: 'Error',
                subtitle: state.errorMessage!,
              );
            },
          ),
          BlocListener<MapRequestsBloc, MapRequestsState>(
            listenWhen: (previous, current) =>
                previous.invoicePresentationToken !=
                current.invoicePresentationToken,
            listener: (context, state) {
              final request = state.activeRequest;
              if (request != null) {
                logInstantInvoiceOpened(request);
              }
              unawaited(_presentInvoiceSheet(context));
            },
          ),
          BlocListener<MapRequestsBloc, MapRequestsState>(
            listenWhen: (previous, current) =>
                previous.isPayingInvoice &&
                !current.isPayingInvoice &&
                current.showCompleted,
            listener: (context, state) {
              if (_invoiceSheetOpen && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          BlocListener<MapRequestsBloc, MapRequestsState>(
            listenWhen: (previous, current) =>
                !previous.showCompleted && current.showCompleted,
            listener: (context, state) {
              if (kDebugMode && state.activeRequest != null) {
                print(
                  'MapRequestsScreen - job completed UI: '
                  '${state.activeRequest!.id}',
                );
              }
            },
          ),
          BlocListener<MapRequestsBloc, MapRequestsState>(
            listenWhen: (previous, current) {
              final userLocationFound =
                  previous.userLocation == null && current.userLocation != null;
              final userLocationRecenter =
                  previous.recenterMapToken != current.recenterMapToken;
              return userLocationFound || userLocationRecenter;
            },
            listener: (context, state) {
              if (_mapController != null && state.userLocation != null) {
                _animateToUserLocation(state.userLocation!);
              }
            },
          ),
          BlocListener<MapRequestsBloc, MapRequestsState>(
            listenWhen: (previous, current) {
              final trackingStarted =
                  previous.status != MapRequestStatus.trackingWorker &&
                  current.status == MapRequestStatus.trackingWorker;
              final workerMoved =
                  previous.activeWorkerLocation != current.activeWorkerLocation;
              return trackingStarted || workerMoved;
            },
            listener: (context, state) {
              if (_mapController == null || state.userLocation == null) return;

              if (state.status == MapRequestStatus.trackingWorker &&
                  state.activeWorkerLocation != null) {
                _fitCameraToBounds(
                  state.userLocation!,
                  state.activeWorkerLocation!,
                );
              }

              if (state.status == MapRequestStatus.trackingWorker &&
                  state.activeWorkerLocation != null &&
                  state.activeWorkerLocation != _currentWorkerLocation) {
                _oldWorkerLocation =
                    _currentWorkerLocation ?? state.activeWorkerLocation;
                _currentWorkerLocation = state.activeWorkerLocation;
                _oldHeading = _currentHeading;
                _currentHeading = state.activeWorkerHeading;

                if (_currentHeading - _oldHeading > 180) {
                  _oldHeading += 360;
                } else if (_oldHeading - _currentHeading > 180) {
                  _currentHeading += 360;
                }

                _markerAnimationController.forward(from: 0.0);
              }
            },
          ),
        ],
        child: Stack(
          children: [
            _buildMap(),
            MapTopControls(onLocatePressed: _onLocatePressed),
            _buildRequestButton(),
            _buildRequestTrackingUI(),
            BlocBuilder<MapRequestsBloc, MapRequestsState>(
              buildWhen: (p, c) =>
                  p.isLoading != c.isLoading || p.status != c.status,
              builder: (context, state) => MapLoadingOverlay(state: state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return BlocBuilder<MapRequestsBloc, MapRequestsState>(
      buildWhen: (previous, current) =>
          previous.userLocation != current.userLocation ||
          previous.nearbyWorkers != current.nearbyWorkers ||
          previous.cameraPosition != current.cameraPosition ||
          previous.status != current.status ||
          previous.activeWorkerLocation != current.activeWorkerLocation ||
          previous.activeWorkerHeading != current.activeWorkerHeading ||
          previous.activeRequest != current.activeRequest,
      builder: (context, state) {
        Set<Marker> displayMarkers = _buildAllMapMarkers(state);
        final userCircles = _buildUserLocationCircles(context, state.userLocation);

        if (state.status == MapRequestStatus.trackingWorker && 
            _oldWorkerLocation != null && 
            _currentWorkerLocation != null && 
            state.activeRequest?.workerInfo?.id != null) {
          
          final t = Curves.easeInOut.transform(_markerAnimationController.value);
          final lat = _oldWorkerLocation!.latitude + (_currentWorkerLocation!.latitude - _oldWorkerLocation!.latitude) * t;
          final lng = _oldWorkerLocation!.longitude + (_currentWorkerLocation!.longitude - _oldWorkerLocation!.longitude) * t;
          final heading = _oldHeading + (_currentHeading - _oldHeading) * t;

          final markerId = MarkerId(state.activeRequest!.workerInfo!.id);
          
          // Find the existing worker marker
          Marker? existingMarker;
          try {
            existingMarker = displayMarkers.firstWhere((m) => m.markerId == markerId);
          } catch (_) {}

          if (existingMarker != null) {
            displayMarkers.remove(existingMarker);
            displayMarkers.add(existingMarker.copyWith(
              positionParam: LatLng(lat, lng),
              rotationParam: heading,
            ));
          }
        }

        return Stack(
          children: [
            GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: state.userLocation ?? const LatLng(37.7749, -122.4194),
                zoom: state.zoomLevel,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              markers: displayMarkers,
              circles: userCircles,
              polylines: state.routePolylines,
              onTap: (_) {},
            ),
            if (state.nearbyWorkers.isEmpty &&
                !state.isLoading &&
                state.status == MapRequestStatus.workersLoaded &&
                !state.hasActiveRequest)
              Positioned(
                top: 160,
                left: 16,
                right: 16,
                child: MapEmptyStateBanner(state: state),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRequestButton() {
    return BlocBuilder<MapRequestsBloc, MapRequestsState>(
      buildWhen: (previous, current) =>
          previous.hasActiveRequest != current.hasActiveRequest ||
          previous.showCompleted != current.showCompleted ||
          previous.showCancelled != current.showCancelled ||
          previous.errorMessage != current.errorMessage,
      builder: (context, state) {
        return RequestServiceButton(
          state: state,
          bottomInset: _bottomOverlayInset(context),
          isOffline: isCustomerOffline(context),
          onPressed: () => _showRequestBottomSheet(context),
        );
      },
    );
  }

  Widget _buildRequestTrackingUI() {
    return BlocBuilder<MapRequestsBloc, MapRequestsState>(
      buildWhen: (previous, current) =>
          previous.activeRequest != current.activeRequest ||
          previous.status != current.status ||
          previous.workerOffers != current.workerOffers ||
          previous.showCancelled != current.showCancelled ||
          previous.hasPendingInvoice != current.hasPendingInvoice ||
          previous.isInvoiceOpening != current.isInvoiceOpening ||
          previous.isPayingInvoice != current.isPayingInvoice ||
          previous.showCompleted != current.showCompleted,
      builder: (context, state) {
        if (state.showCancelled && state.activeRequest != null) {
          return Positioned(
            bottom: _bottomOverlayInset(context),
            left: 16,
            right: 16,
            child: CancelledRequestCard(
              request: state.activeRequest!,
              onDismiss: () {
                context.read<MapRequestsBloc>().add(ClearActiveRequestEvent());
              },
            ),
          );
        }

        if (state.activeRequest == null) {
          return const SizedBox.shrink();
        }

        final request = state.activeRequest!;

        if (state.showCompleted) {
          return Positioned(
            bottom: _bottomOverlayInset(context),
            left: 16,
            right: 16,
            child: CompletedRequestCard(
              request: request,
              onReload: () {
                context.read<MapRequestsBloc>().add(
                      ReloadMapAfterCompletionEvent(),
                    );
              },
              onRequestNewService: () {
                final bloc = context.read<MapRequestsBloc>();
                bloc.add(ReloadMapAfterCompletionEvent());
                _showRequestBottomSheet(context);
              },
              onDismiss: () {
                context.read<MapRequestsBloc>().add(ClearActiveRequestEvent());
              },
            ),
          );
        }

        return Positioned(
          bottom: _bottomOverlayInset(context),
          left: 16,
          right: 16,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.55,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state.hasPendingInvoice)
                    InvoiceReadyCard(
                      request: request,
                      isOpening: state.isInvoiceOpening,
                      onViewInvoice: () {
                        context.read<MapRequestsBloc>().add(
                              OpenInvoiceRequested(requestId: request.id),
                            );
                      },
                    ),
                  if (state.hasWorkerOffers)
                    ...state.workerOffers.map(
                      (display) => WorkerOfferCard(
                        display: display,
                        isAccepting:
                            state.status == MapRequestStatus.acceptingOffer,
                        onAccept: () {
                          context.read<MapRequestsBloc>().add(
                                AcceptWorkerOfferEvent(
                                  offerId: display.offer.id,
                                  requestId: request.id,
                                ),
                              );
                        },
                      ),
                    ),
                  RequestTrackingCard(
                    request: request,
                    status: state.status,
                    waitingForOffers: state.isWaitingForOffers,
                    hasWorkerOffers: state.hasWorkerOffers,
                    canCancel: state.canCancelInstantRequest,
                    isCancelling:
                        state.status == MapRequestStatus.cancellingRequest,
                    onCancel: () => _showCancelDialog(context, request.id),
                    onCancelNotAllowed: () =>
                        _showCancelNotAllowedMessage(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showRequestBottomSheet(BuildContext context) {
    final state = context.read<MapRequestsBloc>().state;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => RequestBottomSheet(
        categories: _categories,
        userLocation: state.userLocation,
        onSubmit: (categoryId, categoryName, description, perHourPrice) async {
          final location =
              state.userLocation ?? const LatLng(37.7749, -122.4194);
          final address = await _geocodingService.getAddressFromCoordinates(
                location.latitude,
                location.longitude,
              ) ??
              'Current Location';

          if (context.mounted) {
            context.read<MapRequestsBloc>().add(
                  CreateServiceRequestEvent(
                    categoryId: categoryId,
                    categoryName: categoryName,
                    customerLocation: location,
                    customerAddress: address,
                    description: description,
                    perHourPrice: perHourPrice,
                  ),
                );
          }

          if (sheetContext.mounted) Navigator.pop(sheetContext);
        },
      ),
    );
  }

  Future<void> _presentInvoiceSheet(BuildContext context) async {
    if (_invoiceSheetOpen || !context.mounted) return;
    _invoiceSheetOpen = true;

    await InstantInvoiceSheet.show(context);

    if (mounted) _invoiceSheetOpen = false;
  }

  void _showCancelNotAllowedMessage(BuildContext context) {
    SnackBarHelper.showError(
      context,
      title: 'Cannot cancel',
      subtitle:
          'Worker already assigned. Please cancel from active request flow.',
    );
  }

  void _showCancelDialog(BuildContext context, String requestId) {
    final bloc = context.read<MapRequestsBloc>();

    CancelInstantRequestDialog.show(
      context,
      onConfirm: (reason) {
        if (kDebugMode) {
          print('MapRequestsScreen - cancel request clicked: $requestId');
        }
        bloc.add(CancelJobEvent(requestId: requestId, reason: reason));
      },
    );
  }
}

