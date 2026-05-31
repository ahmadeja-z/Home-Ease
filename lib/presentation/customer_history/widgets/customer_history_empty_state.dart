import 'package:flutter/material.dart';
import 'package:homeease/core/theme/app_theme.dart';

class ScheduledHistoryEmptyState extends StatelessWidget {
  final VoidCallback? onRefresh;

  const ScheduledHistoryEmptyState({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note_rounded,
              size: 72,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No scheduled requests',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Book a service from the home screen to schedule a visit. '
              'Your requests will appear here for admin approval and tracking.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CustomerHistoryEmptyState extends StatelessWidget {
  final VoidCallback? onRefresh;

  const CustomerHistoryEmptyState({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 72,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No instant orders yet',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Map-based instant requests will appear here once you request a service.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRefresh != null) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CustomerHistoryNoResultsState extends StatelessWidget {
  final VoidCallback? onClearFilters;

  const CustomerHistoryNoResultsState({super.key, this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No matching results',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term or adjust your filters.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onClearFilters != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Clear search & filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CustomerHistoryErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const CustomerHistoryErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppTheme.errorColor),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class CustomerHistoryListSkeleton extends StatelessWidget {
  const CustomerHistoryListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 6,
      itemBuilder: (_, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: _HistoryCardSkeleton(),
      ),
    );
  }
}

/// Card-shaped loading placeholder with visible shimmer in light and dark themes.
class _HistoryCardSkeleton extends StatefulWidget {
  const _HistoryCardSkeleton();

  @override
  State<_HistoryCardSkeleton> createState() => _HistoryCardSkeletonState();
}

class _HistoryCardSkeletonState extends State<_HistoryCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;

    // Strong enough contrast on scaffold (light grey) and white cards.
    final base = isLight ? const Color(0xFFCBD5E1) : cs.onSurface.withValues(alpha: 0.14);
    final highlight =
        isLight ? const Color(0xFFE2E8F0) : cs.onSurface.withValues(alpha: 0.28);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            color: cs.onPrimary,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: isLight ? 0.7 : 0.45),
            ),
            boxShadow: isLight
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerBone(
                    width: 48,
                    height: 48,
                    borderRadius: 14,
                    progress: _controller.value,
                    base: base,
                    highlight: highlight,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ShimmerBone(
                          width: double.infinity,
                          height: 14,
                          borderRadius: 6,
                          progress: _controller.value,
                          base: base,
                          highlight: highlight,
                        ),
                        const SizedBox(height: 8),
                        _ShimmerBone(
                          width: 120,
                          height: 10,
                          borderRadius: 5,
                          progress: _controller.value,
                          base: base,
                          highlight: highlight,
                        ),
                        const SizedBox(height: 6),
                        _ShimmerBone(
                          width: 88,
                          height: 10,
                          borderRadius: 5,
                          progress: _controller.value,
                          base: base,
                          highlight: highlight,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ShimmerBone(
                    width: 56,
                    height: 22,
                    borderRadius: 11,
                    progress: _controller.value,
                    base: base,
                    highlight: highlight,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _ShimmerBone(
                    width: 72,
                    height: 12,
                    borderRadius: 6,
                    progress: _controller.value,
                    base: base,
                    highlight: highlight,
                  ),
                  const Spacer(),
                  _ShimmerBone(
                    width: 64,
                    height: 12,
                    borderRadius: 6,
                    progress: _controller.value,
                    base: base,
                    highlight: highlight,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerBone extends StatelessWidget {
  const _ShimmerBone({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.progress,
    required this.base,
    required this.highlight,
  });

  final double width;
  final double height;
  final double borderRadius;
  final double progress;
  final Color base;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(-1.2 + progress * 2.4, 0),
          end: Alignment(-0.2 + progress * 2.4, 0),
          colors: [base, highlight, base],
          stops: const [0.25, 0.5, 0.75],
        ),
      ),
    );
  }
}
