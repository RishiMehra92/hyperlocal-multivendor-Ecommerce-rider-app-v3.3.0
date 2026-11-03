import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/config/theme/theme_bloc/theme_event.dart';
import '../../constant.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState()) {
    on<LoadTheme>(_onLoadTheme);
    on<ToggleTheme>(_onToggleTheme);
    on<SetTheme>(_onSetTheme);
  }

  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    try {
      final savedTheme = await Global.getTheme();

      emit(state.copyWith(currentTheme: savedTheme));
    } catch (e) {
      emit(state.copyWith(currentTheme: AppConstant.defaultTheme));
    }
  }

  Future<void> _onToggleTheme(
    ToggleTheme event,
    Emitter<ThemeState> emit,
  ) async {
    final newTheme = state.currentTheme == 'light' ? 'dark' : 'light';
    await _saveTheme(newTheme);
    emit(state.copyWith(currentTheme: newTheme));
  }

  Future<void> _onSetTheme(SetTheme event, Emitter<ThemeState> emit) async {
    await _saveTheme(event.theme);

    emit(state.copyWith(currentTheme: event.theme));
  }

  Future<void> _saveTheme(String theme) async {
    try {
      await Global.setTheme(theme);
      // ignore: empty_catches
    } catch (e) {}
  }

  bool get isDarkMode => state.currentTheme == 'dark';
}
