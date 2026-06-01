import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/core/utils/CallAndWhatsAppUtils.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_completion_images_grid.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_section_card.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_status_chip.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_pricing_breakdown_card.dart';
import 'package:homeease/presentation/customer_history/widgets/scheduled_request_invoice_card.dart';
import 'package:homeease/presentation/scheduled_booking/bloc/scheduled_booking_bloc.dart';
import 'package:homeease/presentation/scheduled_booking/bloc/scheduled_booking_event.dart';
import 'package:homeease/presentation/scheduled_booking/bloc/scheduled_booking_state.dart';
import 'package:homeease/presentation/scheduled_booking/widgets/scheduled_booking_timeline.dart';
import 'package:homeease/repositories/scheduled_booking_repository.dart';
import 'package:homeease/widgets/app_cache_image.dart';
import 'package:homeease/widgets/custom_app_bar.dart';
import 'package:homeease/widgets/image_gallery_viewer.dart';

class ScheduledBookingDetailsScreen extends StatelessWidget {
  final String requestId;

  const ScheduledBookingDetailsScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScheduledBookingBloc(
        repository: ScheduledBookingRepository(),
        initialRequestId: requestId,
      )
        ..add(LoadScheduledBookingDetails(requestId))
        ..add(StartScheduledBookingRealtime(requestId)),
      child: _ScheduledBookingDetailsView(requestId: requestId),
    );
  }
}

class _ScheduledBookingDetailsView extends StatefulWidget {
  final String requestId;

  const _ScheduledBookingDetailsView({required this.requestId});

  @override
  State<_ScheduledBookingDetailsView> createState() =>
      _ScheduledBookingDetailsViewState();
}

class _ScheduledBookingDetailsViewState
    extends State<_ScheduledBookingDetailsView> {
  bool _invoiceSheetOpen = false;
  bool _isOpeningInvoice = false;
  DateTime? _lastAutoShownBillGeneratedAt;

  String _formatDateTime(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}/${d.month}/${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScheduledBookingBloc, ScheduledBookingState>(
      listenWhen: (p, c) =>
          p.errorMessage != c.errorMessage ||
          p.successMessage != c.successMessage ||
          p.status != c.status,
      listener: (context, state) {
        if (state.errorMessage != null &&
            (state.status == ScheduledBookingUiStatus.payError ||
                state.status == ScheduledBookingUiStatus.detailsError)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.successMessage != null &&
            state.status == ScheduledBookingUiStatus.paySuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppTheme.successColor,
            ),
          );
          if (_invoiceSheetOpen && context.mounted) {
            Navigator.of(context).maybePop();
            _invoiceSheetOpen = false;
          }
        }

        final booking = state.booking;
        if (booking != null && context.mounted) {
          _maybeAutoOpenInvoice(context, booking);
        }
      },
      builder: (context, state) {
        if (state.status == ScheduledBookingUiStatus.detailsLoading &&
            state.booking == null) {
          return Scaffold(
            appBar: const CustomAppBar(title: 'Booking status'),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final booking = state.booking;
        if (booking == null) {
          return Scaffold(
            appBar: const CustomAppBar(title: 'Booking status'),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.errorMessage ?? 'Unable to load booking'),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.read<ScheduledBookingBloc>().add(
                          LoadScheduledBookingDetails(widget.requestId),
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
            title: 'Scheduled booking',
            action: IconButton(
              onPressed: () => context
                  .read<ScheduledBookingBloc>()
                  .add(const RefreshScheduledBookingDetails()),
              icon: const Icon(Icons.refresh),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              context
                  .read<ScheduledBookingBloc>()
                  .add(const RefreshScheduledBookingDetails());
              await context.read<ScheduledBookingBloc>().stream.firstWhere(
                    (s) => s.status != ScheduledBookingUiStatus.detailsLoading,
                  );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatusBanner(booking: booking),
                  _ServiceInfoSection(booking: booking),
                  _ScheduleSection(booking: booking, formatDateTime: _formatDateTime),
                  _AdminApprovalSection(booking: booking),
                  _WorkerSection(booking: booking),
                  ScheduledBookingTimeline(booking: booking),
                  if (booking.customerRequestImages.isNotEmpty)
                    _RequestImagesSection(booking: booking),
                  if (booking.hasPendingInvoice)
                    ScheduledInvoiceReadyCard(
                      request: booking,
                      isOpening: _isOpeningInvoice,
                      onViewInvoice: () => _openInvoiceSheet(context, booking),
                    )
                  else if (_showPricingPreview(booking))
                    CustomerPricingBreakdownCard(order: booking),
                  CustomerCompletionImagesGrid(
                    imageUrls: booking.completionImages,
                    completionNote: booking.workerCompletionNote,
                  ),
                  if (booking.status == RequestStatus.cancelled ||
                      booking.status == RequestStatus.rejected)
                    _TerminalSection(booking: booking),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _showPricingPreview(ServiceRequestModel booking) {
    return booking.status == RequestStatus.inProgress ||
        booking.status == RequestStatus.approved ||
        booking.status == RequestStatus.assigned;
  }

  void _maybeAutoOpenInvoice(
    BuildContext context,
    ServiceRequestModel booking,
  ) {
    if (!booking.hasPendingInvoice) return;
    final billAt = booking.billGeneratedAt;
    if (billAt == null || billAt == _lastAutoShownBillGeneratedAt) return;
    if (_invoiceSheetOpen) return;

    _lastAutoShownBillGeneratedAt = billAt;
    logScheduledInvoiceOpened(booking);
    unawaited(_openInvoiceSheet(context, booking, autoOpen: true));
  }

  Future<void> _openInvoiceSheet(
    BuildContext context,
    ServiceRequestModel booking, {
    bool autoOpen = false,
  }) async {
    if (_invoiceSheetOpen) return;

    if (!autoOpen) {
      setState(() => _isOpeningInvoice = true);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() => _isOpeningInvoice = false);
    }

    if (_invoiceSheetOpen || !mounted) return;

    _invoiceSheetOpen = true;
    logScheduledInvoiceOpened(booking);
    final bookingBloc = context.read<ScheduledBookingBloc>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: bookingBloc,
          child: DraggableScrollableSheet(
            initialChildSize: 0.82,
            minChildSize: 0.45,
            maxChildSize: 0.95,
            builder: (_, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: BlocBuilder<ScheduledBookingBloc, ScheduledBookingState>(
                        buildWhen: (p, c) =>
                            p.status != c.status ||
                            p.booking?.paymentStatus !=
                                c.booking?.paymentStatus ||
                            p.booking?.finalAmount != c.booking?.finalAmount,
                        builder: (context, state) {
                          final live = state.booking;
                          final invoiceRequest =
                              live != null && live.id == booking.id
                                  ? live
                                  : booking;
                          final isPaying =
                              state.status == ScheduledBookingUiStatus.paying;

                          return SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            child: ScheduledRequestInvoiceCard(
                              request: invoiceRequest,
                              isPaying: isPaying,
                              canConfirmPayment:
                                  invoiceRequest.canCustomerConfirmPayment,
                              onConfirmPaid: () => _confirmPayment(
                                context,
                                invoiceRequest,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    _invoiceSheetOpen = false;
  }

  void _confirmPayment(BuildContext context, ServiceRequestModel booking) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm payment'),
        content: const Text(
          'Confirm that you have paid the worker in person. '
          'This records payment and completes the booking flow.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ScheduledBookingBloc>().add(
                    ConfirmScheduledBookingPayment(booking.id),
                  );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final ServiceRequestModel booking;

  const _StatusBanner({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = _statusMessage(booking);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          CustomerHistoryStatusChip(status: booking.status),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  String _statusMessage(ServiceRequestModel booking) {
    switch (booking.status) {
      case RequestStatus.pendingAdminApproval:
        return 'Waiting for admin to review and approve your booking.';
      case RequestStatus.approved:
        return 'Approved by admin. A worker will be assigned soon.';
      case RequestStatus.assigned:
        return booking.workerId == null
            ? 'Assigned — waiting for worker to accept.'
            : 'Worker assigned. Waiting for acceptance.';
      case RequestStatus.rejected:
        return 'Admin rejected this request.'
            '${booking.cancellationReason != null ? ' ${booking.cancellationReason}' : ''}';
      case RequestStatus.cancelled:
        return 'This booking was cancelled.'
            '${booking.cancellationReason != null ? ' ${booking.cancellationReason}' : ''}';
      case RequestStatus.billGenerated:
        return booking.paymentStatus == PaymentStatus.unpaid
            ? 'Invoice is ready. Please pay the worker and confirm below.'
            : 'Invoice generated.';
      case RequestStatus.completed:
        return 'Job completed. Thank you for using HomeEase!';
      default:
        return booking.getStatusString();
    }
  }
}

class _ServiceInfoSection extends StatelessWidget {
  final ServiceRequestModel booking;

  const _ServiceInfoSection({required this.booking});

  @override
  Widget build(BuildContext context) {
    final title =
        booking.serviceTitle ?? booking.categoryName ?? 'Service';
    final image = booking.serviceMainImage;

    return CustomerHistorySectionCard(
      title: 'Service',
      icon: Icons.home_repair_service_outlined,
      child: Row(
        children: [
          if (image != null && image.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppCacheImage(
                imageUrl: image,
                width: 56,
                height: 56,
                boxFit: BoxFit.cover,
              ),
            )
          else
            CircleAvatar(
              radius: 28,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(
                Icons.build_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Pricing: ${booking.pricingType.value} · '
                  'Base ${booking.basePrice?.toStringAsFixed(0) ?? '—'}',
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
  final ServiceRequestModel booking;
  final String Function(DateTime?) formatDateTime;

  const _ScheduleSection({
    required this.booking,
    required this.formatDateTime,
  });

  @override
  Widget build(BuildContext context) {
    return CustomerHistorySectionCard(
      title: 'Scheduled date & time',
      icon: Icons.event_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(context, 'Preferred date', formatDateTime(booking.preferredDate)),
          _row(context, 'Preferred time', booking.preferredTime ?? '—'),
          _row(context, 'Scheduled at', formatDateTime(booking.scheduledTime)),
          _row(context, 'Address', booking.customerAddress ?? '—'),
          if (booking.customerLocation != null)
            _row(
              context,
              'Coordinates',
              '${booking.customerLocation!.latitude.toStringAsFixed(5)}, '
                  '${booking.customerLocation!.longitude.toStringAsFixed(5)}',
            ),
          if (booking.description != null &&
              booking.description!.trim().isNotEmpty)
            _row(context, 'Description', booking.description!),
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
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class _AdminApprovalSection extends StatelessWidget {
  final ServiceRequestModel booking;

  const _AdminApprovalSection({required this.booking});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _approvalStyle(booking.status);

    return CustomerHistorySectionCard(
      title: 'Admin approval',
      icon: Icons.admin_panel_settings_outlined,
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  (String, Color) _approvalStyle(RequestStatus status) {
    switch (status) {
      case RequestStatus.pendingAdminApproval:
        return ('Pending admin approval', AppTheme.warningColor);
      case RequestStatus.rejected:
        return ('Rejected by admin', AppTheme.errorColor);
      case RequestStatus.approved:
      case RequestStatus.assigned:
      case RequestStatus.accepted:
      case RequestStatus.workerOnTheWay:
      case RequestStatus.arrived:
      case RequestStatus.inProgress:
      case RequestStatus.billGenerated:
      case RequestStatus.paid:
      case RequestStatus.completed:
        return ('Approved', AppTheme.successColor);
      case RequestStatus.cancelled:
        return ('Cancelled before completion', AppTheme.errorColor);
      default:
        return ('Under review', AppTheme.warningColor);
    }
  }
}

class _WorkerSection extends StatelessWidget {
  final ServiceRequestModel booking;

  const _WorkerSection({required this.booking});

  @override
  Widget build(BuildContext context) {
    final worker = booking.workerInfo;

    if (worker == null) {
      final hint = booking.status == RequestStatus.pendingAdminApproval ||
              booking.status == RequestStatus.approved
          ? 'No worker assigned yet. Admin will assign one after approval.'
          : booking.status == RequestStatus.assigned
              ? 'Worker slot assigned — waiting for worker to accept.'
              : booking.status == RequestStatus.rejected
                  ? 'No worker — request was rejected.'
                  : 'No worker on this booking.';

      return CustomerHistorySectionCard(
        title: 'Assigned worker',
        icon: Icons.engineering_outlined,
        child: Text(
          hint,
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
                  worker.name,
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
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestImagesSection extends StatelessWidget {
  final ServiceRequestModel booking;

  const _RequestImagesSection({required this.booking});

  @override
  Widget build(BuildContext context) {
    final urls = booking.customerRequestImages;

    return CustomerHistorySectionCard(
      title: 'Your issue photos',
      icon: Icons.photo_library_outlined,
      child: SizedBox(
        height: 88,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ImageGalleryViewer(
                      imageUrls: urls,
                      initialIndex: index,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AppCacheImage(
                  imageUrl: urls[index],
                  width: 88,
                  height: 88,
                  boxFit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TerminalSection extends StatelessWidget {
  final ServiceRequestModel booking;

  const _TerminalSection({required this.booking});

  @override
  Widget build(BuildContext context) {
    return CustomerHistorySectionCard(
      title: booking.status == RequestStatus.cancelled
          ? 'Cancellation'
          : 'Rejection',
      icon: Icons.info_outline,
      child: Text(
        booking.cancellationReason?.trim().isNotEmpty == true
            ? booking.cancellationReason!
            : 'No additional reason provided.',
        style: TextStyle(color: AppTheme.errorColor.withValues(alpha: 0.9)),
      ),
    );
  }
}
