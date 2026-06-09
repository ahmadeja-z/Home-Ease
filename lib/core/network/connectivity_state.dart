import 'package:equatable/equatable.dart';

class ConnectivityState extends Equatable {
  final bool isConnected;
  final bool isChecking;
  final DateTime? lastCheckedAt;
  final int reconnectToken;

  const ConnectivityState({
    this.isConnected = true,
    this.isChecking = false,
    this.lastCheckedAt,
    this.reconnectToken = 0,
  });

  bool get isOffline => !isConnected;

  ConnectivityState copyWith({
    bool? isConnected,
    bool? isChecking,
    DateTime? lastCheckedAt,
    int? reconnectToken,
  }) {
    return ConnectivityState(
      isConnected: isConnected ?? this.isConnected,
      isChecking: isChecking ?? this.isChecking,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      reconnectToken: reconnectToken ?? this.reconnectToken,
    );
  }

  @override
  List<Object?> get props =>
      [isConnected, isChecking, lastCheckedAt, reconnectToken];
}
