import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thrown when a request fails due to connectivity issues.
class NetworkFailure implements Exception {
  final String message;

  const NetworkFailure([
    this.message =
        'No internet connection. Please check your connection and try again.',
  ]);

  @override
  String toString() => message;
}

const _networkPatterns = [
  'socketexception',
  'clientexception',
  'failed host lookup',
  'network is unreachable',
  'connection refused',
  'connection closed',
  'connection reset',
  'connection timed out',
  'timed out',
  'no address associated with hostname',
  'network error',
  'handshake exception',
  'unable to resolve host',
];

/// Returns true when [error] indicates loss of connectivity.
bool isNetworkError(Object error) {
  if (error is NetworkFailure) return true;
  if (error is SocketException) return true;
  if (error is TimeoutException) return true;
  if (error is HttpException) return true;

  if (error is DioException) {
    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.error is SocketException;
  }

  if (error is PostgrestException) {
    final code = error.code?.toLowerCase() ?? '';
    if (code.contains('timeout') || code.contains('network')) return true;
  }

  final text = error.toString().toLowerCase();
  return _networkPatterns.any(text.contains);
}

/// Maps any error to a customer-safe message (never raw exception text).
String mapCustomerErrorMessage(Object error) {
  if (isNetworkError(error)) {
    return const NetworkFailure().message;
  }
  if (error is PostgrestException) {
    return 'Something went wrong. Please try again.';
  }
  if (error is NetworkFailure) {
    return error.message;
  }
  return 'Something went wrong. Please try again.';
}

/// True when [message] is the standard offline customer message.
bool isNetworkFailureMessage(String? message) {
  if (message == null) return false;
  return message == const NetworkFailure().message;
}

/// Wraps repository calls and converts network errors to [NetworkFailure].
Future<T> guardNetworkCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } catch (error) {
    if (isNetworkError(error)) {
      throw const NetworkFailure();
    }
    rethrow;
  }
}
