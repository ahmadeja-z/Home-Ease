import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/network/connectivity_bloc.dart';
import 'package:homeease/core/network/connectivity_event.dart';
import 'package:homeease/core/network/connectivity_state.dart';
import 'package:homeease/core/widgets/no_internet_widget.dart';

/// Shows [NoInternetWidget] when offline with no cache; otherwise shows [child].
class CustomerOfflineGate extends StatelessWidget {
  final bool hasCachedData;
  final Widget child;
  final VoidCallback? onRetry;
  final String? offlineTitle;
  final String? offlineSubtitle;

  const CustomerOfflineGate({
    super.key,
    required this.hasCachedData,
    required this.child,
    this.onRetry,
    this.offlineTitle,
    this.offlineSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityBloc, ConnectivityState>(
      buildWhen: (p, c) =>
          p.isConnected != c.isConnected || p.isChecking != c.isChecking,
      builder: (context, connectivity) {
        if (connectivity.isConnected || hasCachedData) {
          return child;
        }

        return NoInternetWidget(
          isRetrying: connectivity.isChecking,
          title: offlineTitle,
          subtitle: offlineSubtitle,
          onRetry: () {
            context.read<ConnectivityBloc>().add(
                  const ConnectivityRetryRequested(),
                );
            onRetry?.call();
          },
        );
      },
    );
  }
}

/// Returns true when the device appears offline.
bool isCustomerOffline(BuildContext context) {
  return context.read<ConnectivityBloc>().state.isOffline;
}
