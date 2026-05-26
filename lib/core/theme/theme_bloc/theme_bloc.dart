import 'package:bloc/bloc.dart';
import '../../services/system_ui_service.dart';
import '../app_theme.dart';
import '../theme_repository.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeRepository _themeRepository;

  ThemeBloc(this._themeRepository)
    : super(const ThemeState(AppThemeMode.light)) {
    on<LoadThemeEvent>(_onLoadTheme);
    on<SwitchThemeEvent>(_onSwitchTheme);
  }

  Future<void> _onLoadTheme(
    LoadThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    final savedTheme = await _themeRepository.loadSavedTheme();
    _updateSystemUi(savedTheme);
    emit(ThemeState(savedTheme));
  }

  Future<void> _onSwitchTheme(
    SwitchThemeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    await _themeRepository.saveTheme(event.themeMode);
    _updateSystemUi(event.themeMode);
    emit(ThemeState(event.themeMode));
  }

  void _updateSystemUi(AppThemeMode mode) {
    if (mode == AppThemeMode.light) {
      SystemUiService.setLightMode();
    } else {
      SystemUiService.setDarkMode();
    }
  }
}
