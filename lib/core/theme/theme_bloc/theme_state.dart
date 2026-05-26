import '../app_theme.dart';

import 'package:equatable/equatable.dart';

class ThemeState extends Equatable {
  final AppThemeMode themeMode;

  const ThemeState(this.themeMode);

  @override
  List<Object> get props => [themeMode];
}