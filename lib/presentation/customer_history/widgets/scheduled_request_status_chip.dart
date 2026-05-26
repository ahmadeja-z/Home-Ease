import 'package:flutter/material.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/models/service_request_model.dart';

class ScheduledRequestStatusChip extends StatelessWidget {
  final RequestStatus status;

  const ScheduledRequestStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = _style(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color, String) _style(RequestStatus status) {
    switch (status) {
      case RequestStatus.pendingAdminApproval:
        return (
          AppTheme.warningColor,
          AppTheme.warningColor.withValues(alpha: 0.12),
          'Awaiting admin',
        );
      case RequestStatus.approved:
        return (
          AppTheme.mainColor,
          AppTheme.mainColor.withValues(alpha: 0.12),
          'Approved',
        );
      case RequestStatus.assigned:
        return (
          AppTheme.secondColor,
          AppTheme.secondColor.withValues(alpha: 0.12),
          'Assigned',
        );
      case RequestStatus.accepted:
        return (
          AppTheme.mainColor,
          AppTheme.mainColor.withValues(alpha: 0.12),
          'Accepted',
        );
      case RequestStatus.workerOnTheWay:
        return (
          AppTheme.secondColor,
          AppTheme.secondColor.withValues(alpha: 0.12),
          'On the way',
        );
      case RequestStatus.arrived:
        return (
          AppTheme.secondColor,
          AppTheme.secondColor.withValues(alpha: 0.12),
          'Arrived',
        );
      case RequestStatus.inProgress:
        return (
          AppTheme.accentColor,
          AppTheme.accentColor.withValues(alpha: 0.12),
          'In progress',
        );
      case RequestStatus.billGenerated:
        return (
          AppTheme.accentDarkColor,
          AppTheme.accentColor.withValues(alpha: 0.15),
          'Invoice ready',
        );
      case RequestStatus.paid:
        return (
          AppTheme.successColor,
          AppTheme.successColor.withValues(alpha: 0.12),
          'Paid',
        );
      case RequestStatus.completed:
        return (
          AppTheme.successColor,
          AppTheme.successColor.withValues(alpha: 0.12),
          'Completed',
        );
      case RequestStatus.cancelled:
        return (
          AppTheme.errorColor,
          AppTheme.errorColor.withValues(alpha: 0.12),
          'Cancelled',
        );
      case RequestStatus.rejected:
        return (
          AppTheme.errorColor,
          AppTheme.errorColor.withValues(alpha: 0.12),
          'Rejected',
        );
      case RequestStatus.overdue:
        return (
          AppTheme.errorColor,
          AppTheme.errorColor.withValues(alpha: 0.12),
          'Overdue',
        );
      case RequestStatus.workerNoShow:
        return (
          AppTheme.errorColor,
          AppTheme.errorColor.withValues(alpha: 0.12),
          'No-show',
        );
      case RequestStatus.reassigned:
        return (
          AppTheme.secondColor,
          AppTheme.secondColor.withValues(alpha: 0.12),
          'Reassigned',
        );
      case RequestStatus.pending:
        return (
          Colors.grey,
          Colors.grey.withValues(alpha: 0.12),
          'Pending',
        );
      case RequestStatus.workSubmitted:
        return (
          Colors.grey,
          Colors.grey.withValues(alpha: 0.12),
          'Work submitted',
        );
    }
  }
}
