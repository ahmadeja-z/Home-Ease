import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/network/connectivity_bloc.dart';
import 'package:homeease/core/network/connectivity_event.dart';
import 'package:homeease/core/network/connectivity_state.dart';
import 'package:homeease/core/theme/app_theme.dart';

/// Compact offline banner shown at the top of customer screens.
class NetworkStatusBanner extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const NetworkStatusBanner({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      buildWhen: (p, c) => p.isConnected != c.isConnected || p.isChecking != c.isChecking,
      builder: (context, state) {
        if (state.isConnected) return const SizedBox.shrink();

        final theme = Theme.of(context);

        return Container(
          margin: margin ?? EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.warningColor.withValues(alpha: 0.12),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.warningColor.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 20,
                color: AppTheme.warningColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No internet connection',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Some data may be outdated.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: state.isChecking
                    ? null
                    : () => context
                        .read<ConnectivityBloc>()
                        .add(const ConnectivityRetryRequested()),
                child: Text(state.isChecking ? '…' : 'Retry'),
              ),
            ],
          ),
        );
      },
    );
  }
}
