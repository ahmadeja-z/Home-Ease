import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/services/local_notification_service.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_event.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_state.dart';
import 'package:homeease/presentation/customer_history/models/customer_history_model.dart';
import 'package:homeease/presentation/customer_history/repository/customer_history_repository.dart';
import 'package:homeease/presentation/customer_history/utils/scheduled_request_helpers.dart';

class CustomerHistoryBloc
    extends Bloc<CustomerHistoryEvent, CustomerHistoryState> {
  final CustomerHistoryRepository repository;
  StreamSubscription<List<ServiceRequestModel>>? _realtimeSub;
  Timer? _countdownTimer;
  final Map<String, String> _lastNotifiedStatusByRequest = {};

  CustomerHistoryBloc({required this.repository})
      : super(const CustomerHistoryState()) {
    on<LoadCustomerHistory>(_onLoadAll);
    on<LoadScheduledHistory>(_onLoadScheduled);
    on<LoadInstantHistory>(_onLoadInstant);
    on<LoadMoreScheduledHistory>(_onLoadMoreScheduled);
    on<LoadMoreCustomerHistory>(_onLoadMoreInstant);
    on<RefreshCustomerHistory>(_onRefresh);
    on<CustomerHistoryTabChanged>(_onTabChanged);
    on<ChangeCustomerHistoryTab>(_onLegacyTabChanged);
    on<CustomerHistorySearchChanged>(_onSearchChanged);
    on<SearchCustomerHistory>(_onLegacySearch);
    on<ApplyScheduledHistoryFilters>(_onApplyScheduledFilters);
    on<ApplyInstantHistoryFilters>(_onApplyInstantFilters);
    on<ClearCurrentTabFilters>(_onClearCurrentTabFilters);
    on<FilterCustomerHistory>(_onLegacyFilter);
    on<CustomerHistoryFilterOpened>((_, _) {});
    on<LoadCustomerHistoryDetails>(_onLoadInstantDetails);
    on<LoadScheduledHistoryDetails>(_onLoadScheduledDetails);
    on<LoadScheduledRequestDetails>(_onLoadScheduledRequestDetails);
    on<PayScheduledInvoice>(_onPayScheduledInvoice);
    on<CancelScheduledRequest>(_onCancelScheduled);
    on<SubmitCustomerReview>(_onSubmitReview);
    on<CustomerHistoryRealtimeUpdated>(_onRealtimeUpdated);
    on<ScheduledRequestRealtimeUpdated>(_onScheduledRealtimeUpdated);
    on<StartCustomerHistoryRealtime>(_onStartRealtime);
    on<StopCustomerHistoryRealtime>(_onStopRealtime);
    on<StartScheduledRequestWatch>(_onStartWatch);
    on<StopScheduledRequestWatch>(_onStopWatch);
    on<ScheduledCountdownTick>(_onCountdownTick);
    on<ScheduledOverdueDetected>(_onOverdueDetected);
    on<ClearScheduledStatusAlert>(_onClearAlert);
  }

  String? get _customerId => repository.supabase.auth.currentUser?.id;

  Future<void> _onLoadAll(
    LoadCustomerHistory event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    final customerId = _customerId;
    if (customerId == null) {
      emit(state.copyWith(
        status: CustomerHistoryStatus.error,
        errorMessage: 'Please sign in to view your history.',
      ));
      return;
    }

    emit(state.copyWith(
      status: CustomerHistoryStatus.loading,
      clearError: true,
      scheduledOffset: 0,
      instantOffset: 0,
      scheduledHasMore: true,
      instantHasMore: true,
    ));

    try {
      final summary =
          await repository.fetchCustomerHistorySummary(customerId);

      final scheduled = await repository.fetchScheduledHistory(
        customerId: customerId,
        limit: CustomerHistoryState.pageSize,
        offset: 0,
        sort: state.scheduledFilters.sort,
      );

      final instant = await repository.fetchInstantHistory(
        customerId: customerId,
        limit: CustomerHistoryState.pageSize,
        offset: 0,
        sort: state.instantFilters.sort,
      );

      emit(state.copyWith(
        status: _resolveListStatus(scheduled, instant),
        scheduledRequests: scheduled,
        instantRequests: instant,
        filteredScheduledRequests: scheduled,
        filteredInstantRequests: instant,
        summary: summary,
        scheduledOffset: scheduled.length,
        instantOffset: instant.length,
        scheduledHasMore: scheduled.length >= CustomerHistoryState.pageSize,
        instantHasMore: instant.length >= CustomerHistoryState.pageSize,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CustomerHistoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadScheduled(
    LoadScheduledHistory event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    final customerId = _customerId;
    if (customerId == null) return;

    emit(state.copyWith(
      status: CustomerHistoryStatus.loading,
      scheduledOffset: 0,
      scheduledHasMore: true,
      clearError: true,
    ));

    try {
      final scheduled = await _fetchScheduledPage(customerId, offset: 0);

      emit(state.copyWith(
        status: scheduled.isEmpty
            ? CustomerHistoryStatus.scheduledEmpty
            : CustomerHistoryStatus.loaded,
        scheduledRequests: scheduled,
        filteredScheduledRequests: scheduled,
        scheduledOffset: scheduled.length,
        scheduledHasMore: scheduled.length >= CustomerHistoryState.pageSize,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CustomerHistoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadInstant(
    LoadInstantHistory event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    final customerId = _customerId;
    if (customerId == null) return;

    emit(state.copyWith(
      status: CustomerHistoryStatus.loading,
      instantOffset: 0,
      instantHasMore: true,
      clearError: true,
    ));

    try {
      final instant = await _fetchInstantPage(customerId, offset: 0);

      emit(state.copyWith(
        status: instant.isEmpty
            ? CustomerHistoryStatus.instantEmpty
            : CustomerHistoryStatus.loaded,
        instantRequests: instant,
        filteredInstantRequests: instant,
        instantOffset: instant.length,
        instantHasMore: instant.length >= CustomerHistoryState.pageSize,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CustomerHistoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreScheduled(
    LoadMoreScheduledHistory event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    if (!state.scheduledHasMore || state.isScheduledLoadingMore) return;

    final customerId = _customerId;
    if (customerId == null) return;

    emit(state.copyWith(isScheduledLoadingMore: true));

    try {
      final more = await _fetchScheduledPage(
        customerId,
        offset: state.scheduledOffset,
      );

      final merged = _mergeOrders(state.scheduledRequests, more);

      emit(state.copyWith(
        status: merged.isEmpty
            ? CustomerHistoryStatus.scheduledEmpty
            : CustomerHistoryStatus.loaded,
        scheduledRequests: merged,
        filteredScheduledRequests: merged,
        scheduledOffset: state.scheduledOffset + more.length,
        scheduledHasMore: more.length >= CustomerHistoryState.pageSize,
        isScheduledLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isScheduledLoadingMore: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMoreInstant(
    LoadMoreCustomerHistory event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    if (!state.instantHasMore || state.isLoadingMore) return;

    final customerId = _customerId;
    if (customerId == null) return;

    emit(state.copyWith(
      status: CustomerHistoryStatus.loadingMore,
      isLoadingMore: true,
    ));

    try {
      final more = await _fetchInstantPage(
        customerId,
        offset: state.instantOffset,
      );

      final merged = _mergeOrders(state.instantRequests, more);

      emit(state.copyWith(
        status: merged.isEmpty
            ? CustomerHistoryStatus.instantEmpty
            : CustomerHistoryStatus.loaded,
        instantRequests: merged,
        filteredInstantRequests: merged,
        instantOffset: state.instantOffset + more.length,
        instantHasMore: more.length >= CustomerHistoryState.pageSize,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CustomerHistoryStatus.loaded,
        isLoadingMore: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefresh(
    RefreshCustomerHistory event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    if (state.selectedTab == CustomerHistoryTab.scheduled) {
      add(const LoadScheduledHistory());
    } else {
      add(const LoadInstantHistory());
    }
    final customerId = _customerId;
    if (customerId != null) {
      try {
        final summary =
            await repository.fetchCustomerHistorySummary(customerId);
        emit(state.copyWith(summary: summary));
      } catch (_) {}
    }
  }

  Future<void> _onTabChanged(
    CustomerHistoryTabChanged event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    if (state.selectedTab == event.tab) return;

    emit(
      state.copyWith(
        selectedTab: event.tab,
        clearScheduledSearch: event.tab == CustomerHistoryTab.scheduled,
        clearInstantSearch: event.tab == CustomerHistoryTab.instant,
        clearScheduledFilters: event.tab == CustomerHistoryTab.scheduled,
        clearInstantFilters: event.tab == CustomerHistoryTab.instant,
      ),
    );

    if (event.tab == CustomerHistoryTab.scheduled) {
      add(const LoadScheduledHistory());
    } else {
      add(const LoadInstantHistory());
    }
  }

  void _onLegacyTabChanged(
    ChangeCustomerHistoryTab event,
    Emitter<CustomerHistoryState> emit,
  ) {
    add(CustomerHistoryTabChanged(event.tab));
  }

  Future<void> _onSearchChanged(
    CustomerHistorySearchChanged event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    final query = event.query.trim();
    if (state.selectedTab == CustomerHistoryTab.scheduled) {
      emit(state.copyWith(scheduledSearchQuery: query));
      add(const LoadScheduledHistory());
    } else {
      emit(state.copyWith(instantSearchQuery: query));
      add(const LoadInstantHistory());
    }
  }

  void _onLegacySearch(
    SearchCustomerHistory event,
    Emitter<CustomerHistoryState> emit,
  ) {
    add(CustomerHistorySearchChanged(event.query));
  }

  Future<void> _onApplyScheduledFilters(
    ApplyScheduledHistoryFilters event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    emit(state.copyWith(scheduledFilters: event.filters));
    add(const LoadScheduledHistory());
  }

  Future<void> _onApplyInstantFilters(
    ApplyInstantHistoryFilters event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    emit(state.copyWith(instantFilters: event.filters));
    add(const LoadInstantHistory());
  }

  Future<void> _onClearCurrentTabFilters(
    ClearCurrentTabFilters event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    if (state.selectedTab == CustomerHistoryTab.scheduled) {
      emit(state.copyWith(clearScheduledFilters: true, clearScheduledSearch: true));
      add(const LoadScheduledHistory());
    } else {
      emit(state.copyWith(clearInstantFilters: true, clearInstantSearch: true));
      add(const LoadInstantHistory());
    }
  }

  void _onLegacyFilter(
    FilterCustomerHistory event,
    Emitter<CustomerHistoryState> emit,
  ) {
    add(ApplyInstantHistoryFilters(event.filters));
  }

  Future<List<ServiceRequestModel>> _fetchScheduledPage(
    String customerId, {
    required int offset,
  }) {
    final f = state.scheduledFilters;
    final search = state.scheduledSearchQuery;
    return repository.fetchScheduledHistory(
      customerId: customerId,
      limit: CustomerHistoryState.pageSize,
      offset: offset,
      searchQuery: search.isEmpty ? null : search,
      statusFilter: f.statusFilter,
      paymentFilter: f.paymentFilter,
      dateFrom: f.dateFrom,
      dateTo: f.dateTo,
      categoryId: f.categoryId,
      sort: f.sort,
    );
  }

  Future<List<ServiceRequestModel>> _fetchInstantPage(
    String customerId, {
    required int offset,
  }) {
    final f = state.instantFilters;
    final search = state.instantSearchQuery;
    return repository.fetchInstantHistory(
      customerId: customerId,
      limit: CustomerHistoryState.pageSize,
      offset: offset,
      searchQuery: search.isEmpty ? null : search,
      statusFilter: f.statusFilter,
      paymentFilter: f.paymentFilter,
      dateFrom: f.dateFrom,
      dateTo: f.dateTo,
      categoryId: f.categoryId,
      minPrice: f.minPrice,
      maxPrice: f.maxPrice,
      sort: f.sort,
    );
  }

  Future<void> _onLoadInstantDetails(
    LoadCustomerHistoryDetails event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    emit(state.copyWith(
      status: CustomerHistoryStatus.detailsLoading,
      clearSelectedOrder: true,
      clearError: true,
    ));

    try {
      final order =
          await repository.fetchCustomerHistoryDetails(event.requestId);

      emit(state.copyWith(
        status: CustomerHistoryStatus.detailsLoaded,
        selectedOrder: order,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CustomerHistoryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadScheduledRequestDetails(
    LoadScheduledRequestDetails event,
    Emitter<CustomerHistoryState> emit,
  ) =>
      _onLoadScheduledDetails(
        LoadScheduledHistoryDetails(event.requestId),
        emit,
      );

  Future<void> _onScheduledRealtimeUpdated(
    ScheduledRequestRealtimeUpdated event,
    Emitter<CustomerHistoryState> emit,
  ) =>
      _onRealtimeUpdated(
        CustomerHistoryRealtimeUpdated(event.orders),
        emit,
      );

  Future<void> _onLoadScheduledDetails(
    LoadScheduledHistoryDetails event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    _countdownTimer?.cancel();
    emit(state.copyWith(
      status: CustomerHistoryStatus.detailsLoading,
      clearSelectedScheduled: true,
      clearError: true,
      clearWatching: true,
      clearCountdown: true,
      showWorkerNotStartedHint: false,
    ));

    try {
      final order =
          await repository.fetchScheduledHistoryDetails(event.requestId);

      emit(state.copyWith(
        status: CustomerHistoryStatus.detailsLoaded,
        selectedScheduledRequest: order,
      ));
      add(StartScheduledRequestWatch(event.requestId));
    } catch (e) {
      emit(state.copyWith(
        status: CustomerHistoryStatus.error,
        clearSelectedScheduled: true,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onCancelScheduled(
    CancelScheduledRequest event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    final current = state.selectedScheduledRequest;
    if (current != null && !current.canCustomerCancelScheduled) {
      emit(state.copyWith(
        errorMessage: 'This request can no longer be cancelled.',
      ));
      return;
    }

    emit(state.copyWith(isCancellingScheduled: true, clearError: true));

    try {
      final updated = await repository.cancelScheduledRequest(
        requestId: event.requestId,
        reason: event.reason,
      );

      final list = state.scheduledRequests
          .map((o) => o.id == event.requestId ? updated : o)
          .toList();
      final filtered = state.filteredScheduledRequests
          .map((o) => o.id == event.requestId ? updated : o)
          .toList();

      emit(state.copyWith(
        isCancellingScheduled: false,
        selectedScheduledRequest: updated,
        scheduledRequests: list,
        filteredScheduledRequests: filtered,
        status: CustomerHistoryStatus.detailsLoaded,
        scheduledStatusAlert: 'Your scheduled request was cancelled.',
      ));
      add(const StopScheduledRequestWatch());
    } catch (e) {
      emit(state.copyWith(
        isCancellingScheduled: false,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onStartWatch(
    StartScheduledRequestWatch event,
    Emitter<CustomerHistoryState> emit,
  ) {
    _countdownTimer?.cancel();
    emit(state.copyWith(
      watchingScheduledRequestId: event.requestId,
      clearCountdown: true,
      showWorkerNotStartedHint: false,
    ));
    add(const ScheduledCountdownTick());
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => add(const ScheduledCountdownTick()),
    );
  }

  void _onStopWatch(
    StopScheduledRequestWatch event,
    Emitter<CustomerHistoryState> emit,
  ) {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    emit(state.copyWith(clearWatching: true, clearCountdown: true));
  }

  void _onCountdownTick(
    ScheduledCountdownTick event,
    Emitter<CustomerHistoryState> emit,
  ) {
    final request = state.selectedScheduledRequest;
    if (request == null ||
        state.watchingScheduledRequestId != request.id) {
      return;
    }

    final remaining = ScheduledRequestHelpers.timeUntilScheduled(request);
    final notStarted =
        ScheduledRequestHelpers.shouldShowNotStartedWarning(request);

    emit(state.copyWith(
      countdownRemaining: remaining,
      showWorkerNotStartedHint: notStarted,
    ));

    if (notStarted &&
        request.status == RequestStatus.accepted &&
        !hasWorkerStartedTrip(request)) {
      add(const ScheduledOverdueDetected());
    }
  }

  bool hasWorkerStartedTrip(ServiceRequestModel request) =>
      ScheduledRequestHelpers.hasWorkerStartedTrip(request);

  void _onOverdueDetected(
    ScheduledOverdueDetected event,
    Emitter<CustomerHistoryState> emit,
  ) {
    final request = state.selectedScheduledRequest;
    if (request == null) return;
    if (request.status == RequestStatus.overdue ||
        request.status == RequestStatus.workerNoShow) {
      return;
    }
    emit(state.copyWith(
      scheduledStatusAlert:
          'Worker has not started yet. Admin is monitoring this request.',
    ));
  }

  void _onClearAlert(
    ClearScheduledStatusAlert event,
    Emitter<CustomerHistoryState> emit,
  ) {
    emit(state.copyWith(clearScheduledAlert: true));
  }

  Future<void> _onPayScheduledInvoice(
    PayScheduledInvoice event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    emit(state.copyWith(isPayingInvoice: true, clearError: true));

    try {
      final updated = await repository.payScheduledInvoice(event.requestId);

      final scheduledList = state.scheduledRequests
          .map((o) => o.id == event.requestId ? updated : o)
          .toList();
      final filteredScheduled = state.filteredScheduledRequests
          .map((o) => o.id == event.requestId ? updated : o)
          .toList();

      final selected = state.selectedScheduledRequest?.id == event.requestId
          ? updated
          : state.selectedScheduledRequest;

      emit(state.copyWith(
        isPayingInvoice: false,
        scheduledRequests: scheduledList,
        filteredScheduledRequests: filteredScheduled,
        selectedScheduledRequest: selected,
        status: CustomerHistoryStatus.detailsLoaded,
      ));
    } catch (e) {
      emit(state.copyWith(
        isPayingInvoice: false,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onSubmitReview(
    SubmitCustomerReview event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    emit(state.copyWith(status: CustomerHistoryStatus.reviewSubmitting));

    try {
      await repository.submitReview(
        requestId: event.requestId,
        rating: event.rating,
        review: event.review,
      );

      final updated = state.selectedOrder?.copyWith(
        rating: event.rating,
        review: event.review,
      );

      final list = state.instantRequests.map((o) {
        if (o.id == event.requestId) {
          return o.copyWith(rating: event.rating, review: event.review);
        }
        return o;
      }).toList();
      final filtered = state.filteredInstantRequests.map((o) {
        if (o.id == event.requestId) {
          return o.copyWith(rating: event.rating, review: event.review);
        }
        return o;
      }).toList();

      emit(state.copyWith(
        status: CustomerHistoryStatus.reviewSubmitted,
        selectedOrder: updated,
        instantRequests: list,
        filteredInstantRequests: filtered,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CustomerHistoryStatus.detailsLoaded,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRealtimeUpdated(
    CustomerHistoryRealtimeUpdated event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    await _applyRealtime(emit, event.orders.cast<ServiceRequestModel>());
  }

  Future<void> _onStartRealtime(
    StartCustomerHistoryRealtime event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    final customerId = _customerId;
    if (customerId == null) return;

    await _realtimeSub?.cancel();
    _realtimeSub = repository
        .subscribeCustomerHistoryUpdates(customerId)
        .listen(
      (orders) => add(CustomerHistoryRealtimeUpdated(orders)),
      onError: (Object e) {
        if (kDebugMode) {
          print('CustomerHistoryBloc realtime error: $e');
        }
      },
    );
  }

  Future<void> _onStopRealtime(
    StopCustomerHistoryRealtime event,
    Emitter<CustomerHistoryState> emit,
  ) async {
    await _realtimeSub?.cancel();
    _realtimeSub = null;
  }

  Future<void> _applyRealtime(
    Emitter<CustomerHistoryState> emit,
    List<ServiceRequestModel> streamOrders,
  ) async {
    final customerId = _customerId;
    if (customerId == null) return;

    try {
      final summary =
          await repository.fetchCustomerHistorySummary(customerId);

      final scheduledStream = streamOrders.where(_isScheduledRequest).toList();
      final instantStream = streamOrders.where(_isInstantRequest).toList();

      final scheduledMerged = _mergeRealtimeList(
        state.scheduledRequests,
        scheduledStream,
        _matchesScheduledFilters,
      );
      final instantMerged = _mergeRealtimeList(
        state.instantRequests,
        instantStream,
        _matchesInstantFilters,
      );

      final filteredScheduled = _filterScheduledList(scheduledMerged);
      final filteredInstant = _filterInstantList(instantMerged);

      var selectedScheduled = state.selectedScheduledRequest;
      String? alert;
      if (selectedScheduled != null) {
        final previous = selectedScheduled;
        selectedScheduled = streamOrders
                .where((o) => o.id == selectedScheduled!.id)
                .firstOrNull ??
            selectedScheduled;
        alert = _detectScheduledAlert(previous, selectedScheduled);
        await _maybeNotifyScheduledChange(previous, selectedScheduled);
      }

      var selectedInstant = state.selectedOrder;
      if (selectedInstant != null) {
        selectedInstant =
            streamOrders.where((o) => o.id == selectedInstant!.id).firstOrNull ??
                selectedInstant;
      }

      emit(state.copyWith(
        summary: summary,
        scheduledRequests:
            _sortOrders(scheduledMerged, state.scheduledFilters.sort),
        instantRequests: _sortOrders(instantMerged, state.instantFilters.sort),
        filteredScheduledRequests:
            _sortOrders(filteredScheduled, state.scheduledFilters.sort),
        filteredInstantRequests:
            _sortOrders(filteredInstant, state.instantFilters.sort),
        selectedScheduledRequest: selectedScheduled,
        selectedOrder: selectedInstant,
        status: _resolveListStatus(filteredScheduled, filteredInstant),
        scheduledStatusAlert: alert ?? state.scheduledStatusAlert,
      ));
    } catch (_) {}
  }

  bool _isScheduledRequest(ServiceRequestModel o) =>
      o.bookingType == RequestType.scheduled &&
      o.requestFlow == RequestFlow.adminAssign;

  bool _isInstantRequest(ServiceRequestModel o) =>
      o.bookingType == RequestType.instant &&
      o.requestFlow == RequestFlow.directWorker;

  bool _matchesScheduledFilters(ServiceRequestModel o) {
    if (!_isScheduledRequest(o)) return false;
    final f = state.scheduledFilters;
    if (f.statusFilter != null && o.status.value != f.statusFilter) {
      return false;
    }
    if (f.paymentFilter != null &&
        o.paymentStatus.value != f.paymentFilter) {
      return false;
    }
    if (f.categoryId != null && o.categoryId != f.categoryId) return false;
    if (state.scheduledSearchQuery.isNotEmpty &&
        !_matchesSearchQuery(o, state.scheduledSearchQuery)) {
      return false;
    }
    return true;
  }

  List<ServiceRequestModel> _filterScheduledList(
    List<ServiceRequestModel> orders,
  ) {
    if (!state.scheduledFilters.hasActiveFilters &&
        state.scheduledSearchQuery.trim().isEmpty) {
      return orders;
    }
    return orders.where(_matchesScheduledFilters).toList();
  }

  List<ServiceRequestModel> _filterInstantList(
    List<ServiceRequestModel> orders,
  ) {
    if (!state.instantFilters.hasActiveFilters &&
        state.instantSearchQuery.trim().isEmpty) {
      return orders;
    }
    return orders.where(_matchesInstantFilters).toList();
  }

  bool _matchesSearchQuery(ServiceRequestModel o, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return o.id.toLowerCase().contains(q) ||
        o.shortRequestId.toLowerCase().contains(q) ||
        (o.categoryName ?? '').toLowerCase().contains(q) ||
        (o.serviceTitle ?? '').toLowerCase().contains(q) ||
        (o.customerAddress ?? '').toLowerCase().contains(q) ||
        (o.workerInfo?.name ?? '').toLowerCase().contains(q) ||
        (o.description ?? '').toLowerCase().contains(q);
  }

  List<ServiceRequestModel> _mergeRealtimeList(
    List<ServiceRequestModel> current,
    List<ServiceRequestModel> stream,
    bool Function(ServiceRequestModel)? includeNew,
  ) {
    final byId = {for (final o in stream) o.id: o};
    final merged = current.map((o) => byId[o.id] ?? o).toList();

    for (final o in stream) {
      if (!merged.any((e) => e.id == o.id)) {
        if (includeNew == null || includeNew(o)) {
          merged.insert(0, o);
        }
      }
    }
    return merged;
  }

  bool _matchesInstantFilters(ServiceRequestModel o) {
    if (!_isInstantRequest(o)) return false;
    final f = state.instantFilters;
    if (f.statusFilter != null && o.status.value != f.statusFilter) {
      return false;
    }
    if (f.paymentFilter != null &&
        o.paymentStatus.value != f.paymentFilter) {
      return false;
    }
    if (f.categoryId != null && o.categoryId != f.categoryId) return false;
    if (f.minPrice != null && o.displayAmount < f.minPrice!) return false;
    if (f.maxPrice != null && o.displayAmount > f.maxPrice!) return false;
    if (state.instantSearchQuery.isNotEmpty &&
        !_matchesSearchQuery(o, state.instantSearchQuery)) {
      return false;
    }
    return true;
  }

  CustomerHistoryStatus _resolveListStatus(
    List<ServiceRequestModel> scheduled,
    List<ServiceRequestModel> instant,
  ) {
    if (scheduled.isEmpty && instant.isEmpty) {
      return CustomerHistoryStatus.empty;
    }
    return CustomerHistoryStatus.loaded;
  }

  List<ServiceRequestModel> _mergeOrders(
    List<ServiceRequestModel> current,
    List<ServiceRequestModel> more,
  ) {
    final ids = current.map((e) => e.id).toSet();
    final merged = [...current];
    for (final order in more) {
      if (!ids.contains(order.id)) {
        merged.add(order);
        ids.add(order.id);
      }
    }
    return merged;
  }

  List<ServiceRequestModel> _sortOrders(
    List<ServiceRequestModel> orders,
    CustomerHistorySort sort,
  ) {
    final copy = [...orders];
    switch (sort) {
      case CustomerHistorySort.oldest:
        copy.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case CustomerHistorySort.highestAmount:
        copy.sort((a, b) => b.displayAmount.compareTo(a.displayAmount));
        break;
      case CustomerHistorySort.newest:
        copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return copy;
  }

  String? _detectScheduledAlert(
    ServiceRequestModel previous,
    ServiceRequestModel current,
  ) {
    if (previous.status == current.status &&
        previous.workerId == current.workerId) {
      return null;
    }

    switch (current.status) {
      case RequestStatus.overdue:
        return 'Update: Your scheduled worker is late.';
      case RequestStatus.workerNoShow:
        return 'Update: Worker did not attend your scheduled job.';
      case RequestStatus.reassigned:
        return 'Update: Your request was reassigned to another worker.';
      case RequestStatus.assigned:
        if (previous.workerId != null &&
            current.workerId != null &&
            previous.workerId != current.workerId) {
          return 'Update: A new worker has been assigned to your request.';
        }
        if (previous.status == RequestStatus.reassigned) {
          return 'A new worker has been assigned to your request.';
        }
        return 'A worker has been assigned to your scheduled job.';
      case RequestStatus.accepted:
        return 'Your worker accepted the scheduled job.';
      case RequestStatus.workerOnTheWay:
        return 'Your worker is on the way.';
      case RequestStatus.billGenerated:
        return 'Invoice is ready for your scheduled service.';
      case RequestStatus.cancelled:
        return 'This scheduled request was cancelled.';
      case RequestStatus.rejected:
        return 'This scheduled request was rejected by admin.';
      default:
        return null;
    }
  }

  Future<void> _maybeNotifyScheduledChange(
    ServiceRequestModel previous,
    ServiceRequestModel current,
  ) async {
    if (!_isScheduledRequest(current)) return;

    final key = '${current.id}:${current.status.value}:${current.workerId ?? ''}';
    if (_lastNotifiedStatusByRequest[current.id] == key) return;
    _lastNotifiedStatusByRequest[current.id] = key;

    if (previous.status == current.status &&
        previous.workerId == current.workerId) {
      return;
    }

    final body = ScheduledRequestHelpers.notificationMessageForStatus(
      current.status,
      workerName: current.workerInfo?.name,
    );
    if (body == null) return;

    try {
      await LocalNotificationService().showNotification(
        id: current.id.hashCode,
        title: 'Scheduled service update',
        body: body,
        payload: '{"type":"scheduled_request","request_id":"${current.id}"}',
      );
    } catch (e) {
      if (kDebugMode) {
        print('CustomerHistoryBloc notification error: $e');
      }
    }
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    _countdownTimer?.cancel();
    return super.close();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
