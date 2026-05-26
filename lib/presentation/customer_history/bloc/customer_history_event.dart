import 'package:equatable/equatable.dart';
import 'package:homeease/presentation/customer_history/models/customer_history_model.dart';

enum CustomerHistoryTab { scheduled, instant }

abstract class CustomerHistoryEvent extends Equatable {
  const CustomerHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomerHistory extends CustomerHistoryEvent {
  const LoadCustomerHistory();
}

class LoadScheduledHistory extends CustomerHistoryEvent {
  const LoadScheduledHistory();
}

class LoadInstantHistory extends CustomerHistoryEvent {
  const LoadInstantHistory();
}

class LoadMoreScheduledHistory extends CustomerHistoryEvent {
  const LoadMoreScheduledHistory();
}

class LoadMoreCustomerHistory extends CustomerHistoryEvent {
  const LoadMoreCustomerHistory();
}

class RefreshCustomerHistory extends CustomerHistoryEvent {
  const RefreshCustomerHistory();
}

class ChangeCustomerHistoryTab extends CustomerHistoryEvent {
  final CustomerHistoryTab tab;

  const ChangeCustomerHistoryTab(this.tab);

  @override
  List<Object?> get props => [tab];
}

class SearchCustomerHistory extends CustomerHistoryEvent {
  final String query;

  const SearchCustomerHistory(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterCustomerHistory extends CustomerHistoryEvent {
  final CustomerHistoryFilters filters;

  const FilterCustomerHistory(this.filters);

  @override
  List<Object?> get props => [filters];
}

class LoadCustomerHistoryDetails extends CustomerHistoryEvent {
  final String requestId;

  const LoadCustomerHistoryDetails(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class LoadScheduledHistoryDetails extends CustomerHistoryEvent {
  final String requestId;

  const LoadScheduledHistoryDetails(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class PayScheduledInvoice extends CustomerHistoryEvent {
  final String requestId;

  const PayScheduledInvoice(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class SubmitCustomerReview extends CustomerHistoryEvent {
  final String requestId;
  final double rating;
  final String review;

  const SubmitCustomerReview({
    required this.requestId,
    required this.rating,
    required this.review,
  });

  @override
  List<Object?> get props => [requestId, rating, review];
}

class CustomerHistoryRealtimeUpdated extends CustomerHistoryEvent {
  final List<dynamic> orders;

  const CustomerHistoryRealtimeUpdated(this.orders);

  @override
  List<Object?> get props => [orders];
}

class StartCustomerHistoryRealtime extends CustomerHistoryEvent {
  const StartCustomerHistoryRealtime();
}

class StopCustomerHistoryRealtime extends CustomerHistoryEvent {
  const StopCustomerHistoryRealtime();
}

/// Alias for scheduled details load.
class LoadScheduledRequestDetails extends CustomerHistoryEvent {
  final String requestId;

  const LoadScheduledRequestDetails(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class ScheduledRequestRealtimeUpdated extends CustomerHistoryEvent {
  final List<dynamic> orders;

  const ScheduledRequestRealtimeUpdated(this.orders);

  @override
  List<Object?> get props => [orders];
}

class CancelScheduledRequest extends CustomerHistoryEvent {
  final String requestId;
  final String reason;

  const CancelScheduledRequest({
    required this.requestId,
    required this.reason,
  });

  @override
  List<Object?> get props => [requestId, reason];
}

class StartScheduledRequestWatch extends CustomerHistoryEvent {
  final String requestId;

  const StartScheduledRequestWatch(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class StopScheduledRequestWatch extends CustomerHistoryEvent {
  const StopScheduledRequestWatch();
}

class ScheduledCountdownTick extends CustomerHistoryEvent {
  const ScheduledCountdownTick();
}

class ScheduledOverdueDetected extends CustomerHistoryEvent {
  const ScheduledOverdueDetected();
}

class ClearScheduledStatusAlert extends CustomerHistoryEvent {
  const ClearScheduledStatusAlert();
}
