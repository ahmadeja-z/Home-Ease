import 'package:equatable/equatable.dart';

class NavbarState extends Equatable {
  final int selectedIndex;

  const NavbarState({this.selectedIndex = 0});

  NavbarState copyWith({int? selectedIndex}) {
    return NavbarState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }

  @override
  List<Object?> get props => [selectedIndex];
}
