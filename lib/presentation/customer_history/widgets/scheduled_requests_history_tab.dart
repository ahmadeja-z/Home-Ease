import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/network/network_failure.dart';
import 'package:homeease/core/widgets/no_internet_widget.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_bloc.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_event.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_state.dart';
import 'package:homeease/presentation/customer_history/screens/scheduled_history_details_screen.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_empty_state.dart';
import 'package:homeease/presentation/customer_history/widgets/scheduled_request_history_card.dart';

class ScheduledRequestsHistoryTab extends StatefulWidget {
  const ScheduledRequestsHistoryTab({super.key});

  @override
  State<ScheduledRequestsHistoryTab> createState() =>
      _ScheduledRequestsHistoryTabState();
}

class _ScheduledRequestsHistoryTabState
    extends State<ScheduledRequestsHistoryTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= max - 200) {
      context
          .read<CustomerHistoryBloc>()
          .add(const LoadMoreScheduledHistory());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerHistoryBloc, CustomerHistoryState>(
      builder: (context, state) {
        final requests = state.filteredScheduledRequests;

        if (state.isScheduledListLoading) {
          return const CustomerHistoryListSkeleton();
        }

        if (state.status == CustomerHistoryStatus.error &&
            state.scheduledRequests.isEmpty) {
          if (isNetworkFailureMessage(state.errorMessage)) {
            return NoInternetWidget(
              onRetry: () => context
                  .read<CustomerHistoryBloc>()
                  .add(const LoadScheduledHistory()),
            );
          }
          return CustomerHistoryErrorState(
            message: state.errorMessage ?? 'Something went wrong',
            onRetry: () => context
                .read<CustomerHistoryBloc>()
                .add(const LoadScheduledHistory()),
          );
        }

        if (requests.isEmpty && state.hasActiveSearchOrFilters) {
          return CustomerHistoryNoResultsState(
            onClearFilters: () => context
                .read<CustomerHistoryBloc>()
                .add(const ClearCurrentTabFilters()),
          );
        }

        if (state.status == CustomerHistoryStatus.scheduledEmpty ||
            requests.isEmpty) {
          return ScheduledHistoryEmptyState(
            onRefresh: () => context
                .read<CustomerHistoryBloc>()
                .add(const LoadScheduledHistory()),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context
                .read<CustomerHistoryBloc>()
                .add(const LoadScheduledHistory());
            await context.read<CustomerHistoryBloc>().stream.firstWhere(
                  (s) =>
                      s.status != CustomerHistoryStatus.loading &&
                      !s.isScheduledListLoading,
                );
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: requests.length +
                (state.isScheduledLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= requests.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final request = requests[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ScheduledRequestHistoryCard(
                  request: request,
                  onTap: () => _openDetails(context, request.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openDetails(BuildContext context, String requestId) {
    final bloc = context.read<CustomerHistoryBloc>();
    bloc.add(LoadScheduledHistoryDetails(requestId));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: ScheduledHistoryDetailsScreen(requestId: requestId),
        ),
      ),
    );
  }
}
