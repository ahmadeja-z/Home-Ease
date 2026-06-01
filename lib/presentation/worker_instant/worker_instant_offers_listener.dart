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
  StreamSubscription<RequestWorkerOfferModel>? _incomingSubscription;
  StreamSubscription<RequestWorkerOfferModel>? _pendingSubscription;
  String? _shownOfferId;
  String? _pendingOfferId;
  OverlayEntry? _waitingOverlay;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _incomingSubscription?.cancel();
    _incomingSubscription = _repository.subscribeToWorkerInstantOffers().listen(
      _onOfferReceived,
      onError: (Object error) {
        if (kDebugMode) {
          print('WorkerInstantOffersListener - subscription error: $error');
        }
      },
    );

    _pendingSubscription?.cancel();
    _pendingSubscription =
        _repository.subscribeToPendingCustomerResponseUpdates().listen(
      _onPendingOfferUpdated,
      onError: (Object error) {
        if (kDebugMode) {
          print(
            'WorkerInstantOffersListener - pending subscription error: $error',
          );
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

  void _onPendingOfferUpdated(RequestWorkerOfferModel offer) {
    if (_pendingOfferId == null || _pendingOfferId != offer.id) return;

    if (offer.isPendingCustomerResponse) return;

    if (kDebugMode) {
      print(
        'WorkerInstantOffersListener - pending offer terminal: '
        '${offer.id} status=${offer.statusValue}',
      );
    }

    _clearWaitingState(message: _terminalMessage(offer));
  }

  String _terminalMessage(RequestWorkerOfferModel offer) {
    switch (offer.status) {
      case OfferStatus.customerCancelled:
        return 'Customer cancelled this request.';
      case OfferStatus.expired:
        return 'This offer is no longer available.';
      case OfferStatus.customerAccepted:
        return 'Customer accepted your offer.';
      case OfferStatus.rejected:
        return 'Offer closed.';
      default:
        return 'Offer updated.';
    }
  }

  void _showWaitingState(String offerId) {
    _pendingOfferId = offerId;
    _waitingOverlay?.remove();
    _waitingOverlay = null;

    if (!mounted) return;

    final overlay = Overlay.of(context);
    _waitingOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: 16,
        right: 16,
        bottom: MediaQuery.paddingOf(context).bottom + 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Waiting for customer response…',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: () => _clearWaitingState(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(_waitingOverlay!);
  }

  void _clearWaitingState({String? message}) {
    _waitingOverlay?.remove();
    _waitingOverlay = null;
    _pendingOfferId = null;

    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
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
              final updated = await _repository.acceptBasePrice(offer.id);
              if (kDebugMode) {
                print('WorkerInstantOffersListener - worker accepted: ${offer.id}');
              }
              _showWaitingState(updated.id);
            } catch (e) {
              final message = e.toString().contains('invalid_offer')
                  ? 'This request is no longer available.'
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
    _incomingSubscription?.cancel();
    _pendingSubscription?.cancel();
    _waitingOverlay?.remove();
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
