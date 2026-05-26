import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/core/utils/currency_icon.dart';
import 'package:homeease/core/utils/image_helper.dart';
import 'package:homeease/models/services_model.dart';
import 'package:homeease/presentation/scheduled_booking/bloc/scheduled_booking_bloc.dart';
import 'package:homeease/presentation/scheduled_booking/bloc/scheduled_booking_event.dart';
import 'package:homeease/presentation/scheduled_booking/bloc/scheduled_booking_state.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_bloc.dart';
import 'package:homeease/presentation/customer_history/bloc/customer_history_event.dart';
import 'package:homeease/presentation/customer_history/repository/customer_history_repository.dart';
import 'package:homeease/presentation/customer_history/screens/scheduled_history_details_screen.dart';
import 'package:homeease/repositories/scheduled_booking_repository.dart';
import 'package:homeease/widgets/app_cache_image.dart';
import 'package:homeease/widgets/custom_app_bar.dart';
import 'package:homeease/widgets/custom_elevated_button.dart';

class ScheduledBookingScreen extends StatelessWidget {
  final ServicesModel service;

  const ScheduledBookingScreen({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ScheduledBookingBloc(
        repository: ScheduledBookingRepository(),
        initialService: service,
      )..add(const InitializeScheduledBookingForm()),
      child: const _ScheduledBookingFormView(),
    );
  }
}

class _ScheduledBookingFormView extends StatefulWidget {
  const _ScheduledBookingFormView();

  @override
  State<_ScheduledBookingFormView> createState() =>
      _ScheduledBookingFormViewState();
}

class _ScheduledBookingFormViewState extends State<_ScheduledBookingFormView> {
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageHelper = ImageHelper();

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScheduledBookingBloc, ScheduledBookingState>(
      listenWhen: (p, c) =>
          p.status != c.status ||
          p.address != c.address ||
          p.errorMessage != c.errorMessage ||
          p.successMessage != c.successMessage,
      listener: (context, state) {
        if (_addressController.text != state.address) {
          _addressController.text = state.address;
        }

        if (state.status == ScheduledBookingUiStatus.submitSuccess &&
            state.requestId != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider(
                create: (_) => CustomerHistoryBloc(
                  repository: CustomerHistoryRepository(),
                )
                  ..add(LoadScheduledHistoryDetails(state.requestId!))
                  ..add(const StartCustomerHistoryRealtime()),
                child: ScheduledHistoryDetailsScreen(
                  requestId: state.requestId!,
                ),
              ),
            ),
          );
        }

        if (state.errorMessage != null &&
            (state.status == ScheduledBookingUiStatus.submitError ||
                state.status == ScheduledBookingUiStatus.formReady)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final service = state.service;
        if (service == null) {
          return Scaffold(
            appBar: const CustomAppBar(title: 'Book service'),
            body: const Center(child: Text('Service not found')),
          );
        }

        final isSubmitting =
            state.status == ScheduledBookingUiStatus.submitting;

        return Scaffold(
          appBar: const CustomAppBar(title: 'Schedule booking'),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ServiceSummaryCard(service: service, state: state),
                const SizedBox(height: 20),
                _sectionTitle(context, 'Date & time'),
                const SizedBox(height: 8),
                _DateTimeRow(state: state),
                const SizedBox(height: 20),
                _sectionTitle(context, 'Address & location'),
                const SizedBox(height: 8),
                _LocationSection(
                  state: state,
                  addressController: _addressController,
                  onUseCurrentLocation: () => context
                      .read<ScheduledBookingBloc>()
                      .add(const LoadScheduledBookingLocation()),
                ),
                const SizedBox(height: 20),
                _sectionTitle(context, 'Description'),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Describe the issue or job details…',
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onChanged: (v) => context.read<ScheduledBookingBloc>().add(
                        UpdateScheduledBookingDescription(v),
                      ),
                ),
                const SizedBox(height: 20),
                _sectionTitle(context, 'Issue photos (optional)'),
                const SizedBox(height: 8),
                _IssueImagesSection(
                  images: state.issueImages,
                  onAdd: () async {
                    final file =
                        await _imageHelper.showImageSourceSheet(context);
                    if (file != null && context.mounted) {
                      context.read<ScheduledBookingBloc>().add(
                            AddScheduledBookingIssueImage(file),
                          );
                    }
                  },
                  onRemove: (index) => context
                      .read<ScheduledBookingBloc>()
                      .add(RemoveScheduledBookingIssueImage(index)),
                ),
                const SizedBox(height: 28),
                CustomElevatedButton(
                  text: isSubmitting ? 'Submitting…' : 'Submit booking',
                  isLoading: isSubmitting,
                  onPressed: state.canSubmit && !isSubmitting
                      ? () => context
                          .read<ScheduledBookingBloc>()
                          .add(const SubmitScheduledBooking())
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class _ServiceSummaryCard extends StatelessWidget {
  final ServicesModel service;
  final ScheduledBookingState state;

  const _ServiceSummaryCard({
    required this.service,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFixed = service.showFixedPrice;
    final priceLabel = isFixed
        ? '${CurrencyIcon.currencyIcon}${service.fixedJobRate!.toStringAsFixed(0)} fixed'
        : '${CurrencyIcon.currencyIcon}${service.perHourRate.toStringAsFixed(0)}/hr';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          if (service.mainImage != null && service.mainImage!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AppCacheImage(
                imageUrl: service.mainImage!,
                width: 72,
                height: 72,
                boxFit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.home_repair_service_rounded,
                color: theme.colorScheme.primary,
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (service.categoryTitle != null)
                  Text(
                    service.categoryTitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  priceLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  isFixed ? 'Fixed price job' : 'Hourly pricing',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  final ScheduledBookingState state;

  const _DateTimeRow({required this.state});

  String _formatDate(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return 'Select time';
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ScheduledBookingBloc>();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: state.selectedDate ?? now,
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
              );
              if (picked != null) {
                bloc.add(UpdateScheduledBookingDate(picked));
              }
            },
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(_formatDate(state.selectedDate)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: state.selectedTime ?? TimeOfDay.now(),
              );
              if (picked != null) {
                bloc.add(UpdateScheduledBookingTime(picked));
              }
            },
            icon: const Icon(Icons.access_time_rounded, size: 18),
            label: Text(_formatTime(state.selectedTime)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationSection extends StatelessWidget {
  final ScheduledBookingState state;
  final TextEditingController addressController;
  final VoidCallback onUseCurrentLocation;

  const _LocationSection({
    required this.state,
    required this.addressController,
    required this.onUseCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: addressController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Street address, building, etc.',
            filled: true,
            fillColor: theme.cardColor,
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onChanged: (v) => context.read<ScheduledBookingBloc>().add(
                UpdateScheduledBookingAddress(v),
              ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: state.locationLoading ? null : onUseCurrentLocation,
          icon: state.locationLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: Text(
            state.location != null
                ? 'Location: ${state.location!.latitude.toStringAsFixed(4)}, '
                    '${state.location!.longitude.toStringAsFixed(4)}'
                : 'Use current location',
          ),
        ),
        if (state.location == null && !state.locationLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Location is required. Tap the button above or enable GPS.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.warningColor,
              ),
            ),
          ),
      ],
    );
  }
}

class _IssueImagesSection extends StatelessWidget {
  final List<File> images;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _IssueImagesSection({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < images.length; i++)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      images[i],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(28, 28),
                        padding: EdgeInsets.zero,
                      ),
                      iconSize: 16,
                      onPressed: () => onRemove(i),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            if (images.length < 5)
              InkWell(
                onTap: onAdd,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: const Icon(Icons.add_photo_alternate_outlined),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Up to 5 photos. Upload failures will block submission.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
