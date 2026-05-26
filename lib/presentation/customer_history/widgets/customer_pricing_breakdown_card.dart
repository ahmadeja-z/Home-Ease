import 'package:flutter/material.dart';
import 'package:homeease/core/utils/currency_icon.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_section_card.dart';

class CustomerPricingBreakdownCard extends StatelessWidget {
  final ServiceRequestModel order;

  const CustomerPricingBreakdownCard({super.key, required this.order});

  String _money(double? v) {
    if (v == null) return '—';
    return '${CurrencyIcon.currencyIcon}${v.toStringAsFixed(2)}';
  }

  String _formatDateTime(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = order.totalHours ?? 0;
    final rate = order.acceptedPrice ?? order.basePrice ?? 0;
    final computedLabor = rate * hours;
    final labor = order.laborCharges > 0 ? order.laborCharges : computedLabor;
    final finalCalc = labor + order.materialCharges + order.platformFee;

    return CustomerHistorySectionCard(
      title: 'Pricing & invoice',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          _row(theme, 'Base price (per hour)', _money(order.basePrice)),
          _row(theme, 'Accepted price (per hour)', _money(order.acceptedPrice)),
          _row(theme, 'Total hours', hours > 0 ? hours.toStringAsFixed(1) : '—'),
          _row(
            theme,
            'Labor (rate × hours)',
            _money(labor),
            subtitle: rate > 0 && hours > 0
                ? '${_money(rate)} × ${hours.toStringAsFixed(1)}'
                : null,
          ),
          _row(theme, 'Material charges', _money(order.materialCharges)),
          _row(theme, 'Platform fee', _money(order.platformFee)),
          const Divider(height: 20),
          _row(
            theme,
            'Final amount',
            _money(order.finalAmount > 0 ? order.finalAmount : finalCalc),
            bold: true,
          ),
          if (order.finalAmount > 0 && (order.finalAmount - finalCalc).abs() > 0.01)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Formula: labor + material + platform fee',
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          _row(theme, 'Payment status', order.paymentStatus.displayLabel),
          if (order.paymentMethod != null)
            _row(theme, 'Payment method', order.paymentMethod!.value),
          _row(theme, 'Customer paid amount', _money(order.customerPaidAmount)),
          _row(theme, 'Customer paid at', _formatDateTime(order.customerPaidAt)),
        ],
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    String label,
    String value, {
    String? subtitle,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                    fontWeight: bold ? FontWeight.w600 : null,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
