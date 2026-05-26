import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homeease/models/nearby_worker_model.dart';
import 'package:homeease/models/request_worker_offer_model.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/models/worker_profile_model.dart';
import 'package:homeease/core/services/permission_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapRequestsRepository {
  final supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _workersSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _requestSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _offersSubscription;
  RealtimeChannel? _broadcastChannel;

  Future<Position> getCurrentLocation() async {
    final granted = await PermissionService.requestLocationPermission();
    if (!granted) {
      throw Exception(
        'Location permission is required to show your position on the map.',
      );
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please turn on GPS.');
    }

    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      return lastKnown;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  /// Live GPS updates for the customer blue dot / map highlight.
  Stream<Position> watchUserLocation() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
      ),
    );
  }

  /// All online workers near [userLocation] — no category filter (map display).
  Future<List<NearbyWorkerModel>> fetchNearbyWorkers({
    required LatLng userLocation,
    double radius = 10.0,
  }) async {
    if (kDebugMode) {
      print('MapRequestsRepository - fetchNearbyWorkers (no category)');
      print(
        '  userLocation: ${userLocation.latitude}, ${userLocation.longitude}',
      );
      print('  radius_km: $radius');
    }

    try {
      final data = await supabase.rpc(
        'get_nearby_workers',
        params: {
          'user_lat': userLocation.latitude,
          'user_lng': userLocation.longitude,
          'radius_km': radius,
        },
      );

      final workers = _parseWorkerRows(data);

      if (kDebugMode) {
        print('  nearby workers count: ${workers.length}');
        for (var i = 0; i < workers.length; i++) {
          final w = workers[i];
          print(
            '  marker [$i] ${w.name} | ${w.categoryName ?? "—"} | '
            '${w.distance.toStringAsFixed(1)} km',
          );
        }
      }

      return workers;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('PostgrestException fetchNearbyWorkers: ${e.message}');
      }
      rethrow;
    }
  }

  /// Category-filtered workers — use when sending instant request offers only.
  Future<List<NearbyWorkerModel>> fetchNearbyWorkersByCategory({
    required LatLng userLocation,
    required String categoryId,
    double radius = 10.0,
  }) async {
    if (kDebugMode) {
      print('MapRequestsRepository - fetchNearbyWorkersByCategory');
      print('  category for request offers: $categoryId');
      print(
        '  userLocation: ${userLocation.latitude}, ${userLocation.longitude}',
      );
    }

    try {
      final data = await supabase.rpc(
        'get_nearby_workers',
        params: {
          'user_lat': userLocation.latitude,
          'user_lng': userLocation.longitude,
          'radius_km': radius,
          'category_id': categoryId,
        },
      );

      final workers = _parseWorkerRows(data);

      if (kDebugMode) {
        print('  matching workers for offers: ${workers.length}');
      }

      return workers;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202') {
        if (kDebugMode) {
          print(
            'MapRequestsRepository - RPC has no category_id param, '
            'filtering locally',
          );
        }
        final all = await fetchNearbyWorkers(
          userLocation: userLocation,
          radius: radius,
        );
        return all.where((w) => w.categoryId == categoryId).toList();
      }
      if (kDebugMode) {
        print('PostgrestException fetchNearbyWorkersByCategory: ${e.message}');
      }
      rethrow;
    }
  }

  /// @deprecated Use [fetchNearbyWorkers].
  Future<List<NearbyWorkerModel>> fetchOnlineWorkers({
    required LatLng userLocation,
    double radius = 10.0,
  }) =>
      fetchNearbyWorkers(userLocation: userLocation, radius: radius);

  /// @deprecated Use [fetchNearbyWorkers] or [fetchNearbyWorkersByCategory].
  Future<List<NearbyWorkerModel>> getNearbyWorkers({
    required LatLng userLocation,
    double radius = 10.0,
    String? categoryId,
  }) {
    if (categoryId != null && categoryId.isNotEmpty) {
      return fetchNearbyWorkersByCategory(
        userLocation: userLocation,
        categoryId: categoryId,
        radius: radius,
      );
    }
    return fetchNearbyWorkers(userLocation: userLocation, radius: radius);
  }

  List<NearbyWorkerModel> _parseWorkerRows(dynamic data) {
    final workers = <NearbyWorkerModel>[];
    for (final row in data as List) {
      try {
        workers.add(NearbyWorkerModel.fromJson(row as Map<String, dynamic>));
      } catch (e) {
        if (kDebugMode) {
          print('MapRequestsRepository - skip invalid worker row: $e | $row');
        }
      }
    }
    return workers;
  }

  Future<WorkerProfileModel?> getWorkerProfileById(String workerId) async {
    try {
      final data = await supabase
          .from('profiles')
          .select(
            'id, name, profile_picture, phone_number, rating, category_id, status, role, is_active',
          )
          .eq('id', workerId)
          .maybeSingle();

      if (data == null) return null;
      return WorkerProfileModel.fromJson(data);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('PostgrestException getWorkerProfileById: ${e.message}');
      }
      rethrow;
    }
  }

  Stream<void> listenNearbyWorkers({String? categoryId}) {
    return supabase
        .from('worker_locations')
        .stream(primaryKey: ['worker_id'])
        .eq('is_online', true)
        .map((_) {});
  }

  /// Creates an instant hourly service request (worker_id null, status pending).
  Future<ServiceRequestModel> createInstantRequest({
    required String categoryId,
    required String categoryName,
    required LatLng customerLocation,
    required String customerAddress,
    required double perHourPrice,
    String? description,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    if (kDebugMode) {
      print(
        'MapRequestsRepository - customer base price entered: $perHourPrice/hr',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final requestData = {
      'customer_id': userId,
      'worker_id': null,
      'category_id': categoryId,
      'category_name': categoryName,
      'customer_latitude': customerLocation.latitude,
      'customer_longitude': customerLocation.longitude,
      'customer_address': customerAddress,
      'description': description,
      'status': 'pending',
      'booking_type': 'instant',
      'request_flow': 'direct_worker',
      'pricing_type': 'hourly',
      'base_price': perHourPrice,
      'accepted_price': null,
      'labor_charges': 0,
      'material_charges': 0,
      'platform_fee': 0,
      'final_amount': 0,
      'payment_status': 'unpaid',
      'created_at': now,
      'updated_at': now,
    };

    try {
      final response = await supabase
          .from('service_requests')
          .insert(requestData)
          .select()
          .single();

      if (kDebugMode) {
        print('MapRequestsRepository - request created: ${response['id']}');
      }

      return ServiceRequestModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('PostgrestException createInstantRequest: ${e.message}');
      }
      if (e.code == 'PGRST204') {
        throw Exception(
          'Service requests feature is not yet available. Please contact support.',
        );
      }
      rethrow;
    }
  }

  /// Inserts one offer row per matched online worker at customer's base price.
  Future<int> createWorkerOffers({
    required String requestId,
    required List<String> workerIds,
    required double basePrice,
  }) async {
    if (workerIds.isEmpty) {
      if (kDebugMode) {
        print('MapRequestsRepository - createWorkerOffers: no workers to notify');
      }
      return 0;
    }

    final rows = workerIds
        .map(
          (workerId) => {
            'request_id': requestId,
            'worker_id': workerId,
            'status': 'sent',
            'offered_price': basePrice,
            'offer_type': 'base_price',
          },
        )
        .toList();

    try {
      await supabase.from('request_worker_offers').insert(rows);

      if (kDebugMode) {
        print(
          'MapRequestsRepository - worker offers created: ${rows.length}',
        );
      }

      return rows.length;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('PostgrestException createWorkerOffers: ${e.message}');
      }
      throw Exception('Failed to notify workers: ${e.message}');
    }
  }

  /// Full instant flow: create hourly request + notify matched workers.
  Future<ServiceRequestModel> createInstantRequestWithOffers({
    required String categoryId,
    required String categoryName,
    required LatLng customerLocation,
    required String customerAddress,
    required List<String> matchedWorkerIds,
    required double perHourPrice,
    String? description,
  }) async {
    final request = await createInstantRequest(
      categoryId: categoryId,
      categoryName: categoryName,
      customerLocation: customerLocation,
      customerAddress: customerAddress,
      perHourPrice: perHourPrice,
      description: description,
    );

    await createWorkerOffers(
      requestId: request.id,
      workerIds: matchedWorkerIds,
      basePrice: perHourPrice,
    );

    return request;
  }

  /// Realtime worker offer updates for a pending request.
  Stream<List<RequestWorkerOfferModel>> subscribeToWorkerOfferUpdates(
    String requestId,
  ) {
    return supabase
        .from('request_worker_offers')
        .stream(primaryKey: ['id'])
        .eq('request_id', requestId)
        .map((rows) {
          final offers = rows
              .map((r) => RequestWorkerOfferModel.fromJson(r))
              .where((o) => o.isActionable || o.isTerminal)
              .toList();

          for (final offer in offers.where((o) => o.isActionable)) {
            if (kDebugMode) {
              print(
                'MapRequestsRepository - offer update received: ${offer.id} '
                'status=${offer.statusValue} '
                'price=${offer.offeredPrice}',
              );
              if (offer.offeredPrice != null) {
                print(
                  'MapRequestsRepository - worker offer price received: '
                  '${offer.offeredPrice}/hr',
                );
              }
            }
          }

          return offers.where((o) => o.isActionable).toList();
        });
  }

  /// Customer accepts a worker's per-hour offer.
  Future<ServiceRequestModel> acceptWorkerOffer({
    required String offerId,
    required String requestId,
  }) async {
    try {
      final data = await supabase.rpc(
        'customer_accept_worker_offer',
        params: {
          'p_offer_id': offerId,
          'p_request_id': requestId,
        },
      );

      if (kDebugMode) {
        print('MapRequestsRepository - customer accepted offer: $offerId');
        print('MapRequestsRepository - service request accepted: $requestId');
      }

      return _mapRequestRow(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('PostgrestException acceptWorkerOffer: ${e.message}');
      }
      if (e.message.contains('request_already_accepted') ||
          e.message.contains('invalid_offer')) {
        throw Exception(
          'This offer is no longer available. Please choose another worker.',
        );
      }
      rethrow;
    }
  }

  /// Customer confirms direct payment to worker (outside app gateway).
  Future<ServiceRequestModel> payInvoice(String requestId) async {
    if (kDebugMode) {
      print('MapRequestsRepository - customer_pay_invoice RPC called: $requestId');
    }

    try {
      final data = await supabase.rpc(
        'customer_pay_invoice',
        params: {'p_request_id': requestId},
      );

      if (kDebugMode) {
        print('MapRequestsRepository - payment success: $requestId');
      }

      return _mapRequestRow(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('MapRequestsRepository - payment failed: $requestId — ${e.message}');
      }
      rethrow;
    }
  }

  /// @deprecated Use [createInstantRequest].
  Future<ServiceRequestModel> createServiceRequest({
    required String categoryId,
    required String categoryName,
    required LatLng customerLocation,
    required String customerAddress,
    String? description,
    required String requestType,
    double? estimatedPrice,
  }) {
    return createInstantRequest(
      categoryId: categoryId,
      categoryName: categoryName,
      customerLocation: customerLocation,
      customerAddress: customerAddress,
      perHourPrice: estimatedPrice ?? 0,
      description: description,
    );
  }

  /// Realtime updates for the current customer's active requests.
  Stream<ServiceRequestModel?> subscribeToCustomerRequestUpdates(
    String customerId,
  ) {
    return listenActiveRequest(customerId);
  }

  Stream<ServiceRequestModel> listenRequestUpdates(String requestId) {
    return supabase
        .from('service_requests')
        .stream(primaryKey: ['id'])
        .eq('id', requestId)
        .map((event) {
          if (event.isEmpty) {
            throw Exception('Request not found');
          }
          return _mapRequestRow(event.first);
        });
  }

  Stream<ServiceRequestModel?> listenActiveRequest(String customerId) {
    return supabase
        .from('service_requests')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .handleError((error) {
          if (kDebugMode) {
            print('MapRequestsRepository - listenActiveRequest error: $error');
          }
          if (error is PostgrestException && error.code == 'PGRST204') {
            throw Exception('Service requests feature is not yet available.');
          }
        })
        .map((event) {
          // Exclude completed — shown only in-session after customer confirms payment.
          const activeStatuses = [
            'pending',
            'accepted',
            'worker_on_the_way',
            'arrived',
            'in_progress',
            'bill_generated',
          ];

          final activeRequests = event.where(
            (req) => activeStatuses.contains(req['status']),
          );

          if (activeRequests.isEmpty) {
            return null;
          }

          final request = _mapRequestRow(activeRequests.first);

          if (kDebugMode) {
            switch (request.status) {
              case RequestStatus.accepted:
                print(
                  'MapRequestsRepository - service request accepted',
                );
                if (request.workerInfo != null) {
                  print('  worker: ${request.workerInfo!.name}');
                }
                break;
              case RequestStatus.billGenerated:
                print('MapRequestsRepository - invoice received: ${request.id}');
                break;
              case RequestStatus.completed:
                print(
                  'MapRequestsRepository - request completed (paid=${request.paymentStatus}): '
                  '${request.id}',
                );
                break;
              default:
                break;
            }
          }

          return request;
        });
  }

  ServiceRequestModel _mapRequestRow(Map<String, dynamic> requestData) {
    WorkerInfo? workerInfo;

    if (requestData['worker_id'] != null) {
      workerInfo = WorkerInfo.fromJson({
        'id': requestData['worker_id'],
        'name': requestData['worker_name'],
        'profile_picture': requestData['worker_profile_picture'],
        'rating': requestData['worker_rating'],
        'phone_number': requestData['worker_phone'],
        'latitude': requestData['worker_latitude'],
        'longitude': requestData['worker_longitude'],
      });
    }

    final requestJson = Map<String, dynamic>.from(requestData);
    if (workerInfo != null) {
      requestJson['worker_info'] = workerInfo.toJson();
    }

    return ServiceRequestModel.fromJson(requestJson);
  }

  Stream<LatLng> listenWorkerLocationBroadcast(String requestId) {
    late StreamController<LatLng> controller;

    void startListen() {
      _broadcastChannel = supabase.channel('request_$requestId');
      _broadcastChannel!
          .onBroadcast(
            event: 'location_update',
            callback: (payload) {
              if (payload['latitude'] != null && payload['longitude'] != null) {
                controller.add(
                  LatLng(
                    (payload['latitude'] as num).toDouble(),
                    (payload['longitude'] as num).toDouble(),
                  ),
                );
              }
            },
          )
          .subscribe();
    }

    void stopListen() {
      _broadcastChannel?.unsubscribe();
      _broadcastChannel = null;
    }

    controller = StreamController<LatLng>(
      onListen: startListen,
      onCancel: stopListen,
    );

    return controller.stream;
  }

  Future<void> updateWorkerLocation({
    required String workerId,
    required LatLng location,
  }) async {
    await supabase.from('worker_locations').upsert({
      'worker_id': workerId,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
  }) async {
    final updateData = {
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (status == 'completed') {
      updateData['completed_at'] = DateTime.now().toUtc().toIso8601String();
    }

    await supabase.from('service_requests').update(updateData).eq('id', requestId);
  }

  Future<void> startJob(String requestId) async {
    await updateRequestStatus(requestId: requestId, status: 'in_progress');
  }

  /// @deprecated Customer completes via [payInvoice] after bill_generated.
  Future<void> completeJob({
    required String requestId,
    String? review,
    double? rating,
  }) async {
    await supabase.from('service_requests').update({
      'review': review,
      'rating': rating,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', requestId);
  }

  Future<void> cancelJob({
    required String requestId,
    String? reason,
  }) async {
    await supabase.from('service_requests').update({
      'status': 'cancelled',
      'cancellation_reason': reason,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', requestId);

    await supabase
        .from('request_worker_offers')
        .update({
          'status': 'expired',
          'responded_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('request_id', requestId)
        .eq('status', 'sent');
  }

  void dispose() {
    _workersSubscription?.cancel();
    _requestSubscription?.cancel();
    _offersSubscription?.cancel();
    _broadcastChannel?.unsubscribe();
  }
}
