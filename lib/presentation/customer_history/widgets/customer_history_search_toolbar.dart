import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_bloc.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_event.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_state.dart';

/// Search bar + filter/clear actions shown above the history tabs.
class CustomerHistorySearchToolbar extends StatefulWidget {
  const CustomerHistorySearchToolbar({
    super.key,
    required this.onFilterPressed,
  });

  final VoidCallback onFilterPressed;

  @override
  State<CustomerHistorySearchToolbar> createState() =>
      _CustomerHistorySearchToolbarState();
}

class _CustomerHistorySearchToolbarState
    extends State<CustomerHistorySearchToolbar> {
  final _controller = TextEditingController();
  Timer? _debounce;
  int _lastTabIndex = -1;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _syncFromState(CustomerHistoryState state) {
    final tabIndex = state.selectedTabIndex;
    final tabChanged = tabIndex != _lastTabIndex;
    _lastTabIndex = tabIndex;
    final query = state.currentSearchQuery;
    if (tabChanged || _controller.text != query) {
      _controller.text = query;
      _controller.selection = TextSelection.collapsed(offset: query.length);
    }
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context
          .read<CustomerHistoryBloc>()
          .add(CustomerHistorySearchChanged(value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<CustomerHistoryBloc, CustomerHistoryState>(
      listenWhen: (p, c) =>
          p.selectedTabIndex != c.selectedTabIndex ||
          p.scheduledSearchQuery != c.scheduledSearchQuery ||
          p.instantSearchQuery != c.instantSearchQuery,
      listener: (context, state) => _syncFromState(state),
      builder: (context, state) {
        _syncFromState(state);
        final filterCount = state.currentActiveFilterCount;
        final hasFilters = filterCount > 0;
        final hasSearch = state.currentSearchQuery.trim().isNotEmpty;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.12),
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.search,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: state.selectedTab ==
                                  CustomerHistoryTab.scheduled
                              ? 'Search scheduled requests…'
                              : 'Search instant orders…',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            size: 22,
                            color: colorScheme.primary.withValues(alpha: 0.85),
                          ),
                          suffixIcon: hasSearch
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: 20,
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  onPressed: () {
                                    _controller.clear();
                                    context.read<CustomerHistoryBloc>().add(
                                          const CustomerHistorySearchChanged(
                                            '',
                                          ),
                                        );
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        onChanged: _onQueryChanged,
                        onSubmitted: (v) {
                          _debounce?.cancel();
                          context.read<CustomerHistoryBloc>().add(
                                CustomerHistorySearchChanged(v),
                              );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _FilterButton(
                    filterCount: filterCount,
                    hasFilters: hasFilters,
                    onPressed: () {
                      context
                          .read<CustomerHistoryBloc>()
                          .add(const CustomerHistoryFilterOpened());
                      widget.onFilterPressed();
                    },
                  ),
                ],
              ),
              if (hasFilters || hasSearch) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (hasFilters)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$filterCount filter${filterCount == 1 ? '' : 's'} active',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => context
                          .read<CustomerHistoryBloc>()
                          .add(const ClearCurrentTabFilters()),
                      icon: Icon(
                        Icons.filter_alt_off_outlined,
                        size: 16,
                        color: colorScheme.error.withValues(alpha: 0.9),
                      ),
                      label: Text(
                        'Clear all',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.error.withValues(alpha: 0.9),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.filterCount,
    required this.hasFilters,
    required this.onPressed,
  });

  final int filterCount;
  final bool hasFilters;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: hasFilters
          ? colorScheme.primary
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 22,
                color: hasFilters
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              if (hasFilters)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      filterCount > 9 ? '9+' : '$filterCount',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onError,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
