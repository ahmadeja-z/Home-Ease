import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/presentation/customer_history/repository/customer_history_repository.dart';
import 'package:homeease/repositories/user_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'customer_drawer_event.dart';
import 'customer_drawer_state.dart';

class CustomerDrawerBloc extends Bloc<CustomerDrawerEvent, CustomerDrawerState> {
  final CustomerHistoryRepository historyRepository;
  final UserRepository userRepository;

  CustomerDrawerBloc({
    required this.historyRepository,
    required this.userRepository,
  }) : super(const CustomerDrawerState()) {
    on<LoadCustomerDrawerData>(_onLoad);
    on<RefreshCustomerDrawerData>(_onLoad);
  }

  Future<void> _onLoad(
    CustomerDrawerEvent event,
    Emitter<CustomerDrawerState> emit,
  ) async {
    final userId = userRepository.currentUser?.id;
    if (userId == null) {
      emit(state.copyWith(status: CustomerDrawerStatus.loaded));
      return;
    }

    emit(state.copyWith(status: CustomerDrawerStatus.loading));

    try {
      final summary =
          await historyRepository.fetchCustomerHistorySummary(userId);
      final unread = await _fetchUnreadNotificationCount(userId);

      emit(
        state.copyWith(
          status: CustomerDrawerStatus.loaded,
          pendingInvoiceCount: summary.pendingPayments,
          unreadNotificationCount: unread,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('CustomerDrawerBloc load failed: $e');
      }
      emit(state.copyWith(status: CustomerDrawerStatus.error));
    }
  }

  Future<int> _fetchUnreadNotificationCount(String userId) async {
    try {
      final rows = await Supabase.instance.client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false)
          .limit(99);

      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }
}
