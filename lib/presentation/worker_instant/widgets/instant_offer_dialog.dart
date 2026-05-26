import 'package:flutter/material.dart';
import 'package:homeease/models/request_worker_offer_model.dart';
import 'package:homeease/models/service_request_model.dart';

/// Dialog shown to a worker when a new instant offer arrives (status == sent).
class InstantOfferDialog extends StatefulWidget {
  final RequestWorkerOfferModel offer;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  const InstantOfferDialog({
    super.key,
    required this.offer,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<InstantOfferDialog> createState() => _InstantOfferDialogState();
}

class _InstantOfferDialogState extends State<InstantOfferDialog> {
  bool _isLoading = false;

  ServiceRequestModel? get request => widget.offer.request;

  @override
  Widget build(BuildContext context) {
    final req = request;
    if (req == null) {
      return const AlertDialog(
        content: Text('Loading request details...'),
      );
    }

    return AlertDialog(
      title: const Text('New instant request'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _row(Icons.category, 'Category', req.categoryName ?? '—'),
            _row(Icons.location_on, 'Address', req.customerAddress ?? '—'),
            if (req.customerLocation != null)
              _row(
                Icons.map,
                'Location',
                '${req.customerLocation!.latitude.toStringAsFixed(5)}, '
                '${req.customerLocation!.longitude.toStringAsFixed(5)}',
              ),
            if (req.description != null && req.description!.isNotEmpty)
              _row(Icons.description, 'Description', req.description!),
            if (req.basePrice != null)
              _row(
                Icons.attach_money,
                'Customer per-hour price',
                '₦ ${req.basePrice!.toStringAsFixed(0)}/hr',
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    await widget.onReject();
                    if (context.mounted) Navigator.pop(context);
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          child: const Text('Reject', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  try {
                    await widget.onAccept();
                    if (context.mounted) Navigator.pop(context);
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Accept'),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
