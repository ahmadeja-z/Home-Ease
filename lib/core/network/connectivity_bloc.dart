import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_event.dart';
import 'connectivity_service.dart';
import 'connectivity_state.dart';

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final ConnectivityService service;
  StreamSubscription<bool>? _subscription;

  ConnectivityBloc({required this.service}) : super(const ConnectivityState()) {
    on<ConnectivityStarted>(_onStarted);
    on<ConnectivityChanged>(_onChanged);
    on<ConnectivityRetryRequested>(_onRetry);
  }

  Future<void> _onStarted(
    ConnectivityStarted event,
    Emitter<ConnectivityState> emit,
  ) async {
    emit(state.copyWith(isChecking: true));
    final connected = await service.hasInternetConnection();
    emit(
      state.copyWith(
        isConnected: connected,
        isChecking: false,
        lastCheckedAt: DateTime.now(),
      ),
    );

    await _subscription?.cancel();
    _subscription = service.connectionStream.listen(
      (connected) => add(ConnectivityChanged(connected)),
    );
  }

  void _onChanged(
    ConnectivityChanged event,
    Emitter<ConnectivityState> emit,
  ) {
    final wasOffline = !state.isConnected;
    final nowOnline = event.isConnected;

    emit(
      state.copyWith(
        isConnected: event.isConnected,
        isChecking: false,
        lastCheckedAt: DateTime.now(),
        reconnectToken: wasOffline && nowOnline
            ? state.reconnectToken + 1
            : state.reconnectToken,
      ),
    );
  }

  Future<void> _onRetry(
    ConnectivityRetryRequested event,
    Emitter<ConnectivityState> emit,
  ) async {
    final wasOffline = !state.isConnected;
    emit(state.copyWith(isChecking: true));
    final connected = await service.hasInternetConnection();
    emit(
      state.copyWith(
        isConnected: connected,
        isChecking: false,
        lastCheckedAt: DateTime.now(),
        reconnectToken: wasOffline && connected
            ? state.reconnectToken + 1
            : state.reconnectToken,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
