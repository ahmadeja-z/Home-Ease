import 'package:flutter/material.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/customer_history/utils/scheduled_request_helpers.dart';
import 'package:homeease/routes/route_names.dart';
import 'package:url_launcher/url_launcher.dart';

const _supportEmail = 'contact@homeease.com';

/// Primary status banner with optional countdown.
class ScheduledStatusBanner extends StatelessWidget {
  final ServiceRequestModel request;
  final Duration? countdownRemaining;
  final bool showNotStartedHint;

  const ScheduledStatusBanner({
    super.key,
    required this.request,
    this.countdownRemaining,
    this.showNotStartedHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = ScheduledRequestHelpers.statusBannerMessage(request);
    final isWarning = request.status == RequestStatus.overdue ||
        request.status == RequestStatus.workerNoShow ||
        showNotStartedHint;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning
            ? AppTheme.warningColor.withValues(alpha: 0.1)
            : theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning
              ? AppTheme.warningColor.withValues(alpha: 0.4)
              : theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isWarning ? Icons.info_outline : Icons.notifications_active_outlined,
                color: isWarning ? AppTheme.warningColor : theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (ScheduledRequestHelpers.shouldShowCountdown(request) &&
              countdownRemaining != null &&
              countdownRemaining! > Duration.zero) ...[
            const SizedBox(height: 12),
            _CountdownRow(remaining: countdownRemaining!),
          ],
        ],
      ),
    );
  }
}

class _CountdownRow extends StatelessWidget {
  final Duration remaining;

  const _CountdownRow({required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          'Arriving in ${ScheduledRequestHelpers.formatCountdown(remaining)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      ],
    );
  }
}

class ScheduledOverdueWarningCard extends StatelessWidget {
  final ServiceRequestModel request;
  final VoidCallback? onContactWorker;
  final VoidCallback? onContactSupport;

  const ScheduledOverdueWarningCard({
    super.key,
    required this.request,
    this.onContactWorker,
    this.onContactSupport,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = ScheduledRequestHelpers.calculateOverdueDuration(request);
    final worker = request.workerInfo;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
              const SizedBox(width: 8),
              Text(
                'Worker is late',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Worker is late for your scheduled service.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          _infoRow('Scheduled time', _formatTime(request.scheduledTime)),
          if (overdue != null)
            _infoRow('Time overdue', ScheduledRequestHelpers.formatDuration(overdue)),
          if (worker != null) ...[
            const SizedBox(height: 8),
            _infoRow('Worker', worker.name),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (worker?.phoneNumber?.isNotEmpty == true)
                OutlinedButton.icon(
                  onPressed: onContactWorker,
                  icon: const Icon(Icons.phone, size: 18),
                  label: const Text('Contact worker'),
                ),
              ElevatedButton.icon(
                onPressed: onContactSupport ?? () => _contactSupport(context),
                icon: const Icon(Icons.support_agent, size: 18),
                label: const Text('Contact support'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? d) {
    if (d == null) return '—';
    final local = d.toLocal();
    return '${local.day}/${local.month}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class ScheduledNoShowCard extends StatelessWidget {
  final ServiceRequestModel request;
  final bool isCancelling;
  final VoidCallback? onContactSupport;
  final VoidCallback? onCancel;

  const ScheduledNoShowCard({
    super.key,
    required this.request,
    this.isCancelling = false,
    this.onContactSupport,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_off_outlined, color: AppTheme.errorColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Worker did not attend',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Worker did not attend this scheduled job.',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Our team has been notified and will assign another worker or assist you.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onContactSupport ?? () => _contactSupport(context),
                icon: const Icon(Icons.support_agent_outlined),
                label: const Text('Contact support'),
              ),
              if (ScheduledRequestHelpers.canCustomerCancel(request))
                OutlinedButton.icon(
                  onPressed: isCancelling ? null : onCancel,
                  icon: isCancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel request'),
                ),
              Text(
                'You can wait for admin to reassign another worker.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ScheduledReassignedBanner extends StatelessWidget {
  final ServiceRequestModel request;

  const ScheduledReassignedBanner({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final worker = request.workerInfo;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.secondColor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.swap_horiz_rounded, color: AppTheme.secondColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request reassigned',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  request.status == RequestStatus.reassigned
                      ? 'Your request has been reassigned to another worker.'
                      : 'A new worker has been assigned to your scheduled job.',
                  style: theme.textTheme.bodyMedium,
                ),
                if (worker != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Current worker: ${worker.name}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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

Future<void> _contactSupport(BuildContext context) async {
  final uri = Uri(scheme: 'mailto', path: _supportEmail);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
    return;
  }
  if (context.mounted) {
    Navigator.pushNamed(context, RouteNames.faqs);
  }
}
