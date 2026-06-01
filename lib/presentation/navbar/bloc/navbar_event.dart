import 'package:equatable/equatable.dart';
import 'package:homeease/presentation/customer_drawer/models/customer_drawer_route.dart';
import 'package:homeease/presentation/customer_drawer/models/customer_history_drawer_intent.dart';

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

class NavigateFromDrawerEvent extends NavbarEvent {
  final int tabIndex;
  final CustomerDrawerRoute route;
  final CustomerHistoryDrawerIntent? historyIntent;

  const NavigateFromDrawerEvent({
    required this.tabIndex,
    required this.route,
    this.historyIntent,
  });

  @override
  List<Object?> get props => [tabIndex, route, historyIntent];
}

class ClearDrawerHistoryIntent extends NavbarEvent {
  const ClearDrawerHistoryIntent();
}
