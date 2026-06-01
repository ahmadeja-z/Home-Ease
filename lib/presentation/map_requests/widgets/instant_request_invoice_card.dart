import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:homeease/core/utils/currency_icon.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/widgets/app_cache_image.dart';
import 'package:homeease/widgets/image_gallery_viewer.dart';

/// Invoice shown on the map when an instant request reaches `bill_generated`.
/// All amounts are read from [ServiceRequestModel] — never recalculated here.
class InstantRequestInvoiceCard extends StatelessWidget {
  final ServiceRequestModel request;
  final bool isPaying;
  final bool canConfirmPayment;
  final VoidCallback onConfirmPaid;

  const InstantRequestInvoiceCard({
    super.key,
    required this.request,
    required this.isPaying,
    required this.canConfirmPayment,
    required this.onConfirmPaid,
  });

  bool get _hasSystemBreakdown =>
      request.commissionPercentage != null ||
      request.commissionBaseAmount != null ||
      request.platformCommission != null ||
      request.workerEarning != null;

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
          const Divider(height: 24),
          _line(
            'Amount to pay',
            _money(request.finalAmount),
            bold: true,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Labor charges + material charges',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
          if (_hasSystemBreakdown) ...[
            const SizedBox(height: 4),
            Text(
              'Platform details',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            if (request.commissionPercentage != null)
              _systemLine(
                'Platform commission percentage',
                '${request.commissionPercentage!.toStringAsFixed(1)}%',
              ),
            if (request.commissionBaseAmount != null)
              _systemLine(
                'Commission base amount',
                _money(request.commissionBaseAmount),
              ),
            if (request.platformCommission != null)
              _systemLine(
                'Platform commission',
                _money(request.platformCommission),
              ),
            if (request.workerEarning != null)
              _systemLine('Worker earning', _money(request.workerEarning)),
            const SizedBox(height: 4),
          ],
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

  Widget _systemLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
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

/// Logs once when the instant invoice dialog is opened.
void logInstantInvoiceOpened(ServiceRequestModel request) {
  if (kDebugMode) {
    print(
      'MapRequestsScreen - instant invoice opened: ${request.id} '
      'final=${request.finalAmount} '
      'labor=${request.laborCharges} material=${request.materialCharges} '
      'commission%=${request.commissionPercentage} '
      'platformCommission=${request.platformCommission} '
      'workerEarning=${request.workerEarning}',
    );
  }
}

/// Persistent prompt when a bill is ready — survives dialog dismiss and tab changes.
class InvoiceReadyCard extends StatelessWidget {
  final ServiceRequestModel request;
  final bool isOpening;
  final VoidCallback onViewInvoice;

  const InvoiceReadyCard({
    super.key,
    required this.request,
    required this.isOpening,
    required this.onViewInvoice,
  });

  String _money(double amount) {
    return '${CurrencyIcon.currencyIcon}${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primaryContainer.withValues(alpha: 0.55),
            cs.surfaceContainerHighest.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: cs.primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: cs.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invoice Ready',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Worker has submitted the bill.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount to pay',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                _money(request.finalAmount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isOpening ? null : onViewInvoice,
              icon: isOpening
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Icon(Icons.visibility_outlined),
              label: Text(isOpening ? 'Opening…' : 'View Invoice'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'You can review and pay anytime.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
