import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/network/connectivity_bloc.dart';
import 'package:homeease/core/network/connectivity_state.dart';

/// Calls [onReconnect] when connectivity is restored after being offline.
class CustomerReconnectListener extends StatefulWidget {
  final VoidCallback onReconnect;
  final Widget child;

  const CustomerReconnectListener({
    super.key,
    required this.onReconnect,
    required this.child,
  });

  @override
  State<CustomerReconnectListener> createState() =>
      _CustomerReconnectListenerState();
}

class _CustomerReconnectListenerState extends State<CustomerReconnectListener> {
  int _lastToken = 0;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityBloc, ConnectivityState>(
      listenWhen: (p, c) => c.reconnectToken != p.reconnectToken,
      listener: (context, state) {
        if (state.reconnectToken <= _lastToken) return;
        _lastToken = state.reconnectToken;
        widget.onReconnect();
      },
      child: widget.child,
    );
  }
}
