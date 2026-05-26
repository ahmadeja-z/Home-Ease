import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homeease/core/services/permission_service.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/models/services_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduledBookingRepository {
  final SupabaseClient supabase;

  ScheduledBookingRepository({SupabaseClient? client})
      : supabase = client ?? Supabase.instance.client;

  static const String _imagesBucket = 'request-images';

  static const List<String> scheduledBookingStatuses = [
    'pending_admin_approval',
    'approved',
    'assigned',
    'accepted',
    'worker_on_the_way',
    'arrived',
    'in_progress',
    'bill_generated',
    'paid',
    'completed',
    'cancelled',
    'rejected',
  ];

  Future<Position> getCurrentLocation() async {
    final granted = await PermissionService.requestLocationPermission();
    if (!granted) {
      throw Exception(
        'Location permission is required to set your service address.',
      );
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please turn on GPS.');
    }

    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) return lastKnown;

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Uploads optional issue photos; returns public URLs (empty if none).
  Future<List<String>> uploadRequestImages({
    required String customerId,
    required List<File> files,
  }) async {
    if (files.isEmpty) return [];

    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      try {
        final bytes = await files[i].readAsBytes();
        final path =
            '$customerId/scheduled_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';

        await supabase.storage.from(_imagesBucket).uploadBinary(
              path,
              bytes,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );

        urls.add(supabase.storage.from(_imagesBucket).getPublicUrl(path));
      } catch (e) {
        if (kDebugMode) {
          print('ScheduledBookingRepository image upload failed: $e');
        }
        throw Exception(
          'Failed to upload image ${i + 1} of ${files.length}. '
          'Check your connection and try again.',
        );
      }
    }
    return urls;
  }

  Future<ServiceRequestModel> createScheduledBooking({
    required ServicesModel service,
    required DateTime scheduledDateTime,
    required String preferredTimeLabel,
    required LatLng customerLocation,
    required String customerAddress,
    required String description,
    List<String> customerRequestImages = const [],
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Please sign in to book a service.');
    }

    if (service.id == null) {
      throw Exception('Invalid service. Please go back and try again.');
    }

    final isFixed = service.showFixedPrice;
    final pricingType = isFixed ? 'fixed' : 'hourly';
    final basePrice = isFixed
        ? (service.fixedJobRate ?? 0)
        : service.perHourRate;

    if (basePrice <= 0) {
      throw Exception('This service has no valid pricing configured.');
    }

    final preferredDate =
        DateTime(scheduledDateTime.year, scheduledDateTime.month, scheduledDateTime.day);
    final now = DateTime.now().toUtc().toIso8601String();

    final requestData = <String, dynamic>{
      'service_id': service.id,
      'customer_id': userId,
      'worker_id': null,
      'category_id': service.categoryId,
      'category_name': service.categoryTitle ?? service.title,
      'customer_latitude': customerLocation.latitude,
      'customer_longitude': customerLocation.longitude,
      'customer_address': customerAddress,
      'description': description.trim().isEmpty ? null : description.trim(),
      'customer_request_images': customerRequestImages,
      'scheduled_time': scheduledDateTime.toUtc().toIso8601String(),
      'preferred_date': preferredDate.toIso8601String().split('T').first,
      'preferred_time': preferredTimeLabel,
      'booking_type': 'scheduled',
      'request_flow': 'admin_assign',
      'status': 'pending_admin_approval',
      'pricing_type': pricingType,
      'base_price': basePrice,
      'payment_status': 'unpaid',
      'final_amount': 0,
      'labor_charges': 0,
      'material_charges': 0,
      'platform_fee': 0,
      'created_at': now,
      'updated_at': now,
    };

    try {
      final response = await supabase
          .from('service_requests')
          .insert(requestData)
          .select()
          .single();

      final enriched = Map<String, dynamic>.from(response);
      enriched['service_title'] = service.title;
      enriched['service_main_image'] = service.mainImage;

      return await _mapSingleWithWorker(enriched);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('ScheduledBookingRepository createScheduledBooking: ${e.message}');
      }
      if (e.code == 'PGRST204') {
        throw Exception(
          'Scheduled booking is not available yet. Please contact support.',
        );
      }
      throw Exception(e.message);
    }
  }

  Future<ServiceRequestModel> fetchScheduledBookingDetails(
    String requestId,
  ) async {
    try {
      final row = await supabase
          .from('service_requests')
          .select('*')
          .eq('id', requestId)
          .eq('booking_type', 'scheduled')
          .maybeSingle();

      if (row == null) {
        throw Exception('Scheduled booking not found.');
      }

      final enriched = await _enrichWithService(Map<String, dynamic>.from(row));
      return await _mapSingleWithWorker(enriched);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('ScheduledBookingRepository fetchDetails: ${e.message}');
      }
      rethrow;
    }
  }

  Future<List<ServiceRequestModel>> fetchCustomerScheduledBookings({
    required String customerId,
    int limit = 50,
  }) async {
    try {
      final rows = await supabase
          .from('service_requests')
          .select('*')
          .eq('customer_id', customerId)
          .eq('booking_type', 'scheduled')
          .inFilter('status', scheduledBookingStatuses)
          .order('created_at', ascending: false)
          .limit(limit);

      final list = (rows as List).cast<Map<String, dynamic>>();
      final enriched = <Map<String, dynamic>>[];
      for (final row in list) {
        enriched.add(await _enrichWithService(row));
      }
      return _mapRowsWithWorkers(enriched);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('ScheduledBookingRepository fetchList: ${e.message}');
      }
      rethrow;
    }
  }

  Stream<ServiceRequestModel?> subscribeToScheduledBooking(String requestId) {
    return supabase
        .from('service_requests')
        .stream(primaryKey: ['id'])
        .eq('id', requestId)
        .map((events) => events.isEmpty ? null : events.first)
        .asyncMap((row) async {
          if (row == null) return null;
          if (row['booking_type'] != 'scheduled') return null;
          final enriched =
              await _enrichWithService(Map<String, dynamic>.from(row));
          return _mapSingleWithWorker(enriched);
        });
  }

  /// Realtime updates for all scheduled bookings of the current customer.
  Stream<List<ServiceRequestModel>> subscribeToCustomerScheduledBookings(
    String customerId,
  ) {
    return supabase
        .from('service_requests')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .asyncMap((events) async {
          final filtered = events
              .where(
                (r) =>
                    r['booking_type'] == 'scheduled' &&
                    scheduledBookingStatuses.contains(r['status']),
              )
              .cast<Map<String, dynamic>>()
              .toList();
          final enriched = <Map<String, dynamic>>[];
          for (final row in filtered) {
            enriched.add(await _enrichWithService(row));
          }
          return _mapRowsWithWorkers(enriched);
        });
  }

  Future<ServiceRequestModel> payInvoice(String requestId) async {
    if (kDebugMode) {
      print('ScheduledBookingRepository customer_pay_invoice: $requestId');
    }

    try {
      final data = await supabase.rpc(
        'customer_pay_invoice',
        params: {'p_request_id': requestId},
      );

      final map = Map<String, dynamic>.from(data as Map);
      final enriched = await _enrichWithService(map);
      return await _mapSingleWithWorker(enriched);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('ScheduledBookingRepository payInvoice: ${e.message}');
      }
      throw Exception(e.message);
    }
  }

  Future<Map<String, dynamic>> _enrichWithService(
    Map<String, dynamic> row,
  ) async {
    final copy = Map<String, dynamic>.from(row);
    final serviceId = copy['service_id'];
    if (serviceId == null) return copy;

    try {
      final service = await supabase
          .from('services')
          .select('title, main_image')
          .eq('id', serviceId)
          .maybeSingle();

      if (service != null) {
        copy['service_title'] ??= service['title'];
        copy['service_main_image'] ??= service['main_image'];
      }
    } catch (_) {
      // Service row optional for display
    }
    return copy;
  }

  Future<List<ServiceRequestModel>> _mapRowsWithWorkers(
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return [];

    final workerIds = rows
        .map((r) => r['worker_id'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final profilesById = <String, Map<String, dynamic>>{};
    if (workerIds.isNotEmpty) {
      final profiles = await supabase
          .from('profiles')
          .select('id, name, profile_picture, phone_number, rating')
          .inFilter('id', workerIds);

      for (final p in profiles) {
        final map = Map<String, dynamic>.from(p as Map);
        profilesById[map['id'] as String] = map;
      }
    }

    return rows.map((row) {
      final copy = Map<String, dynamic>.from(row);
      final workerId = copy['worker_id'] as String?;
      if (workerId != null && profilesById.containsKey(workerId)) {
        final profile = profilesById[workerId]!;
        copy['worker_name'] = profile['name'];
        copy['worker_profile_picture'] = profile['profile_picture'];
        copy['worker_phone'] = profile['phone_number'];
        copy['worker_rating'] = profile['rating'];
      }
      return _mapRequestRow(copy);
    }).toList();
  }

  Future<ServiceRequestModel> _mapSingleWithWorker(
    Map<String, dynamic> row,
  ) async {
    final list = await _mapRowsWithWorkers([row]);
    return list.first;
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
}
