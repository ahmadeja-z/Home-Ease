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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  String _formatTime() {
    if (request.preferredTime != null &&
        request.preferredTime!.trim().isNotEmpty) {
      return request.preferredTime!;
    }
    final t = request.scheduledTime;
    if (t == null) return '—';
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final title =
        request.serviceTitle ?? request.categoryName ?? 'Scheduled service';
    final worker = request.workerInfo;
    final amount = request.finalAmount > 0
        ? request.finalAmount
        : (request.basePrice ?? 0);
    final thumb = request.customerRequestImages.isNotEmpty
        ? request.customerRequestImages.first
        : request.serviceMainImage;

    final bool isNoWorker =
        request.status == RequestStatus.pendingAdminApproval ||
            request.status == RequestStatus.approved;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: cs.primary.withValues(alpha:0.06),
        highlightColor: cs.primary.withValues(alpha:0.03),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onPrimary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSecondary.withValues(alpha:0.5),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Section ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail / Icon
                    _ServiceThumbnail(
                      thumb: thumb,
                      colorScheme: cs,
                    ),
                    const SizedBox(width: 14),

                    // Title + meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
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
                            '#${request.shortRequestId}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha:0.4),
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Date + Time row
                          Row(
                            children: [
                              _MetaChip(
                                icon: Icons.calendar_today_rounded,
                                label: _formatDate(
                                  request.preferredDate ??
                                      request.scheduledTime,
                                ),
                                colorScheme: cs,
                                theme: theme,
                              ),
                              const SizedBox(width: 6),
                              _MetaChip(
                                icon: Icons.access_time_rounded,
                                label: _formatTime(),
                                colorScheme: cs,
                                theme: theme,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${CurrencyIcon.currencyIcon}${amount.toStringAsFixed(0)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          request.pricingType.value,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha:0.4),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Divider ─────────────────────────────────────────────
              Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha:0.3),
                indent: 16,
                endIndent: 16,
              ),

              // ── Meta Row (address + worker) ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (request.customerAddress != null &&
                        request.customerAddress!.isNotEmpty)
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: request.customerAddress!,
                        colorScheme: cs,
                        theme: theme,
                        maxLines: 1,
                      ),
                    if (worker != null) ...[
                      if (request.customerAddress != null &&
                          request.customerAddress!.isNotEmpty)
                        const SizedBox(height: 5),
                      _InfoRow(
                        icon: Icons.person_outline_rounded,
                        text: worker.name,
                        colorScheme: cs,
                        theme: theme,
                        bold: true,
                      ),
                    ] else if (isNoWorker) ...[
                      if (request.customerAddress != null &&
                          request.customerAddress!.isNotEmpty)
                        const SizedBox(height: 5),
                      _InfoRow(
                        icon: Icons.person_search_rounded,
                        text: 'Assigning worker…',
                        colorScheme: cs,
                        theme: theme,
                        italic: true,
                        muted: true,
                      ),
                    ],
                  ],
                ),
              ),

              // ── Divider ─────────────────────────────────────────────
              Divider(
                height: 1,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha:0.3),
                indent: 16,
                endIndent: 16,
              ),

              // ── Footer ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
                child: Row(
                  children: [
                    ScheduledRequestStatusChip(status: request.status),
                    const SizedBox(width: 6),
                    CustomerHistoryPaymentChip(
                      paymentStatus: request.paymentStatus,
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(request.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha:0.4),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: cs.onSurface.withValues(alpha:0.35),
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

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _ServiceThumbnail extends StatelessWidget {
  const _ServiceThumbnail({
    required this.thumb,
    required this.colorScheme,
  });

  final String? thumb;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (thumb != null && thumb!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AppCacheImage(
          imageUrl: thumb!,
          width: 58,
          height: 58,
          boxFit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.event_note_rounded,
        color: colorScheme.primary,
        size: 26,
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha:0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: colorScheme.onSurface.withValues(alpha:0.5)),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: colorScheme.onSurface.withValues(alpha:0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    required this.colorScheme,
    required this.theme,
    this.maxLines = 2,
    this.bold = false,
    this.italic = false,
    this.muted = false,
  });

  final IconData icon;
  final String text;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final int maxLines;
  final bool bold;
  final bool italic;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icon,
            size: 13,
            color: muted
                ? colorScheme.onSurface.withValues(alpha:0.3)
                : colorScheme.onSurface.withValues(alpha:0.45),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: muted
                  ? colorScheme.onSurface.withValues(alpha:0.38)
                  : colorScheme.onSurface.withValues(alpha:0.65),
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              fontSize: 12,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}