import 'package:equatable/equatable.dart';

abstract class CustomerDrawerEvent extends Equatable {
  const CustomerDrawerEvent();

  @override
  List<Object?> get props => [];
}

class LoadCustomerDrawerData extends CustomerDrawerEvent {
  const LoadCustomerDrawerData();
}

class RefreshCustomerDrawerData extends CustomerDrawerEvent {
  const RefreshCustomerDrawerData();
}
