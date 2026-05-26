import 'package:flutter_bloc/flutter_bloc.dart';
import 'navbar_event.dart';
import 'navbar_state.dart';

class NavbarBloc extends Bloc<NavbarEvent, NavbarState> {
  NavbarBloc() : super(const NavbarState()) {
    on<ChangeTabEvent>(_onChangeTab);
  }

  void _onChangeTab(ChangeTabEvent event, Emitter<NavbarState> emit) {
    emit(NavbarState(selectedIndex: event.newIndex));
  }
}
