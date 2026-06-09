import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/core/widgets/customer_offline_gate.dart';
import 'package:homeease/core/widgets/customer_screen_shell.dart';
import 'package:homeease/core/widgets/offline_action_hint.dart';
import 'package:homeease/core/utils/app_validators.dart';
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
import 'package:homeease/presentation/location_picker/location_picker_screen.dart';
import 'package:homeease/presentation/location_picker/models/location_picker_result.dart';
import 'package:homeease/widgets/custom_elevated_button.dart';
import 'package:homeease/widgets/custom_text_form_field.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────────
// Form view
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduledBookingFormView extends StatefulWidget {
  const _ScheduledBookingFormView();

  @override
  State<_ScheduledBookingFormView> createState() =>
      _ScheduledBookingFormViewState();
}

class _ScheduledBookingFormViewState extends State<_ScheduledBookingFormView>
    with SingleTickerProviderStateMixin {
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageHelper = ImageHelper();
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    _fadeController.dispose();
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
        if (!context.mounted) return;

        if (_addressController.text != state.address) {
          _addressController.text = state.address;
        }

        if (state.status == ScheduledBookingUiStatus.submitSuccess &&
            state.requestId != null) {
          final requestId = state.requestId!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => BlocProvider(
                  create: (_) => CustomerHistoryBloc(
                    repository: CustomerHistoryRepository(),
                  )
                    ..add(LoadScheduledHistoryDetails(requestId))
                    ..add(const StartCustomerHistoryRealtime()),
                  child: ScheduledHistoryDetailsScreen(requestId: requestId),
                ),
              ),
            );
          });
          return;
        }

        if (state.errorMessage != null &&
            (state.status == ScheduledBookingUiStatus.submitError ||
                state.status == ScheduledBookingUiStatus.formReady)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.errorMessage!)),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
        final isOffline = isCustomerOffline(context);

        return CustomerScreenShell(
          appBar: _PremiumAppBar(),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: FadeTransition(
            opacity: _fadeController,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ServiceSummaryCard(service: service, state: state),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    icon: Icons.calendar_month_rounded,
                    label: 'Date & Time',
                  ),
                  const SizedBox(height: 12),
                  _DateTimeRow(state: state),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    icon: Icons.location_on_rounded,
                    label: 'Address & Location',
                  ),
                  const SizedBox(height: 12),
                  _LocationSection(
                    state: state,
                    addressController: _addressController,
                    onPickLocation: () => _openLocationPicker(context, state),
                    onUseCurrentLocation: () =>
                        context.read<ScheduledBookingBloc>().add(
                              const LoadScheduledBookingLocation(
                                  forceRefresh: true),
                            ),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    icon: Icons.edit_note_rounded,
                    label: 'Description',
                  ),
                  const SizedBox(height: 12),
                  _PremiumTextField(
                    controller: _descriptionController,
                    hint: 'Describe the issue or job details…',
                    maxLines: 4,
                    onChanged: (v) =>
                        context.read<ScheduledBookingBloc>().add(
                              UpdateScheduledBookingDescription(v),
                            ),
                  ),
                  const SizedBox(height: 28),
                  _SectionHeader(
                    icon: Icons.photo_library_rounded,
                    label: 'Issue Photos',
                    subtitle: 'Optional · up to 5',
                  ),
                  const SizedBox(height: 12),
                  _IssueImagesSection(
                    images: state.issueImages,
                    onAdd: () async {
                      final file =
                          await _imageHelper.showImageSourceSheet(context);
                      if (file != null && context.mounted) {
                        context
                            .read<ScheduledBookingBloc>()
                            .add(AddScheduledBookingIssueImage(file));
                      }
                    },
                    onRemove: (index) => context
                        .read<ScheduledBookingBloc>()
                        .add(RemoveScheduledBookingIssueImage(index)),
                  ),
                  const SizedBox(height: 36),
                  if (isOffline)
                    const OfflineActionHint(
                      message:
                          'You are offline. Your booking cannot be submitted yet.',
                    ),
                  _SubmitButton(
                    isSubmitting: isSubmitting,
                    canSubmit: state.canSubmit && !isOffline,
                    onPressed: () => context
                        .read<ScheduledBookingBloc>()
                        .add(const SubmitScheduledBooking()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openLocationPicker(
    BuildContext context,
    ScheduledBookingState state,
  ) async {
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute<LocationPickerResult>(
        builder: (_) => LocationPickerScreen(
          initialLocation: state.location,
          initialAddress:
              state.address.trim().isNotEmpty ? state.address : null,
        ),
      ),
    );

    if (result == null || !context.mounted) return;

    context.read<ScheduledBookingBloc>().add(
          ApplyPickedScheduledLocation(
            location: result.location,
            address: result.address,
            usedFallbackAddress: result.usedFallbackAddress,
          ),
        );

    if (result.usedFallbackAddress && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Address could not be resolved. Coordinates will be saved.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium App Bar
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: cs.onSurface),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule Booking',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          Text(
            'Fill in the details below',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;

  const _SectionHeader({
    required this.icon,
    required this.label,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service Summary Card
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceSummaryCard extends StatelessWidget {
  final ServicesModel service;
  final ScheduledBookingState state;

  const _ServiceSummaryCard({required this.service, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isFixed = service.showFixedPrice;
    final priceLabel = isFixed
        ? '${CurrencyIcon.currencyIcon}${service.fixedJobRate!.toStringAsFixed(0)}'
        : '${CurrencyIcon.currencyIcon}${service.perHourRate.toStringAsFixed(0)}/hr';
    final pricingType = isFixed ? 'Fixed price' : 'Per hour';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: cs.primary.withValues(alpha: 0.08),
              ),
              child: (service.mainImage != null &&
                      service.mainImage!.isNotEmpty)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AppCacheImage(
                        imageUrl: service.mainImage!,
                        width: 80,
                        height: 80,
                        boxFit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.home_repair_service_rounded,
                      color: cs.primary,
                      size: 32,
                    ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (service.categoryTitle != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        service.categoryTitle!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.secondary,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  Text(
                    service.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        priceLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: Text(
                          pricingType,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date & Time Row
// ─────────────────────────────────────────────────────────────────────────────

class _DateTimeRow extends StatelessWidget {
  final ScheduledBookingState state;

  const _DateTimeRow({required this.state});

  String _formatDate(DateTime? d) {
    if (d == null) return 'Select date';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null) return 'Select time';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ScheduledBookingBloc>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasDate = state.selectedDate != null;
    final hasTime = state.selectedTime != null;

    return Row(
      children: [
        Expanded(
          child: _DateTimeTile(
            icon: Icons.calendar_today_rounded,
            label: 'Date',
            value: _formatDate(state.selectedDate),
            isSelected: hasDate,
            onTap: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: state.selectedDate ?? now,
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
              );
              if (picked != null) bloc.add(UpdateScheduledBookingDate(picked));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DateTimeTile(
            icon: Icons.schedule_rounded,
            label: 'Time',
            value: _formatTime(state.selectedTime),
            isSelected: hasTime,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: state.selectedTime ?? TimeOfDay.now(),
              );
              if (picked != null) bloc.add(UpdateScheduledBookingTime(picked));
            },
          ),
        ),
      ],
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateTimeTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.07)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? cs.primary.withValues(alpha: 0.4)
                : cs.outline.withValues(alpha: 0.18),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? cs.onSurface
                    : cs.onSurface.withValues(alpha: 0.45),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Location Section
// ─────────────────────────────────────────────────────────────────────────────

class _LocationSection extends StatelessWidget {
  final ScheduledBookingState state;
  final TextEditingController addressController;
  final VoidCallback onPickLocation;
  final VoidCallback onUseCurrentLocation;

  const _LocationSection({
    required this.state,
    required this.addressController,
    required this.onPickLocation,
    required this.onUseCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasCoords = state.location != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Address card
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasCoords
                  ? cs.primary.withValues(alpha: 0.3)
                  : cs.outline.withValues(alpha: 0.15),
              width: hasCoords ? 1.5 : 1,
            ),
            boxShadow: [
              if (hasCoords)
                BoxShadow(
                  color: cs.primary.withValues(alpha: 0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.place_rounded,
                        color: hasCoords ? cs.primary : cs.onSurface.withValues(alpha: 0.4),
                        size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Service Address',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: hasCoords ? cs.primary : cs.onSurface.withValues(alpha: 0.55),
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (state.isLocationManuallySelected) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                size: 11, color: cs.primary),
                            const SizedBox(width: 3),
                            Text(
                              'Custom',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                if (hasCoords) ...[
                  Text(
                    addressController.text.isNotEmpty
                        ? addressController.text
                        : 'Location selected',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.gps_fixed_rounded,
                          size: 12,
                          color: cs.onSurface.withValues(alpha: 0.4)),
                      const SizedBox(width: 4),
                      Text(
                        '${state.location!.latitude.toStringAsFixed(5)}, '
                        '${state.location!.longitude.toStringAsFixed(5)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.4),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    'No location selected yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Use the buttons below to set your service location.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Location buttons
        Row(
          children: [
            Expanded(
              child: _LocationButton(
                icon: Icons.map_outlined,
                label: 'Pick on map',
                onPressed: state.locationLoading ? null : onPickLocation,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LocationButton(
                icon: Icons.my_location_rounded,
                label: 'Use GPS',
                isLoading: state.locationLoading,
                onPressed: state.locationLoading ? null : onUseCurrentLocation,
              ),
            ),
          ],
        ),
        // Errors
        if (state.locationError != null)
          _ValidationNote(
              text: state.locationError!, icon: Icons.warning_amber_rounded),
        if (!hasCoords && !state.locationLoading)
          _ValidationNote(
              text: 'Please select a service location.',
              icon: Icons.info_outline_rounded),
      ],
    );
  }
}

class _LocationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _LocationButton({
    required this.icon,
    required this.label,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final disabled = onPressed == null;

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
        decoration: BoxDecoration(
          color: disabled
              ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.outline.withValues(alpha: disabled ? 0.1 : 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: cs.primary),
              )
            else
              Icon(icon,
                  size: 17,
                  color: disabled
                      ? cs.onSurface.withValues(alpha: 0.3)
                      : cs.primary),
            const SizedBox(width: 7),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: disabled
                    ? cs.onSurface.withValues(alpha: 0.3)
                    : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValidationNote extends StatelessWidget {
  final String text;
  final IconData icon;

  const _ValidationNote({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppTheme.warningColor),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.warningColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium Text Field
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final ValueChanged<String> onChanged;

  const _PremiumTextField({
    required this.controller,
    required this.hint,
    required this.maxLines,
    required this.onChanged,
  });

  @override
  State<_PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<_PremiumTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _focused
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outline.withValues(alpha: 0.15),
            width: _focused ? 1.5 : 1,
          ),
          boxShadow: [
            if (_focused)
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          maxLines: widget.maxLines,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Issue Images Section
// ─────────────────────────────────────────────────────────────────────────────

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SizedBox(
      height: 88,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          // Existing images
          for (var i = 0; i < images.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        images[i],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -5,
                    right: -5,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.errorColor.withValues(alpha: 0.4),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.close,
                            size: 13, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Add button
          if (images.length < 5)
            GestureDetector(
              onTap: onAdd,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: cs.primary.withValues(alpha: 0.25),
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded,
                        size: 22, color: cs.primary),
                    const SizedBox(height: 4),
                    Text(
                      'Add',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Remaining slots indicator
          if (images.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No photos yet',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Tap + to add up to 5',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Submit Button
// ─────────────────────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final bool canSubmit;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.isSubmitting,
    required this.canSubmit,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: canSubmit && !isSubmitting
                  ? LinearGradient(
                      colors: [
                        cs.primary,
                        cs.primary.withValues(alpha: 0.85),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: canSubmit && !isSubmitting
                  ? null
                  : cs.onSurface.withValues(alpha: 0.1),
              boxShadow: canSubmit && !isSubmitting
                  ? [
                      BoxShadow(
                        color: cs.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: canSubmit && !isSubmitting ? onPressed : null,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: cs.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Submitting…',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: cs.onPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Submit Booking',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: canSubmit
                                    ? cs.onPrimary
                                    : cs.onSurface.withValues(alpha: 0.35),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (canSubmit) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: cs.onPrimary,
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your booking request will be sent to Admin.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurface.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}