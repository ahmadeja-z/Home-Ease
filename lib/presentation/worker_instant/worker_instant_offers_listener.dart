import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:homeease/models/request_worker_offer_model.dart';
import 'package:homeease/presentation/worker_instant/widgets/instant_offer_dialog.dart';
import 'package:homeease/repositories/worker_instant_repository.dart';

/// Wrap the worker home shell with this widget to receive instant offers in realtime.
///
/// Example:
/// ```dart
/// WorkerInstantOffersListener(
///   child: WorkerHomeScreen(),
/// )
/// ```
class WorkerInstantOffersListener extends StatefulWidget {
  final Widget child;

  const WorkerInstantOffersListener({super.key, required this.child});

  @override
  State<WorkerInstantOffersListener> createState() =>
      _WorkerInstantOffersListenerState();
}

class _WorkerInstantOffersListenerState extends State<WorkerInstantOffersListener> {
  final WorkerInstantRepository _repository = WorkerInstantRepository();
  StreamSubscription<RequestWorkerOfferModel>? _subscription;
  String? _shownOfferId;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _subscription?.cancel();
    _subscription = _repository.subscribeToWorkerInstantOffers().listen(
      _onOfferReceived,
      onError: (Object error) {
        if (kDebugMode) {
          print('WorkerInstantOffersListener - subscription error: $error');
        }
      },
    );
  }

  Future<void> _onOfferReceived(RequestWorkerOfferModel offer) async {
    if (!mounted || offer.status != OfferStatus.sent) return;
    if (_shownOfferId == offer.id) return;

    if (kDebugMode) {
      print('WorkerInstantOffersListener - realtime offer received: ${offer.id}');
    }

    _shownOfferId = offer.id;
    await _showOfferDialog(offer);
  }

  Future<void> _showOfferDialog(RequestWorkerOfferModel offer) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return InstantOfferDialog(
          offer: offer,
          onReject: () async {
            await _repository.rejectInstantRequest(offer.id);
            if (kDebugMode) {
              print('WorkerInstantOffersListener - worker rejected: ${offer.id}');
            }
          },
          onAccept: () async {
            try {
              await _repository.acceptInstantRequest(
                requestId: offer.requestId,
                offerId: offer.id,
              );
              if (kDebugMode) {
                print('WorkerInstantOffersListener - worker accepted: ${offer.id}');
              }
            } catch (e) {
              final message = e.toString().contains('already accepted')
                  ? 'Request already accepted by another worker'
                  : 'Accept failed: $e';
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
              rethrow;
            }
          },
        );
      },
    );

    _shownOfferId = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
