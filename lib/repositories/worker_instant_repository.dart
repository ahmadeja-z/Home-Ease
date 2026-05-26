import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:homeease/models/request_worker_offer_model.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Worker-side instant booking: offers realtime, accept/reject, status updates.
class WorkerInstantRepository {
  final SupabaseClient supabase = Supabase.instance.client;
  StreamSubscription<List<Map<String, dynamic>>>? _offersSubscription;
  RealtimeChannel? _offersChannel;

  String? get currentWorkerId => supabase.auth.currentUser?.id;

  /// Subscribe to new/updated offers for the logged-in worker (status == sent).
  Stream<RequestWorkerOfferModel> subscribeToWorkerInstantOffers() {
    final workerId = currentWorkerId;
    if (workerId == null) {
      return Stream.error(Exception('Worker not authenticated'));
    }

    if (kDebugMode) {
      print('WorkerInstantRepository - subscribeToWorkerInstantOffers: $workerId');
    }

    return supabase
        .from('request_worker_offers')
        .stream(primaryKey: ['id'])
        .eq('worker_id', workerId)
        .map((rows) => rows.where((r) => r['status'] == 'sent').toList())
        .where((rows) => rows.isNotEmpty)
        .asyncMap((rows) async {
          final latest = rows.first;
          return fetchRequestByOffer(latest['id'] as String);
        });
  }

  /// Fetch offer + joined service_requests row.
  Future<RequestWorkerOfferModel> fetchRequestByOffer(String offerId) async {
    final data = await supabase
        .from('request_worker_offers')
        .select('*, service_requests(*)')
        .eq('id', offerId)
        .single();

    if (kDebugMode) {
      print('WorkerInstantRepository - fetchRequestByOffer: $offerId');
    }

    return RequestWorkerOfferModel.fromJson(data);
  }

  /// Worker accepts the customer's per-hour base price (customer picks worker later).
  Future<RequestWorkerOfferModel> acceptBasePrice(String offerId) async {
    try {
      final data = await supabase.rpc(
        'worker_accept_base_price',
        params: {'p_offer_id': offerId},
      );

      if (kDebugMode) {
        print('WorkerInstantRepository - acceptBasePrice OK: $offerId');
      }

      return RequestWorkerOfferModel.fromJson(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        print('WorkerInstantRepository - acceptBasePrice: ${e.message}');
      }
      rethrow;
    }
  }

  Future<RequestWorkerOfferModel> counterOffer({
    required String offerId,
    required double offeredPrice,
    String? workerMessage,
  }) async {
    final data = await supabase.rpc(
      'worker_counter_offer',
      params: {
        'p_offer_id': offerId,
        'p_offered_price': offeredPrice,
        'p_worker_message': workerMessage,
      },
    );

    if (kDebugMode) {
      print('WorkerInstantRepository - counterOffer: $offerId @ $offeredPrice');
    }

    return RequestWorkerOfferModel.fromJson(data as Map<String, dynamic>);
  }

  /// @deprecated Use [acceptBasePrice] for hourly bidding flow.
  Future<ServiceRequestModel> acceptInstantRequest({
    required String requestId,
    required String offerId,
  }) async {
    await acceptBasePrice(offerId);
    final offer = await fetchRequestByOffer(offerId);
    return offer.request!;
  }

  Future<void> rejectInstantRequest(String offerId) async {
    final workerId = currentWorkerId;
    if (workerId == null) {
      throw Exception('Worker not authenticated');
    }

    await supabase
        .from('request_worker_offers')
        .update({
          'status': 'rejected',
          'responded_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', offerId)
        .eq('worker_id', workerId)
        .eq('status', 'sent');

    if (kDebugMode) {
      print('WorkerInstantRepository - rejectInstantRequest: $offerId');
    }
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required RequestStatus status,
  }) async {
    final workerId = currentWorkerId;
    if (workerId == null) {
      throw Exception('Worker not authenticated');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final updateData = <String, dynamic>{
      'status': _statusToDb(status),
      'updated_at': now,
    };

    switch (status) {
      case RequestStatus.arrived:
        updateData['arrived_at'] = now;
        break;
      case RequestStatus.inProgress:
        updateData['started_at'] = now;
        break;
      case RequestStatus.completed:
        updateData['completed_at'] = now;
        break;
      default:
        break;
    }

    await supabase
        .from('service_requests')
        .update(updateData)
        .eq('id', requestId)
        .eq('worker_id', workerId);

    if (kDebugMode) {
      print(
        'WorkerInstantRepository - updateRequestStatus: $requestId → ${_statusToDb(status)}',
      );
    }
  }

  String _statusToDb(RequestStatus status) {
    switch (status) {
      case RequestStatus.workerOnTheWay:
        return 'worker_on_the_way';
      case RequestStatus.inProgress:
        return 'in_progress';
      case RequestStatus.accepted:
        return 'accepted';
      case RequestStatus.arrived:
        return 'arrived';
      case RequestStatus.completed:
        return 'completed';
      case RequestStatus.cancelled:
        return 'cancelled';
      case RequestStatus.pending:
        return 'pending';
      case RequestStatus.pendingAdminApproval:
        return 'pending_admin_approval';
      case RequestStatus.approved:
        return 'approved';
      case RequestStatus.assigned:
        return 'assigned';
      case RequestStatus.workSubmitted:
        return 'work_submitted';
      case RequestStatus.billGenerated:
        return 'bill_generated';
      case RequestStatus.paid:
        return 'paid';
      case RequestStatus.rejected:
        return 'rejected';
      case RequestStatus.overdue:
        return 'overdue';
      case RequestStatus.workerNoShow:
        return 'worker_no_show';
      case RequestStatus.reassigned:
        return 'reassigned';
    }
  }

  void dispose() {
    _offersSubscription?.cancel();
    _offersSubscription = null;
    _offersChannel?.unsubscribe();
    _offersChannel = null;
  }
}
