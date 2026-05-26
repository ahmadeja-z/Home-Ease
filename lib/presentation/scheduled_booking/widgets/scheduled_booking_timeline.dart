import 'package:flutter/material.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_section_card.dart';

/// Timeline for admin-assigned scheduled bookings.
class ScheduledBookingTimeline extends StatelessWidget {
  final ServiceRequestModel booking;

  const ScheduledBookingTimeline({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final steps = _buildSteps(booking);

    return CustomerHistorySectionCard(
      title: 'Worker timeline',
      icon: Icons.timeline_outlined,
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++)
            _TimelineTile(
              step: steps[i],
              isLast: i == steps.length - 1,
            ),
        ],
      ),
    );
  }

  List<_Step> _buildSteps(ServiceRequestModel o) {
    final steps = <_Step>[
      _Step(
        title: 'Booking submitted',
        time: o.createdAt,
        done: true,
        icon: Icons.send_outlined,
      ),
    ];

    if (o.status == RequestStatus.rejected) {
      steps.add(_Step(
        title: 'Rejected by admin',
        time: o.updatedAt,
        done: true,
        icon: Icons.block_outlined,
        color: AppTheme.errorColor,
      ));
      return steps;
    }

    steps.add(_Step(
      title: 'Admin approval',
      time: o.status == RequestStatus.pendingAdminApproval ? null : o.updatedAt,
      done: o.status != RequestStatus.pendingAdminApproval,
      icon: Icons.verified_user_outlined,
    ));

    if (o.status.index >= RequestStatus.assigned.index ||
        o.workerId != null) {
      steps.add(_Step(
        title: 'Worker assigned',
        time: null,
        done: o.workerId != null,
        icon: Icons.assignment_ind_outlined,
      ));
    }

    if (o.acceptedAt != null ||
        o.status.index >= RequestStatus.accepted.index) {
      steps.add(_Step(
        title: 'Worker accepted',
        time: o.acceptedAt,
        done: o.acceptedAt != null,
        icon: Icons.handshake_outlined,
      ));
    } else if (o.status == RequestStatus.assigned && o.workerId != null) {
      steps.add(_Step(
        title: 'Waiting for worker acceptance',
        time: null,
        done: false,
        icon: Icons.hourglass_empty_outlined,
      ));
    }

    if (_atLeast(o, RequestStatus.workerOnTheWay)) {
      steps.add(_Step(
        title: 'Worker on the way',
        time: o.acceptedAt,
        done: o.status.index >= RequestStatus.workerOnTheWay.index,
        icon: Icons.directions_car_outlined,
      ));
    }

    if (_atLeast(o, RequestStatus.arrived) || o.arrivedAt != null) {
      steps.add(_Step(
        title: 'Arrived',
        time: o.arrivedAt,
        done: o.arrivedAt != null,
        icon: Icons.place_outlined,
      ));
    }

    if (_atLeast(o, RequestStatus.inProgress) || o.startedAt != null) {
      steps.add(_Step(
        title: 'In progress',
        time: o.startedAt,
        done: o.startedAt != null,
        icon: Icons.build_outlined,
      ));
    }

    if (_atLeast(o, RequestStatus.billGenerated) ||
        o.billGeneratedAt != null) {
      steps.add(_Step(
        title: 'Bill generated',
        time: o.billGeneratedAt,
        done: o.billGeneratedAt != null,
        icon: Icons.receipt_outlined,
      ));
    }

    if (o.paymentStatus == PaymentStatus.paid || o.customerPaidAt != null) {
      steps.add(_Step(
        title: 'Payment confirmed',
        time: o.customerPaidAt,
        done: o.customerPaidAt != null,
        icon: Icons.payments_outlined,
      ));
    } else if (o.status == RequestStatus.billGenerated &&
        o.paymentStatus == PaymentStatus.unpaid) {
      steps.add(_Step(
        title: 'Awaiting payment confirmation',
        time: null,
        done: false,
        icon: Icons.account_balance_wallet_outlined,
        color: AppTheme.warningColor,
      ));
    }

    if (o.status == RequestStatus.completed || o.completedAt != null) {
      steps.add(_Step(
        title: 'Completed',
        time: o.completedAt,
        done: o.completedAt != null,
        icon: Icons.check_circle_outline,
      ));
    }

    if (o.status == RequestStatus.cancelled) {
      steps.add(_Step(
        title: 'Cancelled',
        time: o.updatedAt ?? o.completedAt,
        done: true,
        icon: Icons.cancel_outlined,
        color: AppTheme.errorColor,
      ));
    }

    return steps;
  }

  bool _atLeast(ServiceRequestModel o, RequestStatus min) {
    const flow = [
      RequestStatus.pendingAdminApproval,
      RequestStatus.approved,
      RequestStatus.assigned,
      RequestStatus.accepted,
      RequestStatus.workerOnTheWay,
      RequestStatus.arrived,
      RequestStatus.inProgress,
      RequestStatus.billGenerated,
      RequestStatus.completed,
    ];
    final a = flow.indexOf(o.status);
    final b = flow.indexOf(min);
    if (a < 0 || b < 0) return false;
    return a >= b;
  }
}

class _Step {
  final String title;
  final DateTime? time;
  final bool done;
  final IconData icon;
  final Color? color;

  _Step({
    required this.title,
    required this.time,
    required this.done,
    required this.icon,
    this.color,
  });
}

class _TimelineTile extends StatelessWidget {
  final _Step step;
  final bool isLast;

  const _TimelineTile({required this.step, required this.isLast});

  String _format(DateTime? d) {
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year} · '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = step.color ??
        (step.done ? AppTheme.successColor : theme.hintColor);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(step.icon, size: 18, color: color),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: color.withValues(alpha: 0.35),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: step.done ? null : theme.hintColor,
                    ),
                  ),
                  if (step.time != null)
                    Text(_format(step.time), style: theme.textTheme.bodySmall)
                  else if (!step.done)
                    Text(
                      'Pending',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
