import 'package:flutter/material.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_state.dart';
import 'package:homeease/presentation/map_requests/widgets/map_overlay_card.dart';
import 'package:homeease/widgets/app_cache_image.dart';

class RequestTrackingCard extends StatelessWidget {
  final ServiceRequestModel request;
  final MapRequestStatus status;
  final bool waitingForOffers;
  final bool hasWorkerOffers;
  final bool canCancel;
  final bool isCancelling;
  final VoidCallback onCancel;
  final VoidCallback onCancelNotAllowed;

  const RequestTrackingCard({
    super.key,
    required this.request,
    required this.status,
    required this.waitingForOffers,
    required this.hasWorkerOffers,
    required this.canCancel,
    required this.isCancelling,
    required this.onCancel,
    required this.onCancelNotAllowed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final statusColor = _statusColor(request.status);

    return MapOverlayCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _statusIcon(request.status),
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service status',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    Text(
                      _statusTitle(),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (waitingForOffers) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: cs.outline.withValues(alpha: 0.2),
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Waiting for worker offers…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (request.basePrice != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Your offer: ${request.basePrice!.toStringAsFixed(0)}/hr',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.secondary,
                  ),
                ),
              ),
          ],
          const SizedBox(height: 14),
          _InstantStatusStepper(status: request.status),
          if (request.workerInfo != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  AppCacheImage(
                    imageUrl: request.workerInfo!.profileImage ?? '',
                    width: 44,
                    height: 44,
                    round: 22,
                    boxFit: BoxFit.cover,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.workerInfo!.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (request.workerInfo!.phoneNumber != null)
                          Text(
                            request.workerInfo!.phoneNumber!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (request.workerInfo!.rating != null)
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: AppTheme.secondColor,
                          size: 18,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          request.workerInfo!.rating!.toStringAsFixed(1),
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
          if (canCancel || request.status == RequestStatus.accepted) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isCancelling
                    ? null
                    : (canCancel ? onCancel : onCancelNotAllowed),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                  side: BorderSide(
                    color: AppTheme.errorColor.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  hasWorkerOffers ? 'Close request' : 'Cancel request',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusTitle() {
    if (waitingForOffers) return 'Waiting for worker offers…';
    switch (request.status) {
      case RequestStatus.pending:
        return 'Review worker offers';
      case RequestStatus.inProgress:
        return 'Job in progress';
      case RequestStatus.billGenerated:
        return 'Invoice ready';
      default:
        return request.getStatusString();
    }
  }

  Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
      case RequestStatus.pendingAdminApproval:
        return AppTheme.warningColor;
      case RequestStatus.accepted:
      case RequestStatus.workerOnTheWay:
        return AppTheme.accentColor;
      case RequestStatus.arrived:
      case RequestStatus.inProgress:
      case RequestStatus.completed:
        return AppTheme.successColor;
      case RequestStatus.cancelled:
      case RequestStatus.rejected:
      case RequestStatus.workerNoShow:
        return AppTheme.errorColor;
      default:
        return AppTheme.mainColor;
    }
  }

  IconData _statusIcon(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Icons.hourglass_top_rounded;
      case RequestStatus.accepted:
        return Icons.check_circle_outline_rounded;
      case RequestStatus.workerOnTheWay:
        return Icons.directions_car_filled_outlined;
      case RequestStatus.arrived:
        return Icons.location_on_outlined;
      case RequestStatus.inProgress:
        return Icons.handyman_outlined;
      case RequestStatus.billGenerated:
        return Icons.receipt_long_outlined;
      case RequestStatus.completed:
        return Icons.done_all_rounded;
      case RequestStatus.cancelled:
      case RequestStatus.rejected:
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }
}

class _InstantStatusStepper extends StatelessWidget {
  final RequestStatus status;

  const _InstantStatusStepper({required this.status});

  static const _steps = [
    RequestStatus.pending,
    RequestStatus.accepted,
    RequestStatus.workerOnTheWay,
    RequestStatus.inProgress,
    RequestStatus.billGenerated,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final current = _steps.indexOf(status);
    final activeIndex = current < 0 ? 0 : current;

    return Row(
      children: List.generate(_steps.length, (index) {
        final isActive = index <= activeIndex;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < _steps.length - 1 ? 4 : 0),
            height: 4,
            decoration: BoxDecoration(
              color: isActive
                  ? cs.primary
                  : cs.outline.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
