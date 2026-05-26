import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/core/utils/CallAndWhatsAppUtils.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_bloc.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_event.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_state.dart';
import 'package:homeease/presentation/customer_history/models/customer_history_model.dart';
import 'package:homeease/presentation/customer_history/utils/scheduled_request_helpers.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_completion_images_grid.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_section_card.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_status_chip.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_pricing_breakdown_card.dart';
import 'package:homeease/presentation/customer_history/widgets/scheduled_request_alert_cards.dart';
import 'package:homeease/presentation/customer_history/widgets/scheduled_request_images_grid.dart';
import 'package:homeease/presentation/customer_history/widgets/scheduled_request_invoice_card.dart';
import 'package:homeease/presentation/customer_history/widgets/scheduled_request_status_chip.dart';
import 'package:homeease/presentation/customer_history/widgets/scheduled_request_timeline.dart';
import 'package:homeease/widgets/app_cache_image.dart';
import 'package:homeease/widgets/custom_app_bar.dart';

class ScheduledHistoryDetailsScreen extends StatefulWidget {
  final String requestId;

  const ScheduledHistoryDetailsScreen({super.key, required this.requestId});

  @override
  State<ScheduledHistoryDetailsScreen> createState() =>
      _ScheduledHistoryDetailsScreenState();
}

class _ScheduledHistoryDetailsScreenState
    extends State<ScheduledHistoryDetailsScreen> {
  @override
  void dispose() {
    context.read<CustomerHistoryBloc>().add(const StopScheduledRequestWatch());
    super.dispose();
  }

  String _formatDateTime(DateTime? d) {
    if (d == null) return '—';
    final local = d.toLocal();
    return '${local.day}/${local.month}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerHistoryBloc, CustomerHistoryState>(
      listenWhen: (p, c) =>
          p.errorMessage != c.errorMessage ||
          p.isPayingInvoice != c.isPayingInvoice ||
          p.scheduledStatusAlert != c.scheduledStatusAlert ||
          p.selectedScheduledRequest?.status != c.selectedScheduledRequest?.status,
      listener: (context, state) {
        if (state.errorMessage != null &&
            !state.isPayingInvoice &&
            !state.isCancellingScheduled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }

        final alert = state.scheduledStatusAlert;
        if (alert != null && alert.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(alert),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
          context.read<CustomerHistoryBloc>().add(const ClearScheduledStatusAlert());
        }
      },
      buildWhen: (p, c) =>
          p.selectedScheduledRequest != c.selectedScheduledRequest ||
          p.status != c.status ||
          p.isPayingInvoice != c.isPayingInvoice ||
          p.isCancellingScheduled != c.isCancellingScheduled ||
          p.countdownRemaining != c.countdownRemaining ||
          p.showWorkerNotStartedHint != c.showWorkerNotStartedHint,
      builder: (context, state) {
        if (state.isDetailsLoading && state.selectedScheduledRequest == null) {
          return Scaffold(
            appBar: const CustomAppBar(title: 'Scheduled request'),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final request = state.selectedScheduledRequest;
        if (request == null || request.id != widget.requestId) {
          return Scaffold(
            appBar: const CustomAppBar(title: 'Scheduled request'),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.errorMessage ?? 'Unable to load request'),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.read<CustomerHistoryBloc>().add(
                          LoadScheduledRequestDetails(widget.requestId),
                        ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: CustomAppBar(
            title: 'Scheduled request',
            action: IconButton(
              onPressed: () => context.read<CustomerHistoryBloc>().add(
                    LoadScheduledRequestDetails(widget.requestId),
                  ),
              icon: const Icon(Icons.refresh),
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
              context.read<CustomerHistoryBloc>().add(
                    LoadScheduledRequestDetails(widget.requestId),
                  );
              await context.read<CustomerHistoryBloc>().stream.firstWhere(
                    (s) => !s.isDetailsLoading,
                  );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderSection(request: request),
                  ScheduledStatusBanner(
                    request: request,
                    countdownRemaining: state.countdownRemaining,
                    showNotStartedHint: state.showWorkerNotStartedHint,
                  ),
                  if (request.status == RequestStatus.overdue)
                    ScheduledOverdueWarningCard(
                      request: request,
                      onContactWorker: request.workerInfo?.phoneNumber != null
                          ? () => CallAndWhatsAppUtils.openDialer(
                                request.workerInfo!.phoneNumber!,
                              )
                          : null,
                    ),
                  if (request.status == RequestStatus.workerNoShow)
                    ScheduledNoShowCard(
                      request: request,
                      isCancelling: state.isCancellingScheduled,
                      onCancel: () => _showCancelDialog(context, request.id),
                    ),
                  if (request.status == RequestStatus.reassigned)
                    ScheduledReassignedBanner(request: request),
                  _ServiceSection(request: request),
                  _ScheduleSection(
                    request: request,
                    format: _formatDateTime,
                  ),
                  _DescriptionSection(request: request),
                  ScheduledRequestImagesGrid(
                    imageUrls: request.customerRequestImages,
                  ),
                  _AdminApprovalSection(request: request),
                  ScheduledRequestTimeline(request: request),
                  _WorkerSection(request: request),
                  CustomerPricingBreakdownCard(order: request),
                  ScheduledRequestInvoiceCard(
                    request: request,
                    isPaying: state.isPayingInvoice,
                    onConfirmPaid: () => _confirmPayment(context, request.id),
                  ),
                  CustomerCompletionImagesGrid(
                    imageUrls: request.completionImages,
                    completionNote: request.workerCompletionNote,
                  ),
                  _PaymentMetaSection(request: request, format: _formatDateTime),
                  _ReviewSection(request: request),
                  if (request.status == RequestStatus.cancelled ||
                      request.status == RequestStatus.rejected)
                    _TerminalSection(request: request),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCancelDialog(BuildContext context, String requestId) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel scheduled request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please tell us why you are cancelling. '
                'This helps our team improve service.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Cancellation reason',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep request'),
            ),
            TextButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) return;
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Cancel request',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (confirmed == true && context.mounted && reason.isNotEmpty) {
      context.read<CustomerHistoryBloc>().add(
            CancelScheduledRequest(
              requestId: requestId,
              reason: reason,
            ),
          );
    }
  }

  void _confirmPayment(BuildContext context, String id) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm payment'),
        content: const Text(
          'Confirm that you have paid the worker in person. '
          'This records payment via the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<CustomerHistoryBloc>().add(PayScheduledInvoice(id));
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _CancelBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onCancel;

  const _CancelBar({required this.isLoading, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : onCancel,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.cancel_outlined),
          label: const Text('Cancel scheduled request'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.errorColor,
            side: const BorderSide(color: AppTheme.errorColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final ServiceRequestModel request;

  const _HeaderSection({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomerHistorySectionCard(
      title: 'Request #${request.shortRequestId}',
      icon: Icons.tag_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${request.id}', style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ScheduledRequestStatusChip(status: request.status),
              CustomerHistoryPaymentChip(paymentStatus: request.paymentStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Created ${_format(request.createdAt)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _format(DateTime d) {
    final local = d.toLocal();
    return '${local.day}/${local.month}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _ServiceSection extends StatelessWidget {
  final ServiceRequestModel request;

  const _ServiceSection({required this.request});

  @override
  Widget build(BuildContext context) {
    final title =
        request.serviceTitle ?? request.categoryName ?? 'Service';
    return CustomerHistorySectionCard(
      title: 'Service',
      icon: Icons.home_repair_service_outlined,
      child: Row(
        children: [
          if (request.serviceMainImage != null &&
              request.serviceMainImage!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppCacheImage(
                imageUrl: request.serviceMainImage!,
                width: 56,
                height: 56,
                boxFit: BoxFit.cover,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  'Category: ${request.categoryName ?? '—'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Pricing: ${request.pricingType.value}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  final ServiceRequestModel request;
  final String Function(DateTime?) format;

  const _ScheduleSection({required this.request, required this.format});

  @override
  Widget build(BuildContext context) {
    final overdue = ScheduledRequestHelpers.calculateOverdueDuration(request);
    return CustomerHistorySectionCard(
      title: 'Scheduled date & time',
      icon: Icons.event_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(context, 'Preferred date', format(request.preferredDate)),
          _row(context, 'Preferred time', request.preferredTime ?? '—'),
          _row(context, 'Scheduled at', format(request.scheduledTime)),
          if (overdue != null)
            _row(
              context,
              'Overdue by',
              ScheduledRequestHelpers.formatDuration(overdue),
            ),
          _row(context, 'Address', request.customerAddress ?? '—'),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value),
        ],
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final ServiceRequestModel request;

  const _DescriptionSection({required this.request});

  @override
  Widget build(BuildContext context) {
    return CustomerHistorySectionCard(
      title: 'Description',
      icon: Icons.description_outlined,
      child: Text(
        request.description?.trim().isNotEmpty == true
            ? request.description!
            : 'No description provided',
      ),
    );
  }
}

class _AdminApprovalSection extends StatelessWidget {
  final ServiceRequestModel request;

  const _AdminApprovalSection({required this.request});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (request.status) {
      RequestStatus.pendingAdminApproval => (
          'Pending admin approval',
          AppTheme.warningColor,
        ),
      RequestStatus.rejected => ('Rejected by admin', AppTheme.errorColor),
      RequestStatus.cancelled => ('Cancelled', AppTheme.errorColor),
      RequestStatus.overdue => ('Approved — worker overdue', AppTheme.warningColor),
      RequestStatus.workerNoShow => ('Approved — no-show', AppTheme.errorColor),
      _ => ('Approved', AppTheme.successColor),
    };

    return CustomerHistorySectionCard(
      title: 'Admin approval',
      icon: Icons.admin_panel_settings_outlined,
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _WorkerSection extends StatelessWidget {
  final ServiceRequestModel request;

  const _WorkerSection({required this.request});

  @override
  Widget build(BuildContext context) {
    final worker = request.workerInfo;

    if (worker == null) {
      return CustomerHistorySectionCard(
        title: 'Assigned worker',
        icon: Icons.engineering_outlined,
        child: Text(
          _noWorkerMessage(request.status),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).hintColor,
              ),
        ),
      );
    }

    return CustomerHistorySectionCard(
      title: 'Assigned worker',
      icon: Icons.person_outline,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCacheImage(
            imageUrl: worker.profileImage ?? '',
            width: 56,
            height: 56,
            round: 28,
            boxFit: BoxFit.cover,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.name.isNotEmpty ? worker.name : 'Assigned worker',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (worker.rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      Text(worker.rating!.toStringAsFixed(1)),
                    ],
                  ),
                if (worker.phoneNumber != null &&
                    worker.phoneNumber!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        CallAndWhatsAppUtils.openDialer(worker.phoneNumber!),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Call worker'),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Phone not available',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
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

class _PaymentMetaSection extends StatelessWidget {
  final ServiceRequestModel request;
  final String Function(DateTime?) format;

  const _PaymentMetaSection({required this.request, required this.format});

  @override
  Widget build(BuildContext context) {
    return CustomerHistorySectionCard(
      title: 'Payment record',
      icon: Icons.payments_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status: ${request.paymentStatus.displayLabel}'),
          if (request.customerPaidAmount != null)
            Text('Paid amount: ${request.customerPaidAmount}'),
          Text('Paid at: ${format(request.customerPaidAt)}'),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final ServiceRequestModel request;

  const _ReviewSection({required this.request});

  @override
  Widget build(BuildContext context) {
    if (request.status != RequestStatus.completed || !request.hasReview) {
      return const SizedBox.shrink();
    }

    return CustomerHistorySectionCard(
      title: 'Your review',
      icon: Icons.rate_review_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < (request.rating ?? 0).round()
                    ? Icons.star
                    : Icons.star_border,
                color: Colors.amber,
              );
            }),
          ),
          if (request.review != null && request.review!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(request.review!),
          ],
        ],
      ),
    );
  }
}

class _TerminalSection extends StatelessWidget {
  final ServiceRequestModel request;

  const _TerminalSection({required this.request});

  @override
  Widget build(BuildContext context) {
    return CustomerHistorySectionCard(
      title: request.status == RequestStatus.cancelled
          ? 'Cancellation'
          : 'Rejection',
      icon: Icons.cancel_outlined,
      child: Text(
        request.cancellationReason?.trim().isNotEmpty == true
            ? request.cancellationReason!
            : 'No reason provided',
        style: TextStyle(color: AppTheme.errorColor.withValues(alpha: 0.9)),
      ),
    );
  }
}
