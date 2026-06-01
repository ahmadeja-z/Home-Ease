import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/presentation/customer_drawer/models/customer_drawer_route.dart';
import 'navbar_event.dart';
import 'navbar_state.dart';

class NavbarBloc extends Bloc<NavbarEvent, NavbarState> {
  NavbarBloc() : super(const NavbarState()) {
    on<ChangeTabEvent>(_onChangeTab);
    on<NavigateFromDrawerEvent>(_onNavigateFromDrawer);
    on<ClearDrawerHistoryIntent>(_onClearHistoryIntent);
  }

  void _onChangeTab(ChangeTabEvent event, Emitter<NavbarState> emit) {
    if (event.newIndex == state.selectedIndex) return;

    final route = switch (event.newIndex) {
      0 => CustomerDrawerRoute.home,
      1 => CustomerDrawerRoute.myRequests,
      2 => CustomerDrawerRoute.scheduledHistory,
      3 => CustomerDrawerRoute.profile,
      _ => state.activeDrawerRoute,
    };

    emit(
      state.copyWith(
        selectedIndex: event.newIndex,
        activeDrawerRoute: route,
        clearHistoryIntent: true,
      ),
    );
  }

  void _onNavigateFromDrawer(
    NavigateFromDrawerEvent event,
    Emitter<NavbarState> emit,
  ) {
    emit(
      state.copyWith(
        selectedIndex: event.tabIndex,
        activeDrawerRoute: event.route,
        pendingHistoryIntent: event.historyIntent,
        drawerNavigationToken: state.drawerNavigationToken + 1,
      ),
    );
  }

  void _onClearHistoryIntent(
    ClearDrawerHistoryIntent event,
    Emitter<NavbarState> emit,
  ) {
    emit(state.copyWith(clearHistoryIntent: true));
  }
}
