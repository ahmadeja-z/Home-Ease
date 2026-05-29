import 'package:flutter/material.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/core/utils/currency_icon.dart';
import 'package:homeease/presentation/customer_history/models/customer_history_model.dart';

class CustomerHistorySummaryCards extends StatelessWidget {
  final CustomerHistorySummary summary;

  const CustomerHistorySummaryCards({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      _SummaryItem(
        icon: Icons.list_alt_rounded,
        label: 'Total',
        value: '${summary.totalRequests}',
        color: AppTheme.mainColor,
      ),
      _SummaryItem(
        icon: Icons.play_circle_outline,
        label: 'Active',
        value: '${summary.activeJobs}',
        color: AppTheme.secondColor,
      ),
      _SummaryItem(
        icon: Icons.check_circle_outline,
        label: 'Completed',
        value: '${summary.completedJobs}',
        color: AppTheme.successColor,
      ),
      _SummaryItem(
        icon: Icons.pending_actions_outlined,
        label: 'Unpaid bills',
        value: '${summary.pendingPayments}',
        color: AppTheme.accentColor,
      ),
      _SummaryItem(
        icon: Icons.payments_outlined,
        label: 'Total spent',
        value:
            '${CurrencyIcon.currencyIcon}${summary.totalSpent.toStringAsFixed(0)}',
        color: AppTheme.mainDarkColor,
      ),
      _SummaryItem(
        icon: Icons.cancel_outlined,
        label: 'Cancelled',
        value: '${summary.cancelledJobs}',
        color: AppTheme.errorColor,
      ),
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            width: 128,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.onSecondary.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: item.color.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.icon, color: item.color, size: 22),
                const Spacer(),
                Text(
                  item.value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: item.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryItem {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}
