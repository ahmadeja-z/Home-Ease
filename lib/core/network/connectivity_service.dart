import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Checks network type via connectivity_plus and verifies real internet access.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> hasInternetConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (_isOfflineResult(results)) return false;

      final lookup = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 4),
        onTimeout: () => <InternetAddress>[],
      );
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('ConnectivityService.hasInternetConnection: $e');
      }
      return false;
    }
  }

  Stream<bool> get connectionStream async* {
    yield await hasInternetConnection();

    await for (final results in _connectivity.onConnectivityChanged) {
      if (_isOfflineResult(results)) {
        yield false;
        continue;
      }
      yield await hasInternetConnection();
    }
  }

  bool _isOfflineResult(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return results.every((r) => r == ConnectivityResult.none);
  }
}
