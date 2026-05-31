import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/utils/CallAndWhatsAppUtils.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_bloc.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_event.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_state.dart';
import 'package:homeease/presentation/customer_history/models/customer_history_model.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_completion_images_grid.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_status_chip.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_timeline.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_pricing_breakdown_card.dart';
import 'package:homeease/widgets/app_cache_image.dart';
import 'package:homeease/widgets/custom_app_bar.dart';

const _hPad = EdgeInsets.symmetric(horizontal: 16);

class CustomerHistoryDetailsScreen extends StatelessWidget {
  final String requestId;

  const CustomerHistoryDetailsScreen({super.key, required this.requestId});

  String _formatDateTime(DateTime? d) {
    if (d == null) return '—';
    final local = d.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${local.day} ${months[local.month - 1]} ${local.year}  $h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: CustomAppBar(title: 'Order Details'),
      body: BlocBuilder<CustomerHistoryBloc, CustomerHistoryState>(
        buildWhen: (p, c) =>
            p.selectedOrder != c.selectedOrder || p.status != c.status,
        builder: (context, state) {
          final order = state.selectedOrder;
          final isTargetLoaded = order != null && order.id == requestId;

          if (!isTargetLoaded) {
            final showError = !state.isDetailsLoading &&
                state.status == CustomerHistoryStatus.error;

            if (showError) {
              return _ErrorView(
                onRetry: () => context
                    .read<CustomerHistoryBloc>()
                    .add(LoadCustomerHistoryDetails(requestId)),
              );
            }

            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero header ────────────────────────────────────────
                _HeroHeader(order: order),
                const SizedBox(height: 20),

                // ── Request details ────────────────────────────────────
                Padding(
                  padding: _hPad,
                  child: _SectionLabel(
                    icon: Icons.info_outline_rounded,
                    label: 'Request details',
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: _hPad,
                  child: _RequestDetailsCard(
                    order: order,
                    formatDate: _formatDateTime,
                    cs: cs,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Worker ─────────────────────────────────────────────
                Padding(
                  padding: _hPad,
                  child: _SectionLabel(
                    icon: Icons.engineering_rounded,
                    label: 'Assigned worker',
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: _hPad,
                  child: _WorkerCard(order: order, cs: cs),
                ),
                const SizedBox(height: 20),

                // ── Timeline ───────────────────────────────────────────
                Padding(
                  padding: _hPad,
                  child: _SectionLabel(
                    icon: Icons.timeline_rounded,
                    label: 'Order timeline',
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: _hPad,
                  child: CustomerHistoryTimeline(order: order),
                ),
                const SizedBox(height: 20),

                // ── Pricing ────────────────────────────────────────────
                Padding(
                  padding: _hPad,
                  child: _SectionLabel(
                    icon: Icons.receipt_long_rounded,
                    label: 'Pricing breakdown',
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: _hPad,
                  child: CustomerPricingBreakdownCard(order: order),
                ),
                const SizedBox(height: 20),

                // ── Completion images ──────────────────────────────────
                if (order.completionImages.isNotEmpty) ...[
                  Padding(
                    padding: _hPad,
                    child: _SectionLabel(
                      icon: Icons.task_alt_rounded,
                      label: 'Completion proof',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: _hPad,
                    child: CustomerCompletionImagesGrid(
                      imageUrls: order.completionImages,
                      completionNote: order.workerCompletionNote,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Review ─────────────────────────────────────────────
                if (order.status == RequestStatus.completed) ...[
                  Padding(
                    padding: _hPad,
                    child: _SectionLabel(
                      icon: Icons.star_outline_rounded,
                      label: 'Your review',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: _hPad,
                    child: _ReviewCard(
                      order: order,
                      state: state,
                      cs: cs,
                      onAddReview: () =>
                          _showReviewDialog(context, order.id),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Cancelled / rejected ───────────────────────────────
                if (order.status == RequestStatus.cancelled ||
                    order.status == RequestStatus.rejected) ...[
                  Padding(
                    padding: _hPad,
                    child: _TerminalCard(order: order, cs: cs),
                  ),
                  const SizedBox(height: 20),
                ],

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showReviewDialog(
    BuildContext context,
    String requestId,
  ) async {
    final submission = await showDialog<_ReviewSubmission>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _ReviewDialog(),
    );

    if (submission == null || !context.mounted) return;

    context.read<CustomerHistoryBloc>().add(
          SubmitCustomerReview(
            requestId: requestId,
            rating: submission.rating,
            review: submission.review,
          ),
        );
  }
}

class _ReviewSubmission {
  const _ReviewSubmission({required this.rating, required this.review});

  final double rating;
  final String review;
}

/// Owns [TextEditingController] for the dialog route lifecycle (avoids dispose-during-exit).
class _ReviewDialog extends StatefulWidget {
  const _ReviewDialog();

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _reviewController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_rating < 1) return;
    Navigator.of(context).pop(
      _ReviewSubmission(
        rating: _rating.toDouble(),
        review: _reviewController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.star_outline_rounded,
                      color: cs.onTertiaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Rate your experience',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final star = i + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _rating = star),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          star <= _rating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: star <= _rating
                              ? cs.tertiary
                              : cs.onSurface.withValues(alpha: 0.2),
                          size: 36,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reviewController,
                maxLines: 3,
                style: TextStyle(fontSize: 14, color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Share your experience (optional)…',
                  hintStyle: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.35),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor:
                      cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: cs.outline.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _rating < 1 ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        disabledBackgroundColor:
                            cs.onSurface.withValues(alpha: 0.12),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ── Hero Header ────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final ServiceRequestModel order;
  const _HeroHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final worker = order.workerInfo;
    final amount = order.displayAmount;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Worker avatar / service icon
              _buildAvatar(cs, worker),
              const SizedBox(width: 14),

              // Category + ID + chips
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.categoryName ?? 'Service request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                        letterSpacing: -0.4,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${order.shortRequestId}  ·  ${order.bookingType.value}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        CustomerHistoryStatusChip(status: order.status),
                        CustomerHistoryPaymentChip(
                            paymentStatus: order.paymentStatus),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Amount pill
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Rs ${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                    Text(
                      order.pricingType.value,
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.primary.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Rating bar (if reviewed)
          if (order.hasReview) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ...List.generate(
                    5,
                    (i) => Icon(
                      i < (order.rating ?? 0).round()
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 16,
                      color: cs.tertiary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.rating!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Your rating',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onTertiaryContainer.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(ColorScheme cs, dynamic worker) {
    if (worker != null && (worker.profileImage ?? '').isNotEmpty) {
      return AppCacheImage(
        imageUrl: worker.profileImage!,
        width: 58,
        height: 58,
        round: 29,
        boxFit: BoxFit.cover,
      );
    }

    final initials = worker != null && (worker.name as String).isNotEmpty
        ? (worker.name as String)
            .trim()
            .split(' ')
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join()
        : '?';

    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}

// ── Request Details Card ───────────────────────────────────────────────────────

class _RequestDetailsCard extends StatelessWidget {
  final ServiceRequestModel order;
  final String Function(DateTime?) formatDate;
  final ColorScheme cs;

  const _RequestDetailsCard({
    required this.order,
    required this.formatDate,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <({IconData icon, String label, String value})>[
      (
        icon: Icons.location_on_outlined,
        label: 'Address',
        value: order.customerAddress ?? '—',
      ),
      (
        icon: Icons.notes_rounded,
        label: 'Description',
        value: order.description?.trim().isNotEmpty == true
            ? order.description!
            : '—',
      ),
      (
        icon: Icons.bookmark_outline_rounded,
        label: 'Booking type',
        value: order.bookingType.value,
      ),
      (
        icon: Icons.route_outlined,
        label: 'Request flow',
        value: order.requestFlow.value,
      ),
      (
        icon: Icons.payments_outlined,
        label: 'Pricing type',
        value: order.pricingType.value,
      ),
      (
        icon: Icons.calendar_today_rounded,
        label: 'Created',
        value: formatDate(order.createdAt),
      ),
      if (order.completedAt != null)
        (
          icon: Icons.task_alt_rounded,
          label: 'Completed',
          value: formatDate(order.completedAt),
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _InfoTile(
              icon: rows[i].icon,
              label: rows[i].label,
              value: rows[i].value,
              cs: cs,
            ),
            if (i < rows.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                color: cs.outlineVariant.withValues(alpha: 0.3),
                indent: 16,
                endIndent: 16,
              ),
          ],
        ],
      ),
    );
  }
}

// ── Worker Card ────────────────────────────────────────────────────────────────

class _WorkerCard extends StatelessWidget {
  final ServiceRequestModel order;
  final ColorScheme cs;

  const _WorkerCard({required this.order, required this.cs});

  @override
  Widget build(BuildContext context) {
    final worker = order.workerInfo;

    if (worker == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_search_rounded,
                  color: cs.onSurface.withValues(alpha: 0.35), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No worker assigned yet.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              AppCacheImage(
                imageUrl: worker.profileImage ?? '',
                width: 54,
                height: 54,
                round: 27,
                boxFit: BoxFit.cover,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker.name.isNotEmpty ? worker.name : 'Worker',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    if (worker.rating != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => Icon(
                              i < (worker.rating!).round()
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 14,
                              color: cs.tertiary,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            worker.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (worker.phoneNumber != null &&
                        worker.phoneNumber!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        worker.phoneNumber!,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Call button
              if (worker.phoneNumber != null &&
                  worker.phoneNumber!.isNotEmpty)
                FilledButton.tonal(
                  onPressed: () =>
                      CallAndWhatsAppUtils.openDialer(worker.phoneNumber!),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_rounded, size: 15),
                      const SizedBox(width: 5),
                      const Text('Call',
                          style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),
            ],
          ),

          // Location row
          if (worker.location != null) ...[
            const SizedBox(height: 12),
            Divider(
              height: 1,
              thickness: 0.5,
              color: cs.outlineVariant.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14,
                    color: cs.onSurface.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
                Text(
                  '${worker.location!.latitude.toStringAsFixed(4)}, '
                  '${worker.location!.longitude.toStringAsFixed(4)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Review Card ────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ServiceRequestModel order;
  final CustomerHistoryState state;
  final ColorScheme cs;
  final VoidCallback onAddReview;

  const _ReviewCard({
    required this.order,
    required this.state,
    required this.cs,
    required this.onAddReview,
  });

  @override
  Widget build(BuildContext context) {
    // Already reviewed
    if (order.hasReview) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < (order.rating ?? 0).round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 22,
                    color: cs.tertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  order.rating!.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            if (order.review != null && order.review!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                order.review!,
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Can submit
    if (!order.canSubmitReview) return const SizedBox.shrink();

    final submitting =
        state.status == CustomerHistoryStatus.reviewSubmitting;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.rate_review_outlined,
                    color: cs.onTertiaryContainer, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How was your experience?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your feedback helps improve our service.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: submitting ? null : onAddReview,
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: submitting
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cs.onPrimary),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_comment_outlined,
                          size: 16, color: cs.onPrimary),
                      const SizedBox(width: 8),
                      Text(
                        'Add review',
                        style: TextStyle(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Terminal Card (cancelled / rejected) ──────────────────────────────────────

class _TerminalCard extends StatelessWidget {
  final ServiceRequestModel order;
  final ColorScheme cs;

  const _TerminalCard({required this.order, required this.cs});

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.status == RequestStatus.cancelled;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCancelled ? Icons.cancel_outlined : Icons.block_rounded,
            color: cs.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCancelled ? 'Cancellation reason' : 'Rejection reason',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  order.cancellationReason?.trim().isNotEmpty == true
                      ? order.cancellationReason!
                      : 'No reason provided.',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onErrorContainer.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Tile ──────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16,
                color: cs.onSurface.withValues(alpha: 0.4)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 15, color: cs.onSurface.withValues(alpha: 0.45)),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha: 0.55),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ── Error View ─────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: cs.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.wifi_off_rounded,
                  color: cs.onErrorContainer, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to load order details.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}