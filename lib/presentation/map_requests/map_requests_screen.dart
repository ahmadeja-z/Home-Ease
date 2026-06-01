import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homeease/core/utils/map_worker_marker_icons.dart';
import 'package:homeease/models/nearby_worker_model.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/models/services_category_model.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_bloc.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_event.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_state.dart';
import 'package:homeease/presentation/map_requests/widgets/instant_request_invoice_card.dart';
import 'package:homeease/presentation/map_requests/widgets/worker_details_bottom_sheet.dart';
import 'package:homeease/presentation/map_requests/widgets/worker_offer_card.dart';
import 'package:homeease/core/services/geocoding_service.dart';
import 'package:homeease/repositories/home_repository.dart';
import 'package:homeease/repositories/map_requests_repository.dart';
import 'package:homeease/widgets/app_cache_image.dart';

class MapRequestsScreen extends StatelessWidget {
  const MapRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          MapRequestsBloc(repository: MapRequestsRepository())
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: MultiBlocListener(
        listeners: [
          BlocListener<MapRequestsBloc, MapRequestsState>(
            listenWhen: (previous, current) =>
                previous.errorMessage != current.errorMessage &&
                current.errorMessage != null,
            listener: (context, state) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage!)),
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
            _buildTopBar(),
            _buildRequestButton(),
            _buildRequestTrackingUI(),
            _buildLoadingOverlay(),
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
                child: _buildEmptyState(context, state),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, MapRequestsState state) {
    final errorMessage = state.errorMessage;

    final bool isDatabaseNotSetup = errorMessage?.contains('PGRST202') ?? false;
    final bool isTableNotSetup = errorMessage?.contains('PGRST204') ?? false;

    if (isDatabaseNotSetup || isTableNotSetup) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Database Setup Required',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'The map requests feature needs database setup. Please run the SQL script in:',
              style: TextStyle(fontSize: 14, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              'supabase_setup_guide.md',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This will create the required tables and RPC functions in Supabase.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error: $errorMessage',
                style: TextStyle(color: Colors.red[700], fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    if (state.nearbyWorkers.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No online workers nearby.',
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return BlocBuilder<MapRequestsBloc, MapRequestsState>(
      buildWhen: (p, c) => p.isLoading != c.isLoading || p.status != c.status,
      builder: (context, state) {
        if (!state.isLoading &&
            state.status != MapRequestStatus.loadingNearby &&
            state.status != MapRequestStatus.cancellingRequest) {
          return const SizedBox.shrink();
        }
        return Container(
          color: Colors.black26,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    _loadingMessage(state.status),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location),
              tooltip: 'Go to my location',
              onPressed: _onLocatePressed,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestButton() {
    return BlocBuilder<MapRequestsBloc, MapRequestsState>(
      buildWhen: (previous, current) =>
          previous.hasActiveRequest != current.hasActiveRequest ||
          previous.showCompleted != current.showCompleted ||
          previous.showCancelled != current.showCancelled,
      builder: (context, state) {
        if (state.hasActiveRequest ||
            state.showCompleted ||
            state.showCancelled) {
          return const SizedBox.shrink();
        }

        final bool isDatabaseNotSetup =
            state.errorMessage?.contains('PGRST202') ?? false;
        final bool isTableNotSetup =
            state.errorMessage?.contains('PGRST204') ?? false;

        return Positioned(
          bottom: _bottomOverlayInset(context),
          left: 16,
          right: 16,
          child: ElevatedButton(
            onPressed: (isDatabaseNotSetup || isTableNotSetup)
                ? null
                : () => _showRequestBottomSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: (isDatabaseNotSetup || isTableNotSetup)
                  ? Colors.grey
                  : Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
            ),
            child: Text(
              (isDatabaseNotSetup || isTableNotSetup)
                  ? 'Setup Required'
                  : 'Request Service',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  String _loadingMessage(MapRequestStatus status) {
    switch (status) {
      case MapRequestStatus.requestSending:
        return 'Sending request…';
      case MapRequestStatus.cancellingRequest:
        return 'Cancelling request…';
      case MapRequestStatus.acceptingOffer:
        return 'Accepting offer…';
      case MapRequestStatus.paymentProcessing:
        return 'Confirming payment…';
      case MapRequestStatus.paymentSuccess:
        return 'Payment confirmed';
      case MapRequestStatus.paymentError:
        return 'Payment failed';
      default:
        return 'Finding nearby workers…';
    }
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
            child: _CancelledRequestCard(
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
            child: _CompletedRequestCard(
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
                  _RequestTrackingCard(
                    request: request,
                    status: state.status,
                    waitingForOffers: state.isWaitingForOffers,
                    hasWorkerOffers: state.hasWorkerOffers,
                    canCancel: state.canCancelInstantRequest,
                    isCancelling:
                        state.status == MapRequestStatus.cancellingRequest,
                    onCancel: () =>
                        _showCancelDialog(context, request.id),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _RequestBottomSheet(
        categories: _categories,
        userLocation: state.userLocation,
        onSubmit: (categoryId, categoryName, description, perHourPrice) async {
          final location = state.userLocation ??
              const LatLng(37.7749, -122.4194);
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

    final bloc = context.read<MapRequestsBloc>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<MapRequestsBloc, MapRequestsState>(
            buildWhen: (previous, current) =>
                previous.activeRequest != current.activeRequest ||
                previous.isPayingInvoice != current.isPayingInvoice ||
                previous.canSubmitPayment != current.canSubmitPayment,
            builder: (context, state) {
              final request = state.activeRequest;
              if (request == null) {
                return const SizedBox.shrink();
              }

              return DraggableScrollableSheet(
                initialChildSize: 0.82,
                minChildSize: 0.45,
                maxChildSize: 0.95,
                builder: (_, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            child: InstantRequestInvoiceCard(
                              request: request,
                              isPaying: state.isPayingInvoice,
                              canConfirmPayment: state.canSubmitPayment,
                              onConfirmPaid: () =>
                                  _showConfirmPaymentDialog(context, request),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );

    _invoiceSheetOpen = false;
    bloc.add(const CloseInvoiceDialog());
  }

  void _showConfirmPaymentDialog(
    BuildContext context,
    ServiceRequestModel request,
  ) {
    if (!request.canCustomerConfirmPayment) return;

    final bloc = context.read<MapRequestsBloc>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm payment'),
        content: const Text(
          'Confirm that you have paid the worker. '
          'This will mark the job as completed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(PayInvoiceRequested(request.id));
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showCancelNotAllowedMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Worker already assigned. Please cancel from active request flow.',
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String requestId) {
    final bloc = context.read<MapRequestsBloc>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CancelInstantRequestDialog(
        onConfirm: (reason) {
          if (kDebugMode) {
            print('MapRequestsScreen - cancel request clicked: $requestId');
          }
          bloc.add(
            CancelJobEvent(
              requestId: requestId,
              reason: reason,
            ),
          );
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

}

class _CancelInstantRequestDialog extends StatefulWidget {
  final void Function(String? reason) onConfirm;

  const _CancelInstantRequestDialog({required this.onConfirm});

  @override
  State<_CancelInstantRequestDialog> createState() =>
      _CancelInstantRequestDialogState();
}

class _CancelInstantRequestDialogState
    extends State<_CancelInstantRequestDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancel request?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cancel this request? All worker offers will be closed.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'Why are you cancelling?',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep request'),
        ),
        TextButton(
          onPressed: () {
            final reason = _reasonController.text.trim();
            widget.onConfirm(reason.isEmpty ? null : reason);
          },
          child: const Text(
            'Cancel request',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}

class _CancelledRequestCard extends StatelessWidget {
  final ServiceRequestModel request;
  final VoidCallback onDismiss;

  const _CancelledRequestCard({
    required this.request,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.cancel_outlined, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Request cancelled',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            request.cancellationReason?.isNotEmpty == true
                ? request.cancellationReason!
                : 'Your instant request was cancelled. All worker offers are closed.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onDismiss,
            child: const Text('Back to map'),
          ),
        ],
      ),
    );
  }
}

class _CompletedRequestCard extends StatefulWidget {
  final ServiceRequestModel request;
  final VoidCallback onReload;
  final VoidCallback onRequestNewService;
  final VoidCallback onDismiss;

  const _CompletedRequestCard({
    required this.request,
    required this.onReload,
    required this.onRequestNewService,
    required this.onDismiss,
  });

  @override
  State<_CompletedRequestCard> createState() => _CompletedRequestCardState();
}

class _CompletedRequestCardState extends State<_CompletedRequestCard> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _submittingReview = false;
  bool _reviewSubmitted = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  bool get _hasExistingReview =>
      widget.request.rating != null && widget.request.rating! > 0;

  Future<void> _submitReview() async {
    if (_rating < 1 || _submittingReview || _reviewSubmitted || _hasExistingReview) {
      return;
    }

    setState(() => _submittingReview = true);

    context.read<MapRequestsBloc>().add(
          CompleteJobEvent(
            requestId: widget.request.id,
            rating: _rating.toDouble(),
            review: _reviewController.text.trim().isEmpty
                ? null
                : _reviewController.text.trim(),
          ),
        );

    setState(() {
      _submittingReview = false;
      _reviewSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final alreadyRated = _hasExistingReview || _reviewSubmitted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Job completed',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'You confirmed payment to the worker. Thank you!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (!alreadyRated) ...[
            const SizedBox(height: 16),
            const Text(
              'Rate your experience',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = starIndex),
                  icon: Icon(
                    starIndex <= _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            TextField(
              controller: _reviewController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Optional review',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _rating < 1 || _submittingReview ? null : _submitReview,
              child: _submittingReview
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit rating'),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Thanks for your feedback!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onReload,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onRequestNewService,
                  icon: const Icon(Icons.add),
                  label: const Text('New request'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: widget.onDismiss, child: const Text('Done')),
        ],
      ),
    );
  }
}

class _RequestTrackingCard extends StatelessWidget {
  final ServiceRequestModel request;
  final MapRequestStatus status;
  final bool waitingForOffers;
  final bool hasWorkerOffers;
  final bool canCancel;
  final bool isCancelling;
  final VoidCallback onCancel;
  final VoidCallback onCancelNotAllowed;

  const _RequestTrackingCard({
    required this.request,
    required this.status,
    required this.waitingForOffers,
    required this.hasWorkerOffers,
    required this.canCancel,
    required this.isCancelling,
    required this.onCancel,
    required this.onCancelNotAllowed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getStatusIcon(request.status),
                  color: _getStatusColor(request.status),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Status',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      _statusTitle(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (waitingForOffers) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
            const SizedBox(height: 4),
            Text(
              'Waiting for worker offers…',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (request.basePrice != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Your offer: ${request.basePrice!.toStringAsFixed(0)}/hr',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
          ],
          const SizedBox(height: 12),
          _buildProgressIndicator(context, request.status),
          const SizedBox(height: 12),
          if (request.workerInfo != null) ...[
            Row(
              children: [
                AppCacheImage(
                  imageUrl: request.workerInfo!.profileImage ?? '',
                  width: 40,
                  height: 40,
                  round: 20,
                  boxFit: BoxFit.cover,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.workerInfo!.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (request.workerInfo!.phoneNumber != null)
                        Text(
                          request.workerInfo!.phoneNumber!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                if (request.workerInfo!.rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        request.workerInfo!.rating!.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (canCancel || request.status == RequestStatus.accepted)
            Row(
              children: [
                if (canCancel)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isCancelling ? null : onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        hasWorkerOffers ? 'Close request' : 'Cancel request',
                      ),
                    ),
                  )
                else if (request.status == RequestStatus.accepted)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancelNotAllowed,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _statusTitle() {
    if (waitingForOffers) return 'Waiting for worker offers…';
    switch (request.status) {
      case RequestStatus.pending:
        return 'Review worker offers';
      case RequestStatus.inProgress:
        return 'Job in progress';
      case RequestStatus.billGenerated:
        return 'Invoice ready';
      default:
        return request.getStatusString();
    }
  }

  Widget _buildProgressIndicator(BuildContext context, RequestStatus status) {
    final steps = RequestStatus.values;
    final currentIndex = steps.indexOf(status);

    return Row(
      children: List.generate(steps.length - 2, (index) {
        final isActive = index <= currentIndex;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
      case RequestStatus.pendingAdminApproval:
        return Colors.orange;
      case RequestStatus.accepted:
        return Colors.blue;
      case RequestStatus.workerOnTheWay:
        return Colors.purple;
      case RequestStatus.arrived:
        return Colors.teal;
      case RequestStatus.inProgress:
        return Colors.green;
      case RequestStatus.completed:
        return Colors.green;
      case RequestStatus.cancelled:
      case RequestStatus.rejected:
        return Colors.red;
      case RequestStatus.approved:
      case RequestStatus.assigned:
      case RequestStatus.workSubmitted:
      case RequestStatus.billGenerated:
      case RequestStatus.paid:
        return Colors.grey;
      case RequestStatus.overdue:
        return Colors.deepOrange;
      case RequestStatus.workerNoShow:
        return Colors.red;
      case RequestStatus.reassigned:
        return Colors.indigo;
    }
  }

  IconData _getStatusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Icons.access_time;
      case RequestStatus.pendingAdminApproval:
        return Icons.admin_panel_settings_outlined;
      case RequestStatus.accepted:
        return Icons.check_circle;
      case RequestStatus.workerOnTheWay:
        return Icons.directions_car;
      case RequestStatus.arrived:
        return Icons.location_on;
      case RequestStatus.inProgress:
        return Icons.build;
      case RequestStatus.completed:
        return Icons.done_all;
      case RequestStatus.cancelled:
      case RequestStatus.rejected:
        return Icons.cancel;
      case RequestStatus.approved:
      case RequestStatus.assigned:
        return Icons.assignment;
      case RequestStatus.workSubmitted:
      case RequestStatus.billGenerated:
      case RequestStatus.paid:
        return Icons.receipt_long;
      case RequestStatus.overdue:
        return Icons.schedule_outlined;
      case RequestStatus.workerNoShow:
        return Icons.person_off_outlined;
      case RequestStatus.reassigned:
        return Icons.swap_horiz;
    }
  }
}

class _RequestBottomSheet extends StatefulWidget {
  final List<ServicesCategoriesModel> categories;
  final LatLng? userLocation;
  final Future<void> Function(
    String categoryId,
    String categoryName,
    String? description,
    double perHourPrice,
  ) onSubmit;

  const _RequestBottomSheet({
    required this.categories,
    required this.userLocation,
    required this.onSubmit,
  });

  @override
  State<_RequestBottomSheet> createState() => _RequestBottomSheetState();
}

class _RequestBottomSheetState extends State<_RequestBottomSheet> {
  ServicesCategoriesModel? _selectedCategory;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _perHourPriceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    _perHourPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Request Service',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a service and describe your needs',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              'Service Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.categories.map((category) {
                final isSelected = _selectedCategory?.id == category.id;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (category.picture != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              category.picture!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          category.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your per-hour price',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _perHourPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'e.g. 2500',
                prefixText: '₦ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Per-hour price is required';
                }
                final price = double.tryParse(value.trim());
                if (price == null) {
                  return 'Enter a valid number';
                }
                if (price <= 0) {
                  return 'Price must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe your service needs...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedCategory == null || _isSubmitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        if (_selectedCategory == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please select a service category',
                              ),
                            ),
                          );
                          return;
                        }

                        final perHourPrice =
                            double.parse(_perHourPriceController.text.trim());

                        setState(() {
                          _isSubmitting = true;
                        });

                        await widget.onSubmit(
                          _selectedCategory!.id,
                          _selectedCategory!.name,
                          _descriptionController.text.isEmpty
                              ? null
                              : _descriptionController.text,
                          perHourPrice,
                        );

                        if (mounted) {
                          setState(() => _isSubmitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
