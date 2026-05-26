import 'package:flutter/material.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/presentation/map_requests/widgets/request_invoice_card.dart';

/// Invoice + “I Paid the Worker” for scheduled requests in history details.
class ScheduledRequestInvoiceCard extends StatelessWidget {
  final ServiceRequestModel request;
  final bool isPaying;
  final VoidCallback onConfirmPaid;

  const ScheduledRequestInvoiceCard({
    super.key,
    required this.request,
    required this.isPaying,
    required this.onConfirmPaid,
  });

  @override
  Widget build(BuildContext context) {
    if (!request.canCustomerConfirmPayment &&
        request.status != RequestStatus.billGenerated) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: RequestInvoiceCard(
        request: request,
        isPaying: isPaying,
        canConfirmPayment: request.canCustomerConfirmPayment,
        onConfirmPaid: onConfirmPaid,
      ),
    );
  }
}
