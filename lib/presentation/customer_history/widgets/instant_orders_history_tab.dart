import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/network/network_failure.dart';
import 'package:homeease/core/widgets/no_internet_widget.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_bloc.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_event.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_state.dart';
import 'package:homeease/presentation/customer_history/screens/customer_history_details_screen.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_empty_state.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_order_card.dart';

/// Instant orders tab — list, pagination, and pull-to-refresh.
class InstantOrdersHistoryTab extends StatefulWidget {
  const InstantOrdersHistoryTab({super.key});

  @override
  State<InstantOrdersHistoryTab> createState() => _InstantOrdersHistoryTabState();
}

class _InstantOrdersHistoryTabState extends State<InstantOrdersHistoryTab> {
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
      context.read<CustomerHistoryBloc>().add(const LoadMoreCustomerHistory());
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
        final orders = state.filteredInstantRequests;

        if (state.isInstantListLoading) {
          return const CustomerHistoryListSkeleton();
        }
        if (state.status == CustomerHistoryStatus.error &&
            state.instantRequests.isEmpty) {
          if (isNetworkFailureMessage(state.errorMessage)) {
            return NoInternetWidget(
              onRetry: () => context
                  .read<CustomerHistoryBloc>()
                  .add(const LoadInstantHistory()),
            );
          }
          return CustomerHistoryErrorState(
            message: state.errorMessage ?? 'Something went wrong',
            onRetry: () => context
                .read<CustomerHistoryBloc>()
                .add(const LoadInstantHistory()),
          );
        }
        if (orders.isEmpty && state.hasActiveSearchOrFilters) {
          return CustomerHistoryNoResultsState(
            onClearFilters: () => context
                .read<CustomerHistoryBloc>()
                .add(const ClearCurrentTabFilters()),
          );
        }
        if (state.status == CustomerHistoryStatus.instantEmpty ||
            (orders.isEmpty &&
                state.status != CustomerHistoryStatus.loadingMore)) {
          return CustomerHistoryEmptyState(
            onRefresh: () => context
                .read<CustomerHistoryBloc>()
                .add(const LoadInstantHistory()),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<CustomerHistoryBloc>().add(const LoadInstantHistory());
            await context.read<CustomerHistoryBloc>().stream.firstWhere(
                  (s) =>
                      s.status != CustomerHistoryStatus.loading &&
                      !s.isInstantListLoading,
                );
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: orders.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= orders.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final order = orders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CustomerHistoryOrderCard(
                  order: order,
                  onTap: () => _openDetails(context, order.id),
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
    bloc.add(LoadCustomerHistoryDetails(requestId));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: CustomerHistoryDetailsScreen(requestId: requestId),
        ),
      ),
    );
  }
}
