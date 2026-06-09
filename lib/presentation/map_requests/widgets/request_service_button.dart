import 'package:flutter/material.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_state.dart';

class RequestServiceButton extends StatelessWidget {
  final MapRequestsState state;
  final double bottomInset;
  final bool isOffline;
  final VoidCallback onPressed;

  const RequestServiceButton({
    super.key,
    required this.state,
    required this.bottomInset,
    this.isOffline = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (state.hasActiveRequest ||
        state.showCompleted ||
        state.showCancelled) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDatabaseNotSetup = state.errorMessage?.contains('PGRST202') ?? false;
    final isTableNotSetup = state.errorMessage?.contains('PGRST204') ?? false;
    final disabled = isDatabaseNotSetup || isTableNotSetup || isOffline;

    String label = 'Request Service';
    if (isOffline) {
      label = 'Offline';
    } else if (disabled) {
      label = 'Setup Required';
    }

    return Positioned(
      bottom: bottomInset,
      left: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOffline)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Internet is required to send a service request.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: disabled
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [cs.primary, cs.secondary],
                    ),
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Material(
              color: disabled ? Colors.grey : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: disabled ? null : onPressed,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        disabled
                            ? (isOffline
                                ? Icons.wifi_off_rounded
                                : Icons.build_circle_outlined)
                            : Icons.add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
