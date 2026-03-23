import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SettingsEvent {}

class UpdateSettingsEvent extends SettingsEvent {
  final String textSize;
  final String language;
  final String themeMode; // Thêm chế độ giao diện
  UpdateSettingsEvent({required this.textSize, required this.language, required this.themeMode});
}

class SettingsState {
  final String textSize;
  final String language;
  final String themeMode; // 'Light' hoặc 'Dark'

  SettingsState({
    this.textSize = 'Medium', 
    this.language = 'English',
    this.themeMode = 'Light', // Mặc định là Light
  });

  double get fontDelta {
    if (textSize == 'Small') return -3.0;
    if (textSize == 'Large') return 4.0;
    return 0.0;
  }
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc() : super(SettingsState()) {
    on<UpdateSettingsEvent>((event, emit) {
      emit(SettingsState(
        textSize: event.textSize, 
        language: event.language,
        themeMode: event.themeMode,
      ));
    });
  }
}