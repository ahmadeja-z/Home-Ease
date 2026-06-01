import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_bloc.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_event.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_state.dart';
import 'package:homeease/presentation/customer_history/repository/customer_history_repository.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_filter_sheets.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_search_toolbar.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_summary_cards.dart';
import 'package:homeease/presentation/customer_history/widgets/instant_orders_history_tab.dart';
import 'package:homeease/presentation/customer_history/widgets/scheduled_requests_history_tab.dart';
import 'package:homeease/presentation/customer_drawer/models/customer_history_drawer_intent.dart';
import 'package:homeease/presentation/navbar/bloc/navbar_bloc.dart';
import 'package:homeease/presentation/navbar/bloc/navbar_event.dart';
import 'package:homeease/presentation/navbar/bloc/navbar_state.dart';

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
  Object? _lastAppliedDrawerToken;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = context.read<NavbarBloc>().state;
      _applyDrawerIntentIfNeeded(
        nav.pendingHistoryIntent,
        nav.drawerNavigationToken,
      );
    });
  }

  void _applyDrawerIntentIfNeeded(
    CustomerHistoryDrawerIntent? intent,
    int token,
  ) {
    if (intent == null || !mounted) return;
    if (_lastAppliedDrawerToken == token) return;

    _lastAppliedDrawerToken = token;
    context.read<NavbarBloc>().add(const ClearDrawerHistoryIntent());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<CustomerHistoryBloc>();
      bloc.add(CustomerHistoryTabChanged(intent.tab));
      if (intent.scheduledFilters != null) {
        bloc.add(ApplyScheduledHistoryFilters(intent.scheduledFilters!));
      }
      if (intent.instantFilters != null) {
        bloc.add(ApplyInstantHistoryFilters(intent.instantFilters!));
      }
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final tab = _tabController.index == 0
        ? CustomerHistoryTab.scheduled
        : CustomerHistoryTab.instant;
    context.read<CustomerHistoryBloc>().add(CustomerHistoryTabChanged(tab));
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
    final colorScheme = theme.colorScheme;

    return BlocListener<NavbarBloc, NavbarState>(
      listenWhen: (p, c) =>
          p.pendingHistoryIntent != c.pendingHistoryIntent &&
          c.pendingHistoryIntent != null,
      listener: (context, state) {
        _applyDrawerIntentIfNeeded(
          state.pendingHistoryIntent,
          state.drawerNavigationToken,
        );
      },
      child: BlocConsumer<CustomerHistoryBloc, CustomerHistoryState>(
      listenWhen: (p, c) =>
          c.errorMessage != null && p.errorMessage != c.errorMessage,
      listener: (context, state) {
        if (state.errorMessage != null &&
            state.status != CustomerHistoryStatus.error) {
          _showPremiumSnackBar(context, state.errorMessage!);
        }
      },
      builder: (context, state) {
        if (_tabController.index !=
            (state.selectedTab == CustomerHistoryTab.scheduled ? 0 : 1)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _tabController.animateTo(
              state.selectedTab == CustomerHistoryTab.scheduled ? 0 : 1,
            );
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Premium Header ──────────────────────────────────────────
            _PremiumHeader(colorScheme: colorScheme),

            // ── Summary Cards ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: CustomerHistorySummaryCards(summary: state.summary),
            ),

            CustomerHistorySearchToolbar(
              onFilterPressed: () {
                if (state.selectedTab == CustomerHistoryTab.scheduled) {
                  showScheduledHistoryFilterSheet(context);
                } else {
                  showInstantHistoryFilterSheet(context);
                }
              },
            ),

            // ── Pill Tab Bar ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _PillTabBar(
                controller: _tabController,
                colorScheme: colorScheme,
              ),
            ),

            // ── Tab Content ─────────────────────────────────────────────
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
      ),
    );
  }

  void _showPremiumSnackBar(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: colorScheme.onPrimary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 0,
      ),
    );
  }
}

// ── Premium Header ─────────────────────────────────────────────────────────────

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My History',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All your requests & orders in one place',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          // Premium badge / avatar area
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.history_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pill Tab Bar ───────────────────────────────────────────────────────────────

class _PillTabBar extends StatelessWidget {
  const _PillTabBar({
    required this.controller,
    required this.colorScheme,
  });

  final TabController controller;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          height: 46,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onPrimary
            ,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              _PillTab(
                label: 'Scheduled Requests',
                icon: Icons.calendar_month_rounded,
                isSelected: controller.index == 0,
                colorScheme: colorScheme,
                onTap: () => controller.animateTo(0),
              ),
              _PillTab(
                label: 'Instant Orders',
                icon: Icons.bolt_rounded,
                isSelected: controller.index == 1,
                colorScheme: colorScheme,
                onTap: () => controller.animateTo(1),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PillTab extends StatelessWidget {
  const _PillTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          height: 40,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface.withValues(alpha: 0.55),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}