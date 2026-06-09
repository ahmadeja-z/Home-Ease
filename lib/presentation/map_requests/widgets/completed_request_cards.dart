import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_bloc.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_event.dart';
import 'package:homeease/presentation/map_requests/widgets/map_overlay_card.dart';

class CancelledRequestCard extends StatelessWidget {
  final ServiceRequestModel request;
  final VoidCallback onDismiss;

  const CancelledRequestCard({
    super.key,
    required this.request,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return MapOverlayCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cancel_outlined,
              color: AppTheme.errorColor,
              size: 30,
            ),
          ),
          Text(
            'Request cancelled',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            request.cancellationReason?.isNotEmpty == true
                ? request.cancellationReason!
                : 'Your instant request was cancelled. All worker offers are closed.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.65),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: onDismiss,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Back to map'),
          ),
        ],
      ),
    );
  }
}

class CompletedRequestCard extends StatefulWidget {
  final ServiceRequestModel request;
  final VoidCallback onReload;
  final VoidCallback onRequestNewService;
  final VoidCallback onDismiss;

  const CompletedRequestCard({
    super.key,
    required this.request,
    required this.onReload,
    required this.onRequestNewService,
    required this.onDismiss,
  });

  @override
  State<CompletedRequestCard> createState() => _CompletedRequestCardState();
}

class _CompletedRequestCardState extends State<CompletedRequestCard> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _submittingReview = false;
  bool _reviewSubmitted = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  bool get _hasExistingReview =>
      widget.request.rating != null && widget.request.rating! > 0;

  Future<void> _submitReview() async {
    if (_rating < 1 ||
        _submittingReview ||
        _reviewSubmitted ||
        _hasExistingReview) {
      return;
    }

    setState(() => _submittingReview = true);

    context.read<MapRequestsBloc>().add(
          CompleteJobEvent(
            requestId: widget.request.id,
            rating: _rating.toDouble(),
            review: _reviewController.text.trim().isEmpty
                ? null
                : _reviewController.text.trim(),
          ),
        );

    if (mounted) {
      setState(() {
        _submittingReview = false;
        _reviewSubmitted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final alreadyRated = _hasExistingReview || _reviewSubmitted;

    return MapOverlayCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.successColor,
              size: 32,
            ),
          ),
          Text(
            'Job completed',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You confirmed payment to the worker. Thank you!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
          if (!alreadyRated) ...[
            const SizedBox(height: 18),
            Text(
              'Rate your experience',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = starIndex),
                  icon: Icon(
                    starIndex <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppTheme.secondColor,
                    size: 34,
                  ),
                );
              }),
            ),
            TextField(
              controller: _reviewController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Optional review',
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _rating < 1 || _submittingReview ? null : _submitReview,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _submittingReview
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit rating'),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Thanks for your feedback!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onReload,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reload'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.onRequestNewService,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New request'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextButton(onPressed: widget.onDismiss, child: const Text('Done')),
        ],
      ),
    );
  }
}
