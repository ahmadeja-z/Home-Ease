import 'package:equatable/equatable.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_event.dart';
import 'package:homeease/presentation/customer_history/models/customer_history_model.dart';

/// One-shot intent consumed by [CustomerHistoryScreen] after drawer navigation.
class CustomerHistoryDrawerIntent extends Equatable {
  final CustomerHistoryTab tab;
  final CustomerHistoryFilters? scheduledFilters;
  final CustomerHistoryFilters? instantFilters;

  const CustomerHistoryDrawerIntent({
    required this.tab,
    this.scheduledFilters,
    this.instantFilters,
  });

  static const pendingInvoices = CustomerHistoryDrawerIntent(
    tab: CustomerHistoryTab.scheduled,
    scheduledFilters: CustomerHistoryFilters(
      statusFilter: 'bill_generated',
      paymentFilter: 'unpaid',
    ),
    instantFilters: CustomerHistoryFilters(
      statusFilter: 'bill_generated',
      paymentFilter: 'unpaid',
    ),
  );

  static const scheduledHistory = CustomerHistoryDrawerIntent(
    tab: CustomerHistoryTab.scheduled,
  );

  static const instantOrders = CustomerHistoryDrawerIntent(
    tab: CustomerHistoryTab.instant,
  );

  static const reviews = CustomerHistoryDrawerIntent(
    tab: CustomerHistoryTab.instant,
    instantFilters: CustomerHistoryFilters(statusFilter: 'completed'),
  );

  @override
  List<Object?> get props => [tab, scheduledFilters, instantFilters];
}
