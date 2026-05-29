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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final worker = order.workerInfo;
    final displayDate = order.completedAt ?? order.createdAt;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: cs.primary.withValues(alpha: 0.06),
        highlightColor: cs.primary.withValues(alpha: 0.03),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top section ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Worker avatar
                    _WorkerAvatar(worker: worker, cs: cs),
                    const SizedBox(width: 14),

                    // Title + ID + worker name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.categoryName ?? 'Service request',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                              letterSpacing: -0.2,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '#${order.shortRequestId}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.4),
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                          if (worker != null) ...[
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  size: 12,
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    worker.name,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface.withValues(alpha: 0.7),
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Amount + rating
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${CurrencyIcon.currencyIcon}${order.displayAmount.toStringAsFixed(0)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                            fontSize: 16,
                          ),
                        ),
                        if (order.hasReview) ...[
                          const SizedBox(height: 4),
                          _StarRating(rating: order.rating!, cs: cs),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // ── Divider ───────────────────────────────────────────────
              Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha: 0.3),
                indent: 16,
                endIndent: 16,
              ),

              // ── Address row ───────────────────────────────────────────
              if (order.customerAddress != null &&
                  order.customerAddress!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          order.customerAddress!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.3),
                  indent: 16,
                  endIndent: 16,
                ),
              ],

              // ── Footer ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
                child: Row(
                  children: [
                    CustomerHistoryStatusChip(status: order.status),
                    const SizedBox(width: 6),
                    CustomerHistoryPaymentChip(
                        paymentStatus: order.paymentStatus),
                    const Spacer(),
                    Text(
                      _formatDate(displayDate),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Worker Avatar ──────────────────────────────────────────────────────────────

class _WorkerAvatar extends StatelessWidget {
  const _WorkerAvatar({required this.worker, required this.cs});

  final dynamic worker;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    if (worker != null && (worker.profileImage ?? '').isNotEmpty) {
      return AppCacheImage(
        imageUrl: worker.profileImage!,
        width: 52,
        height: 52,
        round: 26,
        boxFit: BoxFit.cover,
      );
    }

    // Initials fallback
    final initials = worker != null && (worker.name as String).isNotEmpty
        ? (worker.name as String)
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : '?';

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.primary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ── Star Rating ────────────────────────────────────────────────────────────────

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating, required this.cs});

  final double rating;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 12, color: cs.onTertiaryContainer),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: cs.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}