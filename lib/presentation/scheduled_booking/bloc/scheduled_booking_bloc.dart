import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homeease/core/services/geocoding_service.dart';
import 'package:homeease/models/services_model.dart';
import 'package:homeease/presentation/scheduled_booking/bloc/scheduled_booking_event.dart';
import 'package:homeease/presentation/scheduled_booking/bloc/scheduled_booking_state.dart';
import 'package:homeease/repositories/scheduled_booking_repository.dart';

class ScheduledBookingBloc
    extends Bloc<ScheduledBookingEvent, ScheduledBookingState> {
  final ScheduledBookingRepository repository;
  final ServicesModel? initialService;
  final String? initialRequestId;
  final GeocodingService _geocoding = GeocodingService();

  StreamSubscription? _realtimeSub;

  ScheduledBookingBloc({
    required this.repository,
    this.initialService,
    this.initialRequestId,
  }) : super(ScheduledBookingState(
          service: initialService,
          requestId: initialRequestId,
        )) {
    on<InitializeScheduledBookingForm>(_onInitForm);
    on<LoadScheduledBookingLocation>(_onLoadLocation);
    on<UpdateScheduledBookingAddress>(_onUpdateAddress);
    on<UpdateScheduledBookingLocation>(_onUpdateLocation);
    on<UpdateScheduledBookingDate>(_onUpdateDate);
    on<UpdateScheduledBookingTime>(_onUpdateTime);
    on<UpdateScheduledBookingDescription>(_onUpdateDescription);
    on<AddScheduledBookingIssueImage>(_onAddImage);
    on<RemoveScheduledBookingIssueImage>(_onRemoveImage);
    on<SubmitScheduledBooking>(_onSubmit);
    on<LoadScheduledBookingDetails>(_onLoadDetails);
    on<StartScheduledBookingRealtime>(_onStartRealtime);
    on<StopScheduledBookingRealtime>(_onStopRealtime);
    on<ScheduledBookingRealtimeUpdated>(_onRealtimeUpdated);
    on<ConfirmScheduledBookingPayment>(_onConfirmPayment);
    on<RefreshScheduledBookingDetails>(_onRefreshDetails);
  }

  String? get _customerId => repository.supabase.auth.currentUser?.id;

  Future<void> _onInitForm(
    InitializeScheduledBookingForm event,
    Emitter<ScheduledBookingState> emit,
  ) async {
    if (state.service == null) {
      emit(state.copyWith(
        status: ScheduledBookingUiStatus.submitError,
        errorMessage: 'Service information is missing.',
      ));
      return;
    }

    final now = DateTime.now();
    final nextHour = (now.hour + 1).clamp(0, 23);
    emit(state.copyWith(
      status: ScheduledBookingUiStatus.formReady,
      selectedDate: DateTime(now.year, now.month, now.day),
      selectedTime: TimeOfDay(hour: nextHour, minute: 0),
      clearError: true,
    ));
    add(const LoadScheduledBookingLocation());
  }

  Future<void> _onLoadLocation(
    LoadScheduledBookingLocation event,
    Emitter<ScheduledBookingState> emit,
  ) async {
    emit(state.copyWith(
      locationLoading: true,
      clearError: true,
    ));

    try {
      final position = await repository.getCurrentLocation();
      final latLng = LatLng(position.latitude, position.longitude);
      final address = await _geocoding.getAddressFromCoordinates(
            position.latitude,
            position.longitude,
          ) ??
          '';

      emit(state.copyWith(
        location: latLng,
        address: address.isNotEmpty ? address : state.address,
        locationLoading: false,
        status: ScheduledBookingUiStatus.formReady,
      ));
    } catch (e) {
      emit(state.copyWith(
        locationLoading: false,
        status: ScheduledBookingUiStatus.formReady,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onUpdateAddress(
    UpdateScheduledBookingAddress event,
    Emitter<ScheduledBookingState> emit,
  ) {
    emit(state.copyWith(address: event.address, clearError: true));
  }

  void _onUpdateLocation(
    UpdateScheduledBookingLocation event,
    Emitter<ScheduledBookingState> emit,
  ) {
    emit(state.copyWith(location: event.location, clearError: true));
  }

  void _onUpdateDate(
    UpdateScheduledBookingDate event,
    Emitter<ScheduledBookingState> emit,
  ) {
    emit(state.copyWith(selectedDate: event.date, clearError: true));
  }

  void _onUpdateTime(
    UpdateScheduledBookingTime event,
    Emitter<ScheduledBookingState> emit,
  ) {
    emit(state.copyWith(selectedTime: event.time, clearError: true));
  }

  void _onUpdateDescription(
    UpdateScheduledBookingDescription event,
    Emitter<ScheduledBookingState> emit,
  ) {
    emit(state.copyWith(description: event.description, clearError: true));
  }

  void _onAddImage(
    AddScheduledBookingIssueImage event,
    Emitter<ScheduledBookingState> emit,
  ) {
    if (state.issueImages.length >= 5) {
      emit(state.copyWith(
        errorMessage: 'You can attach up to 5 images.',
      ));
      return;
    }
    emit(state.copyWith(
      issueImages: [...state.issueImages, event.file],
      clearError: true,
    ));
  }

  void _onRemoveImage(
    RemoveScheduledBookingIssueImage event,
    Emitter<ScheduledBookingState> emit,
  ) {
    final images = [...state.issueImages];
    if (event.index < 0 || event.index >= images.length) return;
    images.removeAt(event.index);
    emit(state.copyWith(issueImages: images, clearError: true));
  }

  Future<void> _onSubmit(
    SubmitScheduledBooking event,
    Emitter<ScheduledBookingState> emit,
  ) async {
    final service = state.service;
    final customerId = _customerId;

    if (service == null || customerId == null) {
      emit(state.copyWith(
        status: ScheduledBookingUiStatus.submitError,
        errorMessage: 'Please sign in to continue.',
      ));
      return;
    }

    if (!state.canSubmit) {
      emit(state.copyWith(
        status: ScheduledBookingUiStatus.submitError,
        errorMessage:
            'Please select date, time, address, and location before submitting.',
      ));
      return;
    }

    final date = state.selectedDate!;
    final time = state.selectedTime!;
    final scheduledDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      emit(state.copyWith(
        status: ScheduledBookingUiStatus.submitError,
        errorMessage: 'Scheduled time must be in the future.',
      ));
      return;
    }

    emit(state.copyWith(
      status: ScheduledBookingUiStatus.submitting,
      clearError: true,
    ));

    try {
      List<String> imageUrls = [];
      if (state.issueImages.isNotEmpty) {
        try {
          imageUrls = await repository.uploadRequestImages(
            customerId: customerId,
            files: state.issueImages,
          );
        } catch (e) {
          emit(state.copyWith(
            status: ScheduledBookingUiStatus.submitError,
            errorMessage: e.toString(),
          ));
          return;
        }
      }

      final preferredTimeLabel =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

      final booking = await repository.createScheduledBooking(
        service: service,
        scheduledDateTime: scheduledDateTime,
        preferredTimeLabel: preferredTimeLabel,
        customerLocation: state.location!,
        customerAddress: state.address.trim(),
        description: state.description,
        customerRequestImages: imageUrls,
      );

      emit(state.copyWith(
        status: ScheduledBookingUiStatus.submitSuccess,
        requestId: booking.id,
        booking: booking,
        successMessage: 'Your booking was submitted for admin approval.',
        issueImages: const [],
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ScheduledBookingUiStatus.submitError,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadDetails(
    LoadScheduledBookingDetails event,
    Emitter<ScheduledBookingState> emit,
  ) async {
    emit(state.copyWith(
      status: ScheduledBookingUiStatus.detailsLoading,
      requestId: event.requestId,
      clearError: true,
    ));

    try {
      final booking =
          await repository.fetchScheduledBookingDetails(event.requestId);
      emit(state.copyWith(
        status: ScheduledBookingUiStatus.detailsLoaded,
        booking: booking,
        service: state.service,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ScheduledBookingUiStatus.detailsError,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onRefreshDetails(
    RefreshScheduledBookingDetails event,
    Emitter<ScheduledBookingState> emit,
  ) async {
    final id = state.requestId;
    if (id == null) return;
    add(LoadScheduledBookingDetails(id));
  }

  Future<void> _onStartRealtime(
    StartScheduledBookingRealtime event,
    Emitter<ScheduledBookingState> emit,
  ) async {
    await _realtimeSub?.cancel();
    _realtimeSub = repository
        .subscribeToScheduledBooking(event.requestId)
        .listen(
      (request) => add(ScheduledBookingRealtimeUpdated(request)),
      onError: (Object e) {
        if (kDebugMode) {
          print('ScheduledBookingBloc realtime error: $e');
        }
      },
    );
  }

  Future<void> _onStopRealtime(
    StopScheduledBookingRealtime event,
    Emitter<ScheduledBookingState> emit,
  ) async {
    await _realtimeSub?.cancel();
    _realtimeSub = null;
  }

  void _onRealtimeUpdated(
    ScheduledBookingRealtimeUpdated event,
    Emitter<ScheduledBookingState> emit,
  ) {
    if (event.request == null) return;
    emit(state.copyWith(
      booking: event.request,
      status: ScheduledBookingUiStatus.detailsLoaded,
    ));
  }

  Future<void> _onConfirmPayment(
    ConfirmScheduledBookingPayment event,
    Emitter<ScheduledBookingState> emit,
  ) async {
    final booking = state.booking;
    if (booking == null || !booking.canCustomerConfirmPayment) {
      emit(state.copyWith(
        errorMessage: 'Payment cannot be confirmed for this booking.',
      ));
      return;
    }

    emit(state.copyWith(
      status: ScheduledBookingUiStatus.paying,
      clearError: true,
    ));

    try {
      final updated = await repository.payInvoice(event.requestId);
      emit(state.copyWith(
        status: ScheduledBookingUiStatus.paySuccess,
        booking: updated,
        successMessage: 'Payment confirmed. Thank you!',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ScheduledBookingUiStatus.payError,
        booking: booking,
        errorMessage: e.toString(),
      ));
    }
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}
