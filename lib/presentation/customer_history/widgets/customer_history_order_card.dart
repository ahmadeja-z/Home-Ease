import 'package:flutter/material.dart';
import 'package:homeease/core/utils/currency_icon.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/customer_history/models/customer_history_model.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_status_chip.dart';
import 'package:homeease/widgets/app_cache_image.dart';

class CustomerHistoryOrderCard extends StatelessWidget {
  final ServiceRequestModel order;
  final VoidCallback onTap;

  const CustomerHistoryOrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final worker = order.workerInfo;
    final displayDate = order.completedAt ?? order.createdAt;

    return Material(
      color: theme.cardColor,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (worker != null)
                    AppCacheImage(
                      imageUrl: worker.profileImage ?? '',
                      width: 44,
                      height: 44,
                      round: 22,
                      boxFit: BoxFit.cover,
                    )
                  else
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.person_outline,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.categoryName ?? 'Service request',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '#${order.shortRequestId}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (worker != null)
                          Text(
                            worker.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${CurrencyIcon.currencyIcon}${order.displayAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (order.hasReview)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            Text(
                              order.rating!.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (order.customerAddress != null &&
                  order.customerAddress!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: theme.hintColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.customerAddress!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  CustomerHistoryStatusChip(status: order.status),
                  const SizedBox(width: 6),
                  CustomerHistoryPaymentChip(paymentStatus: order.paymentStatus),
                  const Spacer(),
                  Text(
                    _formatDate(displayDate),
                    style: theme.textTheme.bodySmall,
                  ),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
