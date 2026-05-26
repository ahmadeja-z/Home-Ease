import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/core/utils/CallAndWhatsAppUtils.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_bloc.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_event.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_state.dart';
import 'package:homeease/presentation/customer_history/models/customer_history_model.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_completion_images_grid.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_section_card.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_status_chip.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_timeline.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_pricing_breakdown_card.dart';
import 'package:homeease/widgets/app_cache_image.dart';
import 'package:homeease/widgets/custom_app_bar.dart';

class CustomerHistoryDetailsScreen extends StatelessWidget {
  final String requestId;

  const CustomerHistoryDetailsScreen({super.key, required this.requestId});

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Order details'),
      body: BlocBuilder<CustomerHistoryBloc, CustomerHistoryState>(
        buildWhen: (p, c) =>
            p.selectedOrder != c.selectedOrder ||
            p.status != c.status,
        builder: (context, state) {
          if (state.isDetailsLoading && state.selectedOrder == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = state.selectedOrder;
          if (order == null || order.id != requestId) {
            return Center(
              child: TextButton(
                onPressed: () => context.read<CustomerHistoryBloc>().add(
                      LoadCustomerHistoryDetails(requestId),
                    ),
                child: const Text('Reload details'),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, order),
                _buildWorkerSection(context, order),
                _buildRequestSection(context, order),
                CustomerHistoryTimeline(order: order),
                CustomerPricingBreakdownCard(order: order),
                CustomerCompletionImagesGrid(
                  imageUrls: order.completionImages,
                  completionNote: order.workerCompletionNote,
                ),
                _buildReviewSection(context, state, order),
                if (order.status == RequestStatus.cancelled ||
                    order.status == RequestStatus.rejected)
                  _buildCancelledSection(context, order),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ServiceRequestModel order) {
    final theme = Theme.of(context);
    return CustomerHistorySectionCard(
      title: 'Order #${order.shortRequestId}',
      icon: Icons.tag_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.categoryName ?? 'Service',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CustomerHistoryStatusChip(status: order.status),
              CustomerHistoryPaymentChip(paymentStatus: order.paymentStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Created ${_formatDate(order.createdAt)}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerSection(BuildContext context, ServiceRequestModel order) {
    final worker = order.workerInfo;
    if (worker == null) {
      return CustomerHistorySectionCard(
        title: 'Worker',
        icon: Icons.engineering_outlined,
        child: Text(
          'No worker assigned yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).hintColor,
              ),
        ),
      );
    }

    return CustomerHistorySectionCard(
      title: 'Worker details',
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
                  const SizedBox(height: 4),
                  Text(worker.phoneNumber!),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => CallAndWhatsAppUtils.openDialer(
                          worker.phoneNumber!,
                        ),
                        icon: const Icon(Icons.phone, size: 16),
                        label: const Text('Call'),
                      ),
                    ],
                  ),
                ],
                if (worker.location != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Location: ${worker.location!.latitude.toStringAsFixed(4)}, '
                      '${worker.location!.longitude.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSection(BuildContext context, ServiceRequestModel order) {
    return CustomerHistorySectionCard(
      title: 'Request details',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow(context, 'Address', order.customerAddress ?? '—'),
          _detailRow(context, 'Description', order.description ?? '—'),
          _detailRow(context, 'Booking type', order.bookingType.value),
          _detailRow(context, 'Request flow', order.requestFlow.value),
          _detailRow(context, 'Pricing type', order.pricingType.value),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
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

  Widget _buildReviewSection(
    BuildContext context,
    CustomerHistoryState state,
    ServiceRequestModel order,
  ) {
    if (order.status != RequestStatus.completed) {
      return const SizedBox.shrink();
    }

    if (order.hasReview) {
      return CustomerHistorySectionCard(
        title: 'Your review',
        icon: Icons.rate_review_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  i < (order.rating ?? 0).round()
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                );
              }),
            ),
            if (order.review != null && order.review!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(order.review!),
            ],
          ],
        ),
      );
    }

    if (!order.canSubmitReview) {
      return const SizedBox.shrink();
    }

    final submitting = state.status == CustomerHistoryStatus.reviewSubmitting;

    return CustomerHistorySectionCard(
      title: 'Review',
      icon: Icons.star_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Share your experience with this worker'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: submitting
                ? null
                : () => _showReviewDialog(context, order.id),
            icon: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_comment_outlined),
            label: const Text('Add review'),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledSection(
    BuildContext context,
    ServiceRequestModel order,
  ) {
    return CustomerHistorySectionCard(
      title: order.status == RequestStatus.cancelled
          ? 'Cancellation'
          : 'Rejection',
      icon: Icons.cancel_outlined,
      child: Text(
        order.cancellationReason?.trim().isNotEmpty == true
            ? order.cancellationReason!
            : 'No reason provided',
        style: TextStyle(color: AppTheme.errorColor.withValues(alpha: 0.9)),
      ),
    );
  }

  Future<void> _showReviewDialog(BuildContext context, String requestId) async {
    var rating = 0;
    final reviewController = TextEditingController();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return IconButton(
                        onPressed: () => setState(() => rating = star),
                        icon: Icon(
                          star <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Write your review (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: rating < 1
                      ? null
                      : () => Navigator.pop(dialogContext, true),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    if (submitted == true && context.mounted) {
      context.read<CustomerHistoryBloc>().add(
            SubmitCustomerReview(
              requestId: requestId,
              rating: rating.toDouble(),
              review: reviewController.text.trim(),
            ),
          );
    }
    reviewController.dispose();
  }
}

