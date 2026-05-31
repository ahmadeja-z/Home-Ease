import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/utils/CallAndWhatsAppUtils.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_bloc.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_event.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_state.dart';
import 'package:homeease/presentation/customer_history/models/customer_history_model.dart';
import 'package:homeease/presentation/customer_history/utils/scheduled_request_helpers.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_completion_images_grid.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_status_chip.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_pricing_breakdown_card.dart';
import 'package:homeease/presentation/customer_history/widgets/scheduled_request_alert_cards.dart';
import 'package:homeease/presentation/customer_history/widgets/scheduled_request_images_grid.dart';
import 'package:homeease/presentation/customer_history/widgets/scheduled_request_invoice_card.dart';
import 'package:homeease/presentation/customer_history/widgets/scheduled_request_status_chip.dart';
import 'package:homeease/presentation/customer_history/widgets/scheduled_request_timeline.dart';
import 'package:homeease/widgets/app_cache_image.dart';
import 'package:homeease/widgets/custom_app_bar.dart';

// ── Spacing constants ──────────────────────────────────────────────────────────
const _sectionGap = SizedBox(height: 12);
const _hPad = EdgeInsets.symmetric(horizontal: 16);

class ScheduledHistoryDetailsScreen extends StatefulWidget {
  final String requestId;
  const ScheduledHistoryDetailsScreen({super.key, required this.requestId});

  @override
  State<ScheduledHistoryDetailsScreen> createState() =>
      _ScheduledHistoryDetailsScreenState();
}

class _ScheduledHistoryDetailsScreenState
    extends State<ScheduledHistoryDetailsScreen> {
  late CustomerHistoryBloc _historyBloc;
  bool _cancelPending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _historyBloc = context.read<CustomerHistoryBloc>();
  }

  @override
  void dispose() {
    _historyBloc.add(const StopScheduledRequestWatch());
    super.dispose();
  }

  String _formatDateTime(DateTime? d) {
    if (d == null) return '—';
    final local = d.toLocal();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${local.day} ${months[local.month - 1]} ${local.year}  $h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerHistoryBloc, CustomerHistoryState>(
      listenWhen: (p, c) =>
          p.errorMessage != c.errorMessage ||
          p.isPayingInvoice != c.isPayingInvoice ||
          p.isCancellingScheduled != c.isCancellingScheduled ||
          p.scheduledStatusAlert != c.scheduledStatusAlert ||
          p.selectedScheduledRequest?.status !=
              c.selectedScheduledRequest?.status,
      listener: (context, state) {
        if (_cancelPending && !state.isCancellingScheduled) {
          _cancelPending = false;
          if (state.errorMessage == null && context.mounted) {
            Navigator.pop(context);
            return;
          }
        }

        if (state.errorMessage != null &&
            !state.isPayingInvoice &&
            !state.isCancellingScheduled) {
          if (!context.mounted) return;
          _showPremiumSnackBar(context, state.errorMessage!, isError: true);
        }
        final alert = state.scheduledStatusAlert;
        if (alert != null && alert.isNotEmpty) {
          if (!context.mounted) return;
          _showPremiumSnackBar(context, alert);
          _historyBloc.add(const ClearScheduledStatusAlert());
        }
      },
      buildWhen: (p, c) =>
          p.selectedScheduledRequest != c.selectedScheduledRequest ||
          p.status != c.status ||
          p.errorMessage != c.errorMessage ||
          p.isPayingInvoice != c.isPayingInvoice ||
          p.isCancellingScheduled != c.isCancellingScheduled ||
          p.countdownRemaining != c.countdownRemaining ||
          p.showWorkerNotStartedHint != c.showWorkerNotStartedHint,
      builder: (context, state) {
        final request = state.selectedScheduledRequest;
        final isTargetLoaded =
            request != null && request.id == widget.requestId;

        if (!isTargetLoaded) {
          final showError = !state.isDetailsLoading &&
              state.status == CustomerHistoryStatus.error;

          if (showError) {
            return _ErrorScreen(
              message: state.errorMessage ?? 'Unable to load request',
              onRetry: () => context
                  .read<CustomerHistoryBloc>()
                  .add(LoadScheduledRequestDetails(widget.requestId)),
            );
          }

          return const Scaffold(
            appBar: CustomAppBar(title: 'Request details'),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
          appBar: CustomAppBar(
            title: 'Request #${request.shortRequestId}',
            action: IconButton(
              onPressed: () => context
                  .read<CustomerHistoryBloc>()
                  .add(LoadScheduledRequestDetails(widget.requestId)),
              icon: const Icon(Icons.refresh_rounded),
              color: Theme.of(context).colorScheme.onSecondary,
            ),
          ),
          bottomNavigationBar: request.canCustomerCancelScheduled
              ? _CancelBar(
                  isLoading: state.isCancellingScheduled,
                  onCancel: () => _showCancelDialog(context, request.id),
                )
              : null,
          body: RefreshIndicator(
            onRefresh: () async {
              _historyBloc.add(LoadScheduledRequestDetails(widget.requestId));
              await _historyBloc.stream.firstWhere((s) => !s.isDetailsLoading);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Hero header ──────────────────────────────────────
                  _HeroHeader(request: request),

                  const SizedBox(height: 16),

                  // ── Alert banners ────────────────────────────────────
                  Padding(
                    padding: _hPad,
                    child: ScheduledStatusBanner(
                      request: request,
                      countdownRemaining: state.countdownRemaining,
                      showNotStartedHint: state.showWorkerNotStartedHint,
                    ),
                  ),
                  if (request.status == RequestStatus.overdue) ...[
                    _sectionGap,
                    Padding(
                      padding: _hPad,
                      child: ScheduledOverdueWarningCard(
                        request: request,
                        onContactWorker: request.workerInfo?.phoneNumber != null
                            ? () => CallAndWhatsAppUtils.openDialer(
                                  request.workerInfo!.phoneNumber!,
                                )
                            : null,
                      ),
                    ),
                  ],
                  if (request.status == RequestStatus.workerNoShow) ...[
                    _sectionGap,
                    Padding(
                      padding: _hPad,
                      child: ScheduledNoShowCard(
                        request: request,
                        isCancelling: state.isCancellingScheduled,
                        onCancel: () =>
                            _showCancelDialog(context, request.id),
                      ),
                    ),
                  ],
                  if (request.status == RequestStatus.reassigned) ...[
                    _sectionGap,
                    Padding(
                      padding: _hPad,
                      child: ScheduledReassignedBanner(request: request),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Schedule details ─────────────────────────────────
                  Padding(
                    padding: _hPad,
                    child: _ScheduleInfoRow(
                      request: request,
                      format: _formatDateTime,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Admin status ─────────────────────────────────────
                  Padding(
                    padding: _hPad,
                    child: _AdminStatusBadge(request: request),
                  ),

                  const SizedBox(height: 20),

                  // ── Timeline ─────────────────────────────────────────
                  Padding(
                    padding: _hPad,
                    child: _SectionLabel(
                      icon: Icons.timeline_rounded,
                      label: 'Request timeline',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: _hPad,
                    child: ScheduledRequestTimeline(request: request),
                  ),

                  const SizedBox(height: 20),

                  // ── Worker card ──────────────────────────────────────
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
                    child: _WorkerCard(request: request),
                  ),

                  const SizedBox(height: 20),

                  // ── Description ──────────────────────────────────────
                  if (request.description?.trim().isNotEmpty == true) ...[
                    Padding(
                      padding: _hPad,
                      child: _SectionLabel(
                        icon: Icons.notes_rounded,
                        label: 'Description',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: _hPad,
                      child: _DescriptionCard(request: request),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Customer images ──────────────────────────────────
                  if (request.customerRequestImages.isNotEmpty) ...[
                    Padding(
                      padding: _hPad,
                      child: _SectionLabel(
                        icon: Icons.photo_library_outlined,
                        label: 'Your photos',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: _hPad,
                      child: ScheduledRequestImagesGrid(
                        imageUrls: request.customerRequestImages,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Pricing breakdown ────────────────────────────────
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
                    child: CustomerPricingBreakdownCard(order: request),
                  ),

                  const SizedBox(height: 12),

                  // ── Invoice ──────────────────────────────────────────
                  Padding(
                    padding: _hPad,
                    child: ScheduledRequestInvoiceCard(
                      request: request,
                      isPaying: state.isPayingInvoice,
                      onConfirmPaid: () =>
                          _confirmPayment(context, request.id),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Completion images ────────────────────────────────
                  if (request.completionImages.isNotEmpty) ...[
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
                        imageUrls: request.completionImages,
                        completionNote: request.workerCompletionNote,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Payment record ───────────────────────────────────
                  Padding(
                    padding: _hPad,
                    child: _SectionLabel(
                      icon: Icons.payments_rounded,
                      label: 'Payment record',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: _hPad,
                    child: _PaymentCard(
                      request: request,
                      format: _formatDateTime,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Review ───────────────────────────────────────────
                  if (request.status == RequestStatus.completed &&
                      request.hasReview) ...[
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
                      child: _ReviewCard(request: request),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Terminal (cancelled/rejected) ────────────────────
                  if (request.status == RequestStatus.cancelled ||
                      request.status == RequestStatus.rejected) ...[
                    Padding(
                      padding: _hPad,
                      child: _TerminalCard(request: request),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPremiumSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    final cs = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
              color: cs.onPrimary,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: cs.onPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? cs.error : cs.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        elevation: 0,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> _showCancelDialog(BuildContext context, String requestId) async {
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _CancelScheduledDialog(),
    );

    if (reason == null || reason.isEmpty) return;

    _cancelPending = true;
    _historyBloc.add(
      CancelScheduledRequest(requestId: requestId, reason: reason),
    );
  }

  void _confirmPayment(BuildContext context, String id) {
    final cs = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      color: cs.primary.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.payments_outlined,
                        color: cs.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Confirm payment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Confirm that you have paid the worker in person. This records payment via the app.',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha:0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(
                            color: cs.outline.withValues(alpha:0.3)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _historyBloc.add(PayScheduledInvoice(id));
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm paid'),
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

/// Cancellation dialog — owns [TextEditingController] for the route lifecycle.
class _CancelScheduledDialog extends StatefulWidget {
  const _CancelScheduledDialog();

  @override
  State<_CancelScheduledDialog> createState() => _CancelScheduledDialogState();
}

class _CancelScheduledDialogState extends State<_CancelScheduledDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;
    Navigator.of(context).pop(reason);
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
                      color: cs.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.cancel_outlined,
                      color: cs.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cancel request',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Please tell us why you are cancelling. This helps our team improve service quality.',
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                style: TextStyle(fontSize: 14, color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Reason for cancellation…',
                  hintStyle: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.35),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
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
                      child: const Text('Keep request'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.error,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
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
  final ServiceRequestModel request;
  const _HeroHeader({required this.request});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = request.serviceTitle ?? request.categoryName ?? 'Scheduled service';
    final thumb = request.customerRequestImages.isNotEmpty
        ? request.customerRequestImages.first
        : request.serviceMainImage;
    final amount = request.finalAmount > 0
        ? request.finalAmount
        : (request.basePrice ?? 0);

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: cs.primary.withValues(alpha:0.08),
            ),
            clipBehavior: Clip.antiAlias,
            child: thumb != null && thumb.isNotEmpty
                ? AppCacheImage(
                    imageUrl: thumb,
                    width: 68,
                    height: 68,
                    boxFit: BoxFit.cover,
                  )
                : Icon(Icons.home_repair_service_rounded,
                    color: cs.primary, size: 30),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                    letterSpacing: -0.3,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Category: ${request.categoryName ?? '—'}  ·  ${request.pricingType.value}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha:0.45),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ScheduledRequestStatusChip(status: request.status),
                    CustomerHistoryPaymentChip(
                        paymentStatus: request.paymentStatus),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Amount bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha:0.08),
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
                  request.pricingType.value,
                  style: TextStyle(
                    fontSize: 10,
                    color: cs.primary.withValues(alpha:0.65),
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

// ── Schedule Info Row ──────────────────────────────────────────────────────────

class _ScheduleInfoRow extends StatelessWidget {
  final ServiceRequestModel request;
  final String Function(DateTime?) format;

  const _ScheduleInfoRow({required this.request, required this.format});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final overdue =
        ScheduledRequestHelpers.calculateOverdueDuration(request);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha:0.4)),
      ),
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.calendar_today_rounded,
            label: 'Preferred date',
            value: format(request.preferredDate),
            cs: cs,
          ),
          _divider(cs),
          _InfoTile(
            icon: Icons.access_time_rounded,
            label: 'Preferred time',
            value: request.preferredTime ?? '—',
            cs: cs,
          ),
          _divider(cs),
          _InfoTile(
            icon: Icons.schedule_rounded,
            label: 'Scheduled at',
            value: format(request.scheduledTime),
            cs: cs,
          ),
          if (overdue != null) ...[
            _divider(cs),
            _InfoTile(
              icon: Icons.warning_amber_rounded,
              label: 'Overdue by',
              value: ScheduledRequestHelpers.formatDuration(overdue),
              cs: cs,
              valueColor: cs.error,
            ),
          ],
          _divider(cs),
          _InfoTile(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: request.customerAddress ?? '—',
            cs: cs,
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme cs) => Divider(
        height: 16,
        thickness: 0.5,
        color: cs.outlineVariant.withValues(alpha:0.3),
      );
}
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: cs.onSurface.withValues(alpha: 0.4)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
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
    );
  }
}
// ── Admin Status Badge ─────────────────────────────────────────────────────────

class _AdminStatusBadge extends StatelessWidget {
  final ServiceRequestModel request;
  const _AdminStatusBadge({required this.request});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final (label, icon, bgColor, textColor) = switch (request.status) {
      RequestStatus.pendingAdminApproval => (
          'Pending admin approval',
          Icons.hourglass_top_rounded,
          cs.tertiaryContainer,
          cs.onTertiaryContainer,
        ),
      RequestStatus.rejected => (
          'Rejected by admin',
          Icons.cancel_outlined,
          cs.errorContainer,
          cs.onErrorContainer,
        ),
      RequestStatus.cancelled => (
          'Request cancelled',
          Icons.block_rounded,
          cs.errorContainer,
          cs.onErrorContainer,
        ),
      RequestStatus.overdue => (
          'Approved — worker overdue',
          Icons.warning_amber_rounded,
          cs.tertiaryContainer,
          cs.onTertiaryContainer,
        ),
      RequestStatus.workerNoShow => (
          'Approved — worker no-show',
          Icons.person_off_outlined,
          cs.errorContainer,
          cs.onErrorContainer,
        ),
      _ => (
          'Approved by admin',
          Icons.verified_outlined,
          cs.primaryContainer,
          cs.onPrimaryContainer,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Worker Card ────────────────────────────────────────────────────────────────

class _WorkerCard extends StatelessWidget {
  final ServiceRequestModel request;
  const _WorkerCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final worker = request.workerInfo;

    if (worker == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha:0.4)),
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
                  color: cs.onSurface.withValues(alpha:0.35), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _noWorkerMessage(request.status),
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: cs.onSurface.withValues(alpha:0.45),
                  height: 1.4,
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
        border: Border.all(color: cs.outlineVariant.withValues(alpha:0.4)),
      ),
      child: Row(
        children: [
          // Avatar
          AppCacheImage(
            imageUrl: worker.profileImage ?? '',
            width: 52,
            height: 52,
            round: 26,
            boxFit: BoxFit.cover,
          ),
          const SizedBox(width: 14),

          // Name + rating
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name.isNotEmpty ? worker.name : 'Assigned worker',
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
                      const SizedBox(width: 4),
                      Text(
                        worker.rating!.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha:0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Call button
          if (worker.phoneNumber != null && worker.phoneNumber!.isNotEmpty)
            FilledButton.tonal(
              onPressed: () =>
                  CallAndWhatsAppUtils.openDialer(worker.phoneNumber!),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_rounded, size: 15),
                  const SizedBox(width: 5),
                  const Text('Call', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _noWorkerMessage(RequestStatus status) {
    switch (status) {
      case RequestStatus.pendingAdminApproval:
      case RequestStatus.approved:
        return 'No worker assigned yet. Admin will assign after approval.';
      case RequestStatus.assigned:
      case RequestStatus.reassigned:
        return 'Worker slot updated — waiting for worker confirmation.';
      case RequestStatus.workerNoShow:
        return 'Previous worker did not attend. A new worker may be assigned.';
      case RequestStatus.rejected:
        return 'Request was rejected. No worker assigned.';
      default:
        return 'Worker information is not available.';
    }
  }
}

// ── Description Card ───────────────────────────────────────────────────────────

class _DescriptionCard extends StatelessWidget {
  final ServiceRequestModel request;
  const _DescriptionCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha:0.4)),
      ),
      child: Text(
        request.description!,
        style: TextStyle(
          fontSize: 14,
          color: cs.onSurface.withValues(alpha:0.75),
          height: 1.6,
        ),
      ),
    );
  }
}

// ── Payment Card ───────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final ServiceRequestModel request;
  final String Function(DateTime?) format;

  const _PaymentCard({required this.request, required this.format});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha:0.4)),
      ),
      child: Column(
        children: [
          _InfoTile(
            icon: Icons.credit_score_rounded,
            label: 'Payment status',
            value: request.paymentStatus.displayLabel,
            cs: cs,
          ),
          if (request.customerPaidAmount != null) ...[
            Divider(height: 16, thickness: 0.5,
                color: cs.outlineVariant.withValues(alpha:0.3)),
            _InfoTile(
              icon: Icons.monetization_on_outlined,
              label: 'Paid amount',
              value: 'Rs ${request.customerPaidAmount}',
              cs: cs,
            ),
          ],
          Divider(height: 16, thickness: 0.5,
              color: cs.outlineVariant.withValues(alpha:0.3)),
          _InfoTile(
            icon: Icons.event_available_outlined,
            label: 'Paid at',
            value: format(request.customerPaidAt),
            cs: cs,
          ),
        ],
      ),
    );
  }
}

// ── Review Card ────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final ServiceRequestModel request;
  const _ReviewCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha:0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < (request.rating ?? 0).round()
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: cs.tertiary,
                size: 22,
              ),
            ),
          ),
          if (request.review != null && request.review!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              request.review!,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha:0.7),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Terminal Card (cancelled / rejected) ──────────────────────────────────────

class _TerminalCard extends StatelessWidget {
  final ServiceRequestModel request;
  const _TerminalCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCancelled = request.status == RequestStatus.cancelled;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha:0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withValues(alpha:0.2)),
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
                  request.cancellationReason?.trim().isNotEmpty == true
                      ? request.cancellationReason!
                      : 'No reason provided.',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onErrorContainer.withValues(alpha:0.8),
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
        Icon(icon, size: 15, color: cs.onSurface.withValues(alpha:0.45)),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.onSurface.withValues(alpha:0.55),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ── Cancel Bottom Bar ──────────────────────────────────────────────────────────

class _CancelBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onCancel;

  const _CancelBar({required this.isLoading, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha:0.3)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: OutlinedButton(
            onPressed: isLoading ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: cs.error,
              side: BorderSide(color: cs.error.withValues(alpha:0.6)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: isLoading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cs.error),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel_outlined, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Cancel scheduled request',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Error Screen ───────────────────────────────────────────────────────────────

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: const CustomAppBar(title: 'Request details'),
      body: Center(
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
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurface.withValues(alpha:0.65),
                  height: 1.5,
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
      ),
    );
  }
}