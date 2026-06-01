import 'package:equatable/equatable.dart';

enum CustomerDrawerStatus { initial, loading, loaded, error }

class CustomerDrawerState extends Equatable {
  final CustomerDrawerStatus status;
  final int pendingInvoiceCount;
  final int unreadNotificationCount;

  const CustomerDrawerState({
    this.status = CustomerDrawerStatus.initial,
    this.pendingInvoiceCount = 0,
    this.unreadNotificationCount = 0,
  });

  bool get hasPendingInvoices => pendingInvoiceCount > 0;

  CustomerDrawerState copyWith({
    CustomerDrawerStatus? status,
    int? pendingInvoiceCount,
    int? unreadNotificationCount,
  }) {
    return CustomerDrawerState(
      status: status ?? this.status,
      pendingInvoiceCount: pendingInvoiceCount ?? this.pendingInvoiceCount,
      unreadNotificationCount:
          unreadNotificationCount ?? this.unreadNotificationCount,
    );
  }

  @override
  List<Object?> get props => [
        status,
        pendingInvoiceCount,
        unreadNotificationCount,
      ];
}
