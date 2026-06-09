import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/network/connectivity_bloc.dart';
import 'package:homeease/core/network/connectivity_state.dart';
import 'package:homeease/core/utils/snackbar_helper.dart';
import 'package:homeease/core/widgets/network_status_banner.dart';

/// Wraps customer tab content with offline banner and reconnect snackbar.
class CustomerConnectivityShell extends StatefulWidget {
  final Widget child;

  const CustomerConnectivityShell({super.key, required this.child});

  @override
  State<CustomerConnectivityShell> createState() =>
      _CustomerConnectivityShellState();
}

class _CustomerConnectivityShellState extends State<CustomerConnectivityShell> {
  int _lastReconnectToken = 0;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityBloc, ConnectivityState>(
      listenWhen: (p, c) => c.reconnectToken != p.reconnectToken,
      listener: (context, state) {
        if (state.reconnectToken <= _lastReconnectToken) return;
        _lastReconnectToken = state.reconnectToken;
        SnackBarHelper.showSuccess(
          context,
          title: 'Back online',
          subtitle: 'Refreshing your data…',
        );
      },
      child: Column(
        children: [
          const NetworkStatusBanner(),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}
