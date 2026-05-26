import 'package:equatable/equatable.dart';

abstract class NavbarEvent extends Equatable {
  const NavbarEvent();

  @override
  List<Object?> get props => [];
}

class ChangeTabEvent extends NavbarEvent {
  final int newIndex;

  const ChangeTabEvent(this.newIndex);

  @override
  List<Object?> get props => [newIndex];
}
