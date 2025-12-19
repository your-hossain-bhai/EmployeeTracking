import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/theme_preferences_service.dart';

// Events
abstract class ThemeEvent {}

class ThemeChanged extends ThemeEvent {
  final ThemeMode mode;
  ThemeChanged(this.mode);
}

class ThemeLoaded extends ThemeEvent {}

// State
class ThemeState {
  final ThemeMode mode;

  const ThemeState({this.mode = ThemeMode.system});

  ThemeState copyWith({ThemeMode? mode}) {
    return ThemeState(mode: mode ?? this.mode);
  }
}

// BLoC
class ThemeController extends Bloc<ThemeEvent, ThemeState> {
  final ThemePreferencesService _preferencesService;

  ThemeController({ThemePreferencesService? preferencesService})
      : _preferencesService = preferencesService ?? ThemePreferencesService(),
        super(const ThemeState()) {
    on<ThemeLoaded>(_onThemeLoaded);
    on<ThemeChanged>(_onThemeChanged);
  }

  Future<void> _onThemeLoaded(
      ThemeLoaded event, Emitter<ThemeState> emit) async {
    await _preferencesService.initialize();
    final mode = _preferencesService.getThemeMode();
    emit(state.copyWith(mode: mode));
  }

  Future<void> _onThemeChanged(
      ThemeChanged event, Emitter<ThemeState> emit) async {
    await _preferencesService.setThemeMode(event.mode);
    emit(state.copyWith(mode: event.mode));
  }
}
