import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_bloc.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_event.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_state.dart';
import 'package:homeease/presentation/customer_history/repository/customer_history_repository.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_summary_cards.dart';
import 'package:homeease/presentation/customer_history/widgets/instant_orders_history_tab.dart';
import 'package:homeease/presentation/customer_history/widgets/scheduled_requests_history_tab.dart';

class CustomerHistoryScreen extends StatelessWidget {
  const CustomerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerHistoryBloc(
        repository: CustomerHistoryRepository(),
      )
        ..add(const LoadCustomerHistory())
        ..add(const StartCustomerHistoryRealtime()),
      child: const _CustomerHistoryView(),
    );
  }
}

class _CustomerHistoryView extends StatefulWidget {
  const _CustomerHistoryView();

  @override
  State<_CustomerHistoryView> createState() => _CustomerHistoryViewState();
}

class _CustomerHistoryViewState extends State<_CustomerHistoryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final tab = _tabController.index == 0
        ? CustomerHistoryTab.scheduled
        : CustomerHistoryTab.instant;
    context.read<CustomerHistoryBloc>().add(ChangeCustomerHistoryTab(tab));
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<CustomerHistoryBloc, CustomerHistoryState>(
      listenWhen: (p, c) =>
          c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null &&
            state.status != CustomerHistoryStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (_tabController.index !=
            (state.selectedTab == CustomerHistoryTab.scheduled ? 0 : 1)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _tabController.index =
                state.selectedTab == CustomerHistoryTab.scheduled ? 0 : 1;
          });
        }

        return Column(
          children: [
            CustomerHistorySummaryCards(summary: state.summary),
            Material(
              color: theme.cardColor,
              child: TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.hintColor,
                indicatorColor: theme.colorScheme.primary,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: 'Scheduled Requests'),
                  Tab(text: 'Instant Orders'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  ScheduledRequestsHistoryTab(),
                  InstantOrdersHistoryTab(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
