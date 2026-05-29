import 'package:equatable/equatable.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/customer_history/utils/scheduled_request_helpers.dart';

enum CustomerHistorySort {
  newest,
  oldest,
  highestAmount,
}

class CustomerHistoryFilters extends Equatable {
  final String? statusFilter;
  final String? paymentFilter;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final CustomerHistorySort sort;

  const CustomerHistoryFilters({
    this.statusFilter,
    this.paymentFilter,
    this.dateFrom,
    this.dateTo,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.sort = CustomerHistorySort.newest,
  });

  CustomerHistoryFilters copyWith({
    String? statusFilter,
    String? paymentFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    CustomerHistorySort? sort,
    bool clearStatus = false,
    bool clearPayment = false,
    bool clearDates = false,
    bool clearCategory = false,
    bool clearPrice = false,
  }) {
    return CustomerHistoryFilters(
      statusFilter: clearStatus ? null : (statusFilter ?? this.statusFilter),
      paymentFilter:
          clearPayment ? null : (paymentFilter ?? this.paymentFilter),
      dateFrom: clearDates ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDates ? null : (dateTo ?? this.dateTo),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      sort: sort ?? this.sort,
    );
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  int get activeFilterCount {
    var count = 0;
    if (statusFilter != null) count++;
    if (paymentFilter != null) count++;
    if (dateFrom != null || dateTo != null) count++;
    if (categoryId != null) count++;
    if (minPrice != null || maxPrice != null) count++;
    return count;
  }

  @override
  List<Object?> get props => [
        statusFilter,
        paymentFilter,
        dateFrom,
        dateTo,
        categoryId,
        minPrice,
        maxPrice,
        sort,
      ];
}

class CustomerHistorySummary extends Equatable {
  final int totalRequests;
  final int activeJobs;
  final int completedJobs;
  final int pendingPayments;
  final double totalSpent;
  final int cancelledJobs;

  const CustomerHistorySummary({
    this.totalRequests = 0,
    this.activeJobs = 0,
    this.completedJobs = 0,
    this.pendingPayments = 0,
    this.totalSpent = 0,
    this.cancelledJobs = 0,
  });

  @override
  List<Object?> get props => [
        totalRequests,
        activeJobs,
        completedJobs,
        pendingPayments,
        totalSpent,
        cancelledJobs,
      ];
}

/// List + details use [ServiceRequestModel]; helpers for UI.
extension CustomerHistoryOrderX on ServiceRequestModel {
  String get shortRequestId {
    if (id.length <= 8) return id.toUpperCase();
    return id.substring(id.length - 8).toUpperCase();
  }

  double get displayAmount =>
      finalAmount > 0 ? finalAmount : (basePrice ?? estimatedPrice ?? 0);

  bool get isActiveJob => const {
        RequestStatus.pending,
        RequestStatus.pendingAdminApproval,
        RequestStatus.approved,
        RequestStatus.assigned,
        RequestStatus.accepted,
        RequestStatus.workerOnTheWay,
        RequestStatus.arrived,
        RequestStatus.inProgress,
        RequestStatus.billGenerated,
        RequestStatus.overdue,
        RequestStatus.reassigned,
      }.contains(status);

  bool get isScheduledBooking =>
      bookingType == RequestType.scheduled &&
      requestFlow == RequestFlow.adminAssign;

  bool get canCustomerCancelScheduled =>
      ScheduledRequestHelpers.canCustomerCancel(this);

  bool get isPendingPayment =>
      status == RequestStatus.billGenerated &&
      paymentStatus == PaymentStatus.unpaid;

  bool get hasReview => rating != null && rating! > 0;

  bool get canSubmitReview =>
      status == RequestStatus.completed &&
      paymentStatus == PaymentStatus.paid &&
      !hasReview;
}
