import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:homeease/core/network/network_failure.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/customer_history/models/customer_history_model.dart';
import 'package:homeease/presentation/customer_history/utils/scheduled_request_helpers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerHistoryRepository {
  final SupabaseClient supabase;

  CustomerHistoryRepository({SupabaseClient? client})
      : supabase = client ?? Supabase.instance.client;

  static const List<String> customerHistoryStatuses = [
    'pending',
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
    'overdue',
    'worker_no_show',
    'reassigned',
  ];

  static const List<String> scheduledHistoryStatuses = [
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
    'overdue',
    'worker_no_show',
    'reassigned',
  ];

  static const List<String> instantHistoryStatuses = [
    'pending',
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

  static const Set<String> _activeStatusValues = {
    'pending',
    'pending_admin_approval',
    'approved',
    'assigned',
    'accepted',
    'worker_on_the_way',
    'arrived',
    'in_progress',
    'bill_generated',
    'overdue',
    'worker_no_show',
    'reassigned',
  };

  Future<List<ServiceRequestModel>> fetchScheduledHistory({
    required String customerId,
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    String? statusFilter,
    String? paymentFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? categoryId,
    CustomerHistorySort sort = CustomerHistorySort.newest,
  }) {
    return guardNetworkCall(() async {
    try {
      dynamic query = supabase
          .from('service_requests')
          .select('*')
          .eq('customer_id', customerId)
          .eq('booking_type', 'scheduled')
          .eq('request_flow', 'admin_assign')
          .inFilter('status', scheduledHistoryStatuses);

      query = _applyHistoryFilters(
        query,
        statusFilter: statusFilter,
        paymentFilter: paymentFilter,
        dateFrom: dateFrom,
        dateTo: dateTo,
        categoryId: categoryId,
      );

      query = _applySort(query, sort);
      query = query.range(offset, offset + limit - 1);

      final rows = await query as List<dynamic>;
      final enriched = <Map<String, dynamic>>[];
      for (final row in rows.cast<Map<String, dynamic>>()) {
        enriched.add(await _enrichWithService(row));
      }
      var models = await _mapRowsWithWorkers(enriched);

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        models = _applySearch(models, searchQuery.trim());
      }

      return models;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('CustomerHistoryRepository fetchScheduledHistory: ${e.message}');
      }
      rethrow;
    }
    });
  }

  Future<ServiceRequestModel> fetchScheduledHistoryDetails(
    String requestId,
  ) async {
    try {
      final row = await supabase
          .from('service_requests')
          .select('*')
          .eq('id', requestId)
          .eq('booking_type', 'scheduled')
          .eq('request_flow', 'admin_assign')
          .maybeSingle();

      if (row == null) {
        throw Exception('Scheduled request not found');
      }

      final enriched = await _enrichWithService(Map<String, dynamic>.from(row));
      final models = await _mapRowsWithWorkers([enriched]);
      return models.first;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print(
          'CustomerHistoryRepository fetchScheduledHistoryDetails: ${e.message}',
        );
      }
      rethrow;
    }
  }

  /// Instant orders only (`booking_type = instant`).
  Future<List<ServiceRequestModel>> fetchInstantHistory({
    required String customerId,
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    String? statusFilter,
    String? paymentFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    CustomerHistorySort sort = CustomerHistorySort.newest,
  }) {
    return guardNetworkCall(() async {
    try {
      dynamic query = supabase
          .from('service_requests')
          .select('*')
          .eq('customer_id', customerId)
          .eq('booking_type', 'instant')
          .eq('request_flow', 'direct_worker')
          .inFilter('status', instantHistoryStatuses);

      query = _applyHistoryFilters(
        query,
        statusFilter: statusFilter,
        paymentFilter: paymentFilter,
        dateFrom: dateFrom,
        dateTo: dateTo,
        categoryId: categoryId,
        minPrice: minPrice,
        maxPrice: maxPrice,
      );

      query = _applySort(query, sort);
      query = query.range(offset, offset + limit - 1);

      final rows = await query as List<dynamic>;
      var models = await _mapRowsWithWorkers(
        rows.cast<Map<String, dynamic>>(),
      );

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        models = _applySearch(models, searchQuery.trim());
      }

      return models;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('CustomerHistoryRepository fetchInstantHistory: ${e.message}');
      }
      rethrow;
    }
    });
  }

  /// @deprecated Use [fetchInstantHistory].
  Future<List<ServiceRequestModel>> fetchCustomerHistory({
    required String customerId,
    int limit = 20,
    int offset = 0,
    String? searchQuery,
    String? statusFilter,
    String? paymentFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    CustomerHistorySort sort = CustomerHistorySort.newest,
  }) {
    return fetchInstantHistory(
      customerId: customerId,
      limit: limit,
      offset: offset,
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      paymentFilter: paymentFilter,
      dateFrom: dateFrom,
      dateTo: dateTo,
      sort: sort,
    );
  }

  Future<ServiceRequestModel> fetchCustomerHistoryDetails(
    String requestId,
  ) async {
    try {
      final row = await supabase
          .from('service_requests')
          .select('*')
          .eq('id', requestId)
          .eq('booking_type', 'instant')
          .eq('request_flow', 'direct_worker')
          .maybeSingle();

      if (row == null) {
        throw Exception('Order not found');
      }

      final models = await _mapRowsWithWorkers([row]);
      return models.first;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print(
          'CustomerHistoryRepository fetchCustomerHistoryDetails: ${e.message}',
        );
      }
      rethrow;
    }
  }

  Future<CustomerHistorySummary> fetchCustomerHistorySummary(
    String customerId,
  ) {
    return guardNetworkCall(() async {
    try {
      final rows = await supabase
          .from('service_requests')
          .select(
            'status, payment_status, final_amount, customer_paid_amount, booking_type',
          )
          .eq('customer_id', customerId)
          .inFilter('status', customerHistoryStatuses);

      var totalRequests = 0;
      var activeJobs = 0;
      var completedJobs = 0;
      var pendingPayments = 0;
      var cancelledJobs = 0;
      var totalSpent = 0.0;

      for (final raw in rows) {
        final map = Map<String, dynamic>.from(raw as Map);
        totalRequests++;
        final status = map['status'] as String? ?? '';
        final payment = map['payment_status'] as String? ?? 'unpaid';
        final finalAmount = (map['final_amount'] as num?)?.toDouble() ?? 0;
        final paidAmount =
            (map['customer_paid_amount'] as num?)?.toDouble() ?? 0;

        if (_activeStatusValues.contains(status)) activeJobs++;
        if (status == 'completed') {
          completedJobs++;
          totalSpent += paidAmount > 0 ? paidAmount : finalAmount;
        }
        if (status == 'bill_generated' && payment == 'unpaid') {
          pendingPayments++;
        }
        if (status == 'cancelled' || status == 'rejected') {
          cancelledJobs++;
        }
      }

      return CustomerHistorySummary(
        totalRequests: totalRequests,
        activeJobs: activeJobs,
        completedJobs: completedJobs,
        pendingPayments: pendingPayments,
        totalSpent: totalSpent,
        cancelledJobs: cancelledJobs,
      );
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print(
          'CustomerHistoryRepository fetchCustomerHistorySummary: ${e.message}',
        );
      }
      rethrow;
    }
    });
  }

  /// Alias for scheduled details screen.
  Future<ServiceRequestModel> fetchScheduledRequestDetails(String requestId) =>
      fetchScheduledHistoryDetails(requestId);

  Stream<List<ServiceRequestModel>> subscribeScheduledRequestUpdates(
    String customerId,
  ) =>
      subscribeCustomerHistoryUpdates(customerId);

  Duration? calculateOverdueDuration(ServiceRequestModel request) =>
      ScheduledRequestHelpers.calculateOverdueDuration(request);

  Future<ServiceRequestModel> cancelScheduledRequest({
    required String requestId,
    required String reason,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw Exception('Please provide a cancellation reason.');
    }

    final now = DateTime.now().toUtc().toIso8601String();

    try {
      final row = await supabase
          .from('service_requests')
          .update({
            'status': 'cancelled',
            'cancellation_reason': trimmed,
            'updated_at': now,
          })
          .eq('id', requestId)
          .eq('customer_id', userId)
          .eq('booking_type', 'scheduled')
          .select()
          .maybeSingle();

      if (row == null) {
        throw Exception(
          'Unable to cancel this request. It may have already started.',
        );
      }

      final enriched = await _enrichWithService(Map<String, dynamic>.from(row));
      final models = await _mapRowsWithWorkers([enriched]);
      return models.first;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('CustomerHistoryRepository cancelScheduledRequest: ${e.message}');
      }
      throw Exception(e.message);
    }
  }

  Future<ServiceRequestModel> payScheduledInvoice(String requestId) async {
    if (kDebugMode) {
      print('CustomerHistoryRepository payScheduledInvoice: $requestId');
    }

    try {
      final data = await supabase.rpc(
        'customer_pay_invoice',
        params: {'p_request_id': requestId},
      );

      final map = Map<String, dynamic>.from(data as Map);
      final enriched = await _enrichWithService(map);
      final models = await _mapRowsWithWorkers([enriched]);
      return models.first;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('CustomerHistoryRepository payScheduledInvoice: ${e.message}');
      }
      throw Exception(e.message);
    }
  }

  Future<void> submitReview({
    required String requestId,
    required double rating,
    required String review,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await supabase.from('service_requests').update({
      'rating': rating,
      'review': review,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', requestId).eq('customer_id', userId);
  }

  Stream<List<ServiceRequestModel>> subscribeCustomerHistoryUpdates(
    String customerId,
  ) {
    return supabase
        .from('service_requests')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .order('created_at', ascending: false)
        .asyncMap((event) async {
          final filtered = event
              .where(
                (r) => customerHistoryStatuses.contains(r['status']),
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

  /// @deprecated Use [subscribeCustomerHistoryUpdates].
  Stream<List<ServiceRequestModel>> subscribeToCustomerHistoryUpdates(
    String customerId,
  ) =>
      subscribeCustomerHistoryUpdates(customerId);

  dynamic _applyHistoryFilters(
    dynamic query, {
    String? statusFilter,
    String? paymentFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
  }) {
    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.eq('status', statusFilter);
    }
    if (paymentFilter != null && paymentFilter.isNotEmpty) {
      query = query.eq('payment_status', paymentFilter);
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.eq('category_id', categoryId);
    }
    if (dateFrom != null) {
      query = query.gte('created_at', dateFrom.toUtc().toIso8601String());
    }
    if (dateTo != null) {
      final end = DateTime(
        dateTo.year,
        dateTo.month,
        dateTo.day,
        23,
        59,
        59,
      );
      query = query.lte('created_at', end.toUtc().toIso8601String());
    }
    if (minPrice != null) {
      query = query.gte('final_amount', minPrice);
    }
    if (maxPrice != null) {
      query = query.lte('final_amount', maxPrice);
    }
    return query;
  }

  dynamic _applySort(dynamic query, CustomerHistorySort sort) {
    switch (sort) {
      case CustomerHistorySort.oldest:
        return query.order('created_at', ascending: true);
      case CustomerHistorySort.highestAmount:
        return query.order('final_amount', ascending: false);
      case CustomerHistorySort.newest:
        return query.order('created_at', ascending: false);
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
    } catch (_) {}

    return copy;
  }

  List<ServiceRequestModel> _applySearch(
    List<ServiceRequestModel> orders,
    String query,
  ) {
    final q = query.toLowerCase();
    return orders.where((o) {
      final idMatch = o.id.toLowerCase().contains(q) ||
          o.shortRequestId.toLowerCase().contains(q);
      final category = (o.categoryName ?? '').toLowerCase().contains(q);
      final service = (o.serviceTitle ?? '').toLowerCase().contains(q);
      final address = (o.customerAddress ?? '').toLowerCase().contains(q);
      final worker = (o.workerInfo?.name ?? '').toLowerCase().contains(q);
      final description = (o.description ?? '').toLowerCase().contains(q);
      return idMatch ||
          category ||
          service ||
          address ||
          worker ||
          description;
    }).toList();
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
