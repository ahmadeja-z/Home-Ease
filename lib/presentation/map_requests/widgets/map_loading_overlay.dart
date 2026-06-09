import 'package:flutter/material.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_state.dart';

class MapLoadingOverlay extends StatelessWidget {
  final MapRequestsState state;

  const MapLoadingOverlay({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (!state.isLoading &&
        state.status != MapRequestStatus.loadingNearby &&
        state.status != MapRequestStatus.cancellingRequest) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      color: Colors.black.withValues(alpha: 0.28),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _message(state.status),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _message(MapRequestStatus status) {
    switch (status) {
      case MapRequestStatus.requestSending:
        return 'Sending request…';
      case MapRequestStatus.cancellingRequest:
        return 'Cancelling request…';
      case MapRequestStatus.acceptingOffer:
        return 'Accepting offer…';
      case MapRequestStatus.paymentProcessing:
        return 'Confirming payment…';
      case MapRequestStatus.paymentSuccess:
        return 'Payment confirmed';
      case MapRequestStatus.paymentError:
        return 'Payment failed';
      default:
        return 'Finding nearby workers…';
    }
  }
}
