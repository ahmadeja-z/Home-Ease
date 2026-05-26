import 'package:flutter/material.dart';
import 'package:homeease/core/utils/currency_icon.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/customer_history/models/customer_history_model.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_status_chip.dart';
import 'package:homeease/presentation/customer_history/widgets/scheduled_request_status_chip.dart';
import 'package:homeease/widgets/app_cache_image.dart';

class ScheduledRequestHistoryCard extends StatelessWidget {
  final ServiceRequestModel request;
  final VoidCallback onTap;

  const ScheduledRequestHistoryCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _formatTime() {
    if (request.preferredTime != null &&
        request.preferredTime!.trim().isNotEmpty) {
      return request.preferredTime!;
    }
    final t = request.scheduledTime;
    if (t == null) return '—';
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title =
        request.serviceTitle ?? request.categoryName ?? 'Scheduled service';
    final worker = request.workerInfo;
    final amount = request.finalAmount > 0
        ? request.finalAmount
        : (request.basePrice ?? 0);
    final thumb = request.customerRequestImages.isNotEmpty
        ? request.customerRequestImages.first
        : request.serviceMainImage;

    return Material(
      color: theme.cardColor,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (thumb != null && thumb.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AppCacheImage(
                        imageUrl: thumb,
                        width: 56,
                        height: 56,
                        boxFit: BoxFit.cover,
                      ),
                    )
                  else
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.event_note_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '#${request.shortRequestId}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 14, color: theme.hintColor),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(
                                request.preferredDate ?? request.scheduledTime,
                              ),
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.access_time,
                                size: 14, color: theme.hintColor),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${CurrencyIcon.currencyIcon}${amount.toStringAsFixed(0)}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        request.pricingType.value,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              if (request.customerAddress != null &&
                  request.customerAddress!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: theme.hintColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        request.customerAddress!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (worker != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Worker: ${worker.name}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] else if (request.status == RequestStatus.pendingAdminApproval ||
                  request.status == RequestStatus.approved) ...[
                const SizedBox(height: 6),
                Text(
                  'No worker assigned yet',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.hintColor,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  ScheduledRequestStatusChip(status: request.status),
                  const SizedBox(width: 6),
                  CustomerHistoryPaymentChip(
                    paymentStatus: request.paymentStatus,
                  ),
                  const Spacer(),
                  Text(
                    'Created ${_formatDate(request.createdAt)}',
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
