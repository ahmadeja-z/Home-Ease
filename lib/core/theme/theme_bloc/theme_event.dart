import 'package:equatable/equatable.dart';

import '../app_theme.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object> get props => [];
}

class SwitchThemeEvent extends ThemeEvent {
  final AppThemeMode themeMode;

  const SwitchThemeEvent(this.themeMode);

  @override
  List<Object> get props => [themeMode];
}

class LoadThemeEvent extends ThemeEvent {
  const LoadThemeEvent();
}
