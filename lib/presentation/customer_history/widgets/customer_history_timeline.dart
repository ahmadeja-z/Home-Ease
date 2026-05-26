import 'package:flutter/material.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/customer_history/widgets/customer_history_section_card.dart';

class CustomerHistoryTimeline extends StatelessWidget {
  final ServiceRequestModel order;

  const CustomerHistoryTimeline({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final steps = <_TimelineStep>[];

    steps.add(_TimelineStep(
      title: 'Request created',
      time: order.createdAt,
      done: true,
      icon: Icons.add_circle_outline,
    ));

    if (order.bookingType == RequestType.scheduled) {
      steps.add(_TimelineStep(
        title: 'Admin approval',
        time: order.status == RequestStatus.pendingAdminApproval
            ? null
            : order.updatedAt,
        done: order.status != RequestStatus.pendingAdminApproval &&
            order.status != RequestStatus.rejected,
        icon: Icons.verified_user_outlined,
      ));
      if (order.status.index >= RequestStatus.assigned.index ||
          order.workerId != null) {
        steps.add(_TimelineStep(
          title: 'Worker assigned',
          time: null,
          done: order.workerId != null,
          icon: Icons.assignment_ind_outlined,
        ));
      }
    }

    if (order.acceptedAt != null ||
        order.status.index >= RequestStatus.accepted.index) {
      steps.add(_TimelineStep(
        title: 'Worker accepted',
        time: order.acceptedAt,
        done: order.acceptedAt != null,
        icon: Icons.handshake_outlined,
      ));
    }

    if (_atLeast(order, RequestStatus.workerOnTheWay)) {
      steps.add(_TimelineStep(
        title: 'Worker on the way',
        time: order.acceptedAt,
        done: order.status.index >= RequestStatus.workerOnTheWay.index,
        icon: Icons.directions_car_outlined,
      ));
    }

    if (_atLeast(order, RequestStatus.arrived) || order.arrivedAt != null) {
      steps.add(_TimelineStep(
        title: 'Arrived',
        time: order.arrivedAt,
        done: order.arrivedAt != null,
        icon: Icons.place_outlined,
      ));
    }

    if (_atLeast(order, RequestStatus.inProgress) || order.startedAt != null) {
      steps.add(_TimelineStep(
        title: 'Job started',
        time: order.startedAt,
        done: order.startedAt != null,
        icon: Icons.build_outlined,
      ));
    }

    if (_atLeast(order, RequestStatus.billGenerated) ||
        order.billGeneratedAt != null) {
      steps.add(_TimelineStep(
        title: 'Bill generated',
        time: order.billGeneratedAt,
        done: order.billGeneratedAt != null,
        icon: Icons.receipt_outlined,
      ));
    }

    if (order.paymentStatus == PaymentStatus.paid || order.customerPaidAt != null) {
      steps.add(_TimelineStep(
        title: 'Payment confirmed',
        time: order.customerPaidAt,
        done: order.customerPaidAt != null,
        icon: Icons.payments_outlined,
      ));
    }

    if (order.status == RequestStatus.completed || order.completedAt != null) {
      steps.add(_TimelineStep(
        title: 'Completed',
        time: order.completedAt,
        done: order.completedAt != null,
        icon: Icons.check_circle_outline,
      ));
    }

    if (order.status == RequestStatus.cancelled) {
      steps.add(_TimelineStep(
        title: 'Cancelled',
        time: order.updatedAt ?? order.completedAt,
        done: true,
        icon: Icons.cancel_outlined,
        color: AppTheme.errorColor,
      ));
    }

    if (order.status == RequestStatus.rejected) {
      steps.add(_TimelineStep(
        title: 'Rejected',
        time: order.updatedAt,
        done: true,
        icon: Icons.block_outlined,
        color: AppTheme.errorColor,
      ));
    }

    return CustomerHistorySectionCard(
      title: 'Timeline',
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

  bool _atLeast(ServiceRequestModel o, RequestStatus min) {
    const order = RequestStatus.values;
    final a = order.indexOf(o.status);
    final b = order.indexOf(min);
    return a >= b;
  }
}

class _TimelineStep {
  final String title;
  final DateTime? time;
  final bool done;
  final IconData icon;
  final Color? color;

  _TimelineStep({
    required this.title,
    required this.time,
    required this.done,
    required this.icon,
    this.color,
  });
}

class _TimelineTile extends StatelessWidget {
  final _TimelineStep step;
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
                    Text(
                      _format(step.time),
                      style: theme.textTheme.bodySmall,
                    )
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
