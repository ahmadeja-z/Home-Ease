import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:homeease/core/utils/currency_icon.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/widgets/app_cache_image.dart';
import 'package:homeease/widgets/image_gallery_viewer.dart';

class RequestInvoiceCard extends StatelessWidget {
  final ServiceRequestModel request;
  final bool isPaying;
  final bool canConfirmPayment;
  final VoidCallback onConfirmPaid;

  const RequestInvoiceCard({
    super.key,
    required this.request,
    required this.isPaying,
    required this.canConfirmPayment,
    required this.onConfirmPaid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Invoice',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _line('Accepted price (per hour)', _money(request.acceptedPrice)),
          _line(
            'Total hours',
            request.totalHours?.toStringAsFixed(1) ?? '—',
          ),
          _line('Labor charges', _money(request.laborCharges)),
          _line('Material charges', _money(request.materialCharges)),
          _line('Platform fee', _money(request.platformFee)),
          const Divider(height: 24),
          _line(
            'Final amount',
            _money(request.finalAmount),
            bold: true,
          ),
          _line(
            'Payment status',
            request.paymentStatus.displayLabel,
            bold: true,
          ),
          if (request.workerCompletionNote != null &&
              request.workerCompletionNote!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Worker completion note',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(request.workerCompletionNote!),
          ],
          if (request.completionImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Completion images',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: request.completionImages.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final url = request.completionImages[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ImageGalleryViewer(
                            imageUrls: request.completionImages,
                            initialIndex: index,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AppCacheImage(
                        imageUrl: url,
                        width: 72,
                        height: 72,
                        boxFit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (request.workerInfo != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                AppCacheImage(
                  imageUrl: request.workerInfo!.profileImage ?? '',
                  width: 36,
                  height: 36,
                  round: 18,
                  boxFit: BoxFit.cover,
                ),
                const SizedBox(width: 8),
                Text(
                  request.workerInfo!.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          if (canConfirmPayment) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isPaying ? null : onConfirmPaid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isPaying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'I Paid the Worker',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _money(double? amount) {
    if (amount == null) return '—';
    return '${CurrencyIcon.currencyIcon}${amount.toStringAsFixed(2)}';
  }
}

/// Logs once when the invoice overlay is shown.
void logInvoiceOpened(String requestId) {
  if (kDebugMode) {
    print('MapRequestsScreen - invoice opened: $requestId');
  }
}
