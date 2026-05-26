import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:homeease/models/service_request_model.dart';

abstract class ScheduledBookingEvent extends Equatable {
  const ScheduledBookingEvent();

  @override
  List<Object?> get props => [];
}

class InitializeScheduledBookingForm extends ScheduledBookingEvent {
  const InitializeScheduledBookingForm();
}

class LoadScheduledBookingLocation extends ScheduledBookingEvent {
  const LoadScheduledBookingLocation();
}

class UpdateScheduledBookingAddress extends ScheduledBookingEvent {
  final String address;

  const UpdateScheduledBookingAddress(this.address);

  @override
  List<Object?> get props => [address];
}

class UpdateScheduledBookingLocation extends ScheduledBookingEvent {
  final LatLng location;

  const UpdateScheduledBookingLocation(this.location);

  @override
  List<Object?> get props => [location];
}

class UpdateScheduledBookingDate extends ScheduledBookingEvent {
  final DateTime date;

  const UpdateScheduledBookingDate(this.date);

  @override
  List<Object?> get props => [date];
}

class UpdateScheduledBookingTime extends ScheduledBookingEvent {
  final TimeOfDay time;

  const UpdateScheduledBookingTime(this.time);

  @override
  List<Object?> get props => [time];
}

class UpdateScheduledBookingDescription extends ScheduledBookingEvent {
  final String description;

  const UpdateScheduledBookingDescription(this.description);

  @override
  List<Object?> get props => [description];
}

class AddScheduledBookingIssueImage extends ScheduledBookingEvent {
  final File file;

  const AddScheduledBookingIssueImage(this.file);

  @override
  List<Object?> get props => [file];
}

class RemoveScheduledBookingIssueImage extends ScheduledBookingEvent {
  final int index;

  const RemoveScheduledBookingIssueImage(this.index);

  @override
  List<Object?> get props => [index];
}

class SubmitScheduledBooking extends ScheduledBookingEvent {
  const SubmitScheduledBooking();
}

class LoadScheduledBookingDetails extends ScheduledBookingEvent {
  final String requestId;

  const LoadScheduledBookingDetails(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class StartScheduledBookingRealtime extends ScheduledBookingEvent {
  final String requestId;

  const StartScheduledBookingRealtime(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class StopScheduledBookingRealtime extends ScheduledBookingEvent {
  const StopScheduledBookingRealtime();
}

class ScheduledBookingRealtimeUpdated extends ScheduledBookingEvent {
  final ServiceRequestModel? request;

  const ScheduledBookingRealtimeUpdated(this.request);

  @override
  List<Object?> get props => [request];
}

class ConfirmScheduledBookingPayment extends ScheduledBookingEvent {
  final String requestId;

  const ConfirmScheduledBookingPayment(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

class RefreshScheduledBookingDetails extends ScheduledBookingEvent {
  const RefreshScheduledBookingDetails();
}
