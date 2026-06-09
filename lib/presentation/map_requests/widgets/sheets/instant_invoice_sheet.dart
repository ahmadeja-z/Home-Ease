import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_bloc.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_event.dart';
import 'package:homeease/presentation/map_requests/bloc/map_requests_state.dart';
import 'package:homeease/presentation/map_requests/widgets/dialogs/confirm_payment_dialog.dart';
import 'package:homeease/presentation/map_requests/widgets/instant_request_invoice_card.dart';

/// Draggable bottom sheet for instant request invoice + payment.
class InstantInvoiceSheet {
  InstantInvoiceSheet._();

  static Future<void> show(BuildContext context) async {
    final bloc = context.read<MapRequestsBloc>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: bloc,
          child: BlocBuilder<MapRequestsBloc, MapRequestsState>(
            buildWhen: (previous, current) =>
                previous.activeRequest != current.activeRequest ||
                previous.isPayingInvoice != current.isPayingInvoice ||
                previous.canSubmitPayment != current.canSubmitPayment,
            builder: (context, state) {
              final request = state.activeRequest;
              if (request == null) return const SizedBox.shrink();

              return DraggableScrollableSheet(
                initialChildSize: 0.82,
                minChildSize: 0.45,
                maxChildSize: 0.95,
                builder: (_, scrollController) {
                  final cs = Theme.of(context).colorScheme;
                  return Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: cs.outline.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            child: InstantRequestInvoiceCard(
                              request: request,
                              isPaying: state.isPayingInvoice,
                              canConfirmPayment: state.canSubmitPayment,
                              onConfirmPaid: () => ConfirmPaymentDialog.show(
                                context,
                                request: request,
                                onConfirm: () => bloc.add(
                                  PayInvoiceRequested(request.id),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );

    bloc.add(const CloseInvoiceDialog());
  }
}
