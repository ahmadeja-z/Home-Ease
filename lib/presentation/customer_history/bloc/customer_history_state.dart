import 'package:equatable/equatable.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_event.dart';
import 'package:homeease/presentation/customer_history/models/customer_history_model.dart';

enum CustomerHistoryStatus {
  initial,
  loading,
  loaded,
  loadingMore,
  detailsLoading,
  detailsLoaded,
  reviewSubmitting,
  reviewSubmitted,
  empty,
  scheduledEmpty,
  instantEmpty,
  error,
}

class CustomerHistoryState extends Equatable {
  final CustomerHistoryStatus status;
  final CustomerHistoryTab selectedTab;
  final List<ServiceRequestModel> scheduledRequests;
  final List<ServiceRequestModel> instantRequests;
  final List<ServiceRequestModel> filteredScheduledRequests;
  final List<ServiceRequestModel> filteredInstantRequests;
  final ServiceRequestModel? selectedScheduledRequest;
  final ServiceRequestModel? selectedOrder;
  final CustomerHistorySummary summary;
  final CustomerHistoryFilters scheduledFilters;
  final CustomerHistoryFilters instantFilters;
  final String scheduledSearchQuery;
  final String instantSearchQuery;
  final bool scheduledHasMore;
  final bool instantHasMore;
  final bool isLoadingMore;
  final bool isScheduledLoadingMore;
  final int scheduledOffset;
  final int instantOffset;
  final bool isPayingInvoice;
  final bool isCancellingScheduled;
  final String? errorMessage;
  final String? watchingScheduledRequestId;
  final Duration? countdownRemaining;
  final bool showWorkerNotStartedHint;
  final String? scheduledStatusAlert;

  static const int pageSize = 20;

  const CustomerHistoryState({
    this.status = CustomerHistoryStatus.initial,
    this.selectedTab = CustomerHistoryTab.scheduled,
    this.scheduledRequests = const [],
    this.instantRequests = const [],
    this.filteredScheduledRequests = const [],
    this.filteredInstantRequests = const [],
    this.selectedScheduledRequest,
    this.selectedOrder,
    this.summary = const CustomerHistorySummary(),
    this.scheduledFilters = const CustomerHistoryFilters(),
    this.instantFilters = const CustomerHistoryFilters(),
    this.scheduledSearchQuery = '',
    this.instantSearchQuery = '',
    this.scheduledHasMore = true,
    this.instantHasMore = true,
    this.isLoadingMore = false,
    this.isScheduledLoadingMore = false,
    this.scheduledOffset = 0,
    this.instantOffset = 0,
    this.isPayingInvoice = false,
    this.isCancellingScheduled = false,
    this.errorMessage,
    this.watchingScheduledRequestId,
    this.countdownRemaining,
    this.showWorkerNotStartedHint = false,
    this.scheduledStatusAlert,
  });

  int get selectedTabIndex =>
      selectedTab == CustomerHistoryTab.scheduled ? 0 : 1;

  String get currentSearchQuery => selectedTab == CustomerHistoryTab.scheduled
      ? scheduledSearchQuery
      : instantSearchQuery;

  CustomerHistoryFilters get currentFilters =>
      selectedTab == CustomerHistoryTab.scheduled
          ? scheduledFilters
          : instantFilters;

  int get currentActiveFilterCount => currentFilters.activeFilterCount;

  bool get hasActiveFiltersOnCurrentTab => currentFilters.hasActiveFilters;

  /// Instant tab list (alias for existing instant UI).
  List<ServiceRequestModel> get historyOrders => filteredInstantRequests;

  bool get hasMore => instantHasMore;

  int get currentOffset => instantOffset;

  /// @deprecated Use [scheduledFilters] / [instantFilters].
  CustomerHistoryFilters get filters => currentFilters;

  /// @deprecated Use [currentSearchQuery].
  String get searchQuery => currentSearchQuery;

  bool get hasActiveSearchOrFilters =>
      currentSearchQuery.trim().isNotEmpty || hasActiveFiltersOnCurrentTab;

  CustomerHistoryState copyWith({
    CustomerHistoryStatus? status,
    CustomerHistoryTab? selectedTab,
    List<ServiceRequestModel>? scheduledRequests,
    List<ServiceRequestModel>? instantRequests,
    List<ServiceRequestModel>? filteredScheduledRequests,
    List<ServiceRequestModel>? filteredInstantRequests,
    ServiceRequestModel? selectedScheduledRequest,
    bool clearSelectedScheduled = false,
    ServiceRequestModel? selectedOrder,
    bool clearSelectedOrder = false,
    CustomerHistorySummary? summary,
    CustomerHistoryFilters? scheduledFilters,
    CustomerHistoryFilters? instantFilters,
    String? scheduledSearchQuery,
    String? instantSearchQuery,
    bool? scheduledHasMore,
    bool? instantHasMore,
    bool? isLoadingMore,
    bool? isScheduledLoadingMore,
    int? scheduledOffset,
    int? instantOffset,
    bool? isPayingInvoice,
    bool? isCancellingScheduled,
    String? errorMessage,
    bool clearError = false,
    String? watchingScheduledRequestId,
    bool clearWatching = false,
    Duration? countdownRemaining,
    bool clearCountdown = false,
    bool? showWorkerNotStartedHint,
    String? scheduledStatusAlert,
    bool clearScheduledAlert = false,
    bool clearScheduledFilters = false,
    bool clearInstantFilters = false,
    bool clearScheduledSearch = false,
    bool clearInstantSearch = false,
  }) {
    return CustomerHistoryState(
      status: status ?? this.status,
      selectedTab: selectedTab ?? this.selectedTab,
      scheduledRequests: scheduledRequests ?? this.scheduledRequests,
      instantRequests: instantRequests ?? this.instantRequests,
      filteredScheduledRequests:
          filteredScheduledRequests ?? this.filteredScheduledRequests,
      filteredInstantRequests:
          filteredInstantRequests ?? this.filteredInstantRequests,
      selectedScheduledRequest: clearSelectedScheduled
          ? null
          : (selectedScheduledRequest ?? this.selectedScheduledRequest),
      selectedOrder:
          clearSelectedOrder ? null : (selectedOrder ?? this.selectedOrder),
      summary: summary ?? this.summary,
      scheduledFilters: clearScheduledFilters
          ? const CustomerHistoryFilters()
          : (scheduledFilters ?? this.scheduledFilters),
      instantFilters: clearInstantFilters
          ? const CustomerHistoryFilters()
          : (instantFilters ?? this.instantFilters),
      scheduledSearchQuery: clearScheduledSearch
          ? ''
          : (scheduledSearchQuery ?? this.scheduledSearchQuery),
      instantSearchQuery: clearInstantSearch
          ? ''
          : (instantSearchQuery ?? this.instantSearchQuery),
      scheduledHasMore: scheduledHasMore ?? this.scheduledHasMore,
      instantHasMore: instantHasMore ?? this.instantHasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isScheduledLoadingMore:
          isScheduledLoadingMore ?? this.isScheduledLoadingMore,
      scheduledOffset: scheduledOffset ?? this.scheduledOffset,
      instantOffset: instantOffset ?? this.instantOffset,
      isPayingInvoice: isPayingInvoice ?? this.isPayingInvoice,
      isCancellingScheduled:
          isCancellingScheduled ?? this.isCancellingScheduled,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      watchingScheduledRequestId: clearWatching
          ? null
          : (watchingScheduledRequestId ?? this.watchingScheduledRequestId),
      countdownRemaining: clearCountdown
          ? null
          : (countdownRemaining ?? this.countdownRemaining),
      showWorkerNotStartedHint:
          showWorkerNotStartedHint ?? this.showWorkerNotStartedHint,
      scheduledStatusAlert: clearScheduledAlert
          ? null
          : (scheduledStatusAlert ?? this.scheduledStatusAlert),
    );
  }

  bool get isListLoading =>
      status == CustomerHistoryStatus.loading ||
      status == CustomerHistoryStatus.initial;

  bool get isDetailsLoading => status == CustomerHistoryStatus.detailsLoading;

  bool get isScheduledListLoading =>
      isListLoading && scheduledRequests.isEmpty;

  bool get isInstantListLoading => isListLoading && instantRequests.isEmpty;

  @override
  List<Object?> get props => [
        status,
        selectedTab,
        scheduledRequests,
        instantRequests,
        filteredScheduledRequests,
        filteredInstantRequests,
        selectedScheduledRequest,
        selectedOrder,
        summary,
        scheduledFilters,
        instantFilters,
        scheduledSearchQuery,
        instantSearchQuery,
        scheduledHasMore,
        instantHasMore,
        isLoadingMore,
        isScheduledLoadingMore,
        scheduledOffset,
        instantOffset,
        isPayingInvoice,
        isCancellingScheduled,
        errorMessage,
        watchingScheduledRequestId,
        countdownRemaining,
        showWorkerNotStartedHint,
        scheduledStatusAlert,
      ];
}
