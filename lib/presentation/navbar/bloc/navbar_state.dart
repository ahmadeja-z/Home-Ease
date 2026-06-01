import 'package:equatable/equatable.dart';
import 'package:homeease/presentation/customer_drawer/models/customer_drawer_route.dart';
import 'package:homeease/presentation/customer_drawer/models/customer_history_drawer_intent.dart';

class NavbarState extends Equatable {
  final int selectedIndex;
  final CustomerDrawerRoute? activeDrawerRoute;
  final CustomerHistoryDrawerIntent? pendingHistoryIntent;
  final int drawerNavigationToken;

  const NavbarState({
    this.selectedIndex = 0,
    this.activeDrawerRoute,
    this.pendingHistoryIntent,
    this.drawerNavigationToken = 0,
  });

  NavbarState copyWith({
    int? selectedIndex,
    CustomerDrawerRoute? activeDrawerRoute,
    CustomerHistoryDrawerIntent? pendingHistoryIntent,
    bool clearHistoryIntent = false,
    int? drawerNavigationToken,
  }) {
    return NavbarState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
      activeDrawerRoute: activeDrawerRoute ?? this.activeDrawerRoute,
      pendingHistoryIntent: clearHistoryIntent
          ? null
          : (pendingHistoryIntent ?? this.pendingHistoryIntent),
      drawerNavigationToken:
          drawerNavigationToken ?? this.drawerNavigationToken,
    );
  }

  @override
  List<Object?> get props => [
        selectedIndex,
        activeDrawerRoute,
        pendingHistoryIntent,
        drawerNavigationToken,
      ];
}
