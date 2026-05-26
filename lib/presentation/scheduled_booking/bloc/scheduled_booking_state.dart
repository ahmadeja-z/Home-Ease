import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homeease/models/service_request_model.dart';
import 'package:homeease/models/services_model.dart';

enum ScheduledBookingUiStatus {
  initial,
  loadingLocation,
  formReady,
  submitting,
  submitSuccess,
  submitError,
  detailsLoading,
  detailsLoaded,
  detailsError,
  paying,
  paySuccess,
  payError,
}

class ScheduledBookingState extends Equatable {
  final ScheduledBookingUiStatus status;
  final ServicesModel? service;
  final String? requestId;
  final ServiceRequestModel? booking;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final String address;
  final LatLng? location;
  final String description;
  final List<File> issueImages;
  final String? errorMessage;
  final String? successMessage;
  final bool locationLoading;

  const ScheduledBookingState({
    this.status = ScheduledBookingUiStatus.initial,
    this.service,
    this.requestId,
    this.booking,
    this.selectedDate,
    this.selectedTime,
    this.address = '',
    this.location,
    this.description = '',
    this.issueImages = const [],
    this.errorMessage,
    this.successMessage,
    this.locationLoading = false,
  });

  bool get isFormMode =>
      service != null &&
      requestId == null &&
      (status == ScheduledBookingUiStatus.formReady ||
          status == ScheduledBookingUiStatus.loadingLocation ||
          status == ScheduledBookingUiStatus.submitting ||
          status == ScheduledBookingUiStatus.submitError);

  bool get isDetailsMode => requestId != null;

  bool get canSubmit =>
      selectedDate != null &&
      selectedTime != null &&
      location != null &&
      address.trim().isNotEmpty &&
      status != ScheduledBookingUiStatus.submitting;

  PricingType get formPricingType {
    if (service == null) return PricingType.unknown;
    return service!.showFixedPrice ? PricingType.fixed : PricingType.hourly;
  }

  double? get formBasePrice {
    if (service == null) return null;
    return service!.showFixedPrice
        ? service!.fixedJobRate
        : service!.perHourRate;
  }

  ScheduledBookingState copyWith({
    ScheduledBookingUiStatus? status,
    ServicesModel? service,
    String? requestId,
    ServiceRequestModel? booking,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    String? address,
    LatLng? location,
    String? description,
    List<File>? issueImages,
    String? errorMessage,
    String? successMessage,
    bool? locationLoading,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearBooking = false,
  }) {
    return ScheduledBookingState(
      status: status ?? this.status,
      service: service ?? this.service,
      requestId: requestId ?? this.requestId,
      booking: clearBooking ? null : (booking ?? this.booking),
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      address: address ?? this.address,
      location: location ?? this.location,
      description: description ?? this.description,
      issueImages: issueImages ?? this.issueImages,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      locationLoading: locationLoading ?? this.locationLoading,
    );
  }

  @override
  List<Object?> get props => [
        status,
        service,
        requestId,
        booking,
        selectedDate,
        selectedTime,
        address,
        location,
        description,
        issueImages,
        errorMessage,
        successMessage,
        locationLoading,
      ];
}
