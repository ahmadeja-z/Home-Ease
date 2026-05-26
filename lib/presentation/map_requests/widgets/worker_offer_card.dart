import 'package:flutter/material.dart';
import 'package:homeease/core/utils/currency_icon.dart';
import 'package:homeease/models/customer_worker_offer_display.dart';
import 'package:homeease/models/request_worker_offer_model.dart';
import 'package:homeease/widgets/app_cache_image.dart';

class WorkerOfferCard extends StatelessWidget {
  final CustomerWorkerOfferDisplay display;
  final bool isAccepting;
  final VoidCallback onAccept;

  const WorkerOfferCard({
    super.key,
    required this.display,
    required this.isAccepting,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final offer = display.offer;
    final priceLabel = offer.offeredPrice != null
        ? '${CurrencyIcon.currencyIcon}${offer.offeredPrice!.toStringAsFixed(0)}/hr'
        : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppCacheImage(
                  imageUrl: display.profileImage ?? '',
                  width: 48,
                  height: 48,
                  round: 24,
                  boxFit: BoxFit.cover,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        display.workerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (display.rating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              display.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      if (display.phoneNumber != null &&
                          display.phoneNumber!.isNotEmpty)
                        Text(
                          display.phoneNumber!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      priceLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (offer.status == OfferStatus.counterOffer)
                      Text(
                        'Counter offer',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange[700],
                        ),
                      )
                    else
                      Text(
                        'Accepted your price',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[700],
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (offer.workerMessage != null &&
                offer.workerMessage!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  offer.workerMessage!,
                  style: TextStyle(color: Colors.grey[800], fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isAccepting || !display.canAccept ? null : onAccept,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isAccepting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Accept offer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
