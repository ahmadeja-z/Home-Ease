import 'package:flutter/material.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_state.dart';

class MapEmptyStateBanner extends StatelessWidget {
  final MapRequestsState state;

  const MapEmptyStateBanner({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final errorMessage = state.errorMessage;

    final isDatabaseNotSetup = errorMessage?.contains('PGRST202') ?? false;
    final isTableNotSetup = errorMessage?.contains('PGRST204') ?? false;

    if (isDatabaseNotSetup || isTableNotSetup) {
      return _Banner(
        icon: Icons.settings_suggest_outlined,
        iconColor: AppTheme.warningColor,
        background: AppTheme.warningColor.withValues(alpha: 0.1),
        borderColor: AppTheme.warningColor.withValues(alpha: 0.3),
        title: 'Database setup required',
        body:
            'Run the SQL setup in supabase_setup_guide.md to enable map requests.',
      );
    }

    if (errorMessage != null) {
      return _Banner(
        icon: Icons.error_outline_rounded,
        iconColor: AppTheme.errorColor,
        background: AppTheme.errorColor.withValues(alpha: 0.08),
        borderColor: AppTheme.errorColor.withValues(alpha: 0.25),
        title: 'Something went wrong',
        body: errorMessage,
      );
    }

    if (state.nearbyWorkers.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return _Banner(
      icon: Icons.person_search_outlined,
      iconColor: cs.primary,
      background: cs.primaryContainer.withValues(alpha: 0.35),
      borderColor: cs.primary.withValues(alpha: 0.2),
      title: 'No online workers nearby',
      body: 'Workers in your area will appear on the map when they come online.',
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color background;
  final Color borderColor;
  final String title;
  final String body;

  const _Banner({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.borderColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
