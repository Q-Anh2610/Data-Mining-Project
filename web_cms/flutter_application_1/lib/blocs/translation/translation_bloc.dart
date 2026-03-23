// File: lib/blocs/translation/translation_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/translation_record.dart';
import '../../services/local_database_service.dart';
import '../../services/translation_service.dart'; 

abstract class TranslationEvent {}
class TranslateTextEvent extends TranslationEvent { final String sourceText; TranslateTextEvent(this.sourceText); }
class SwapLanguagesEvent extends TranslationEvent {}
class ClearSessionEvent extends TranslationEvent {} 
class LoadSessionEvent extends TranslationEvent { final String sessionId; LoadSessionEvent(this.sessionId); } // Sự kiện mở lại chat cũ

class TranslationState {
  final bool isLoading;
  final List<TranslationRecord> sessionRecords; 
  final String? error;
  final String sourceLang;
  final String targetLang;
  final String currentSessionId; // Quản lý mã phiên đang dùng

  TranslationState({
    this.isLoading = false,
    this.sessionRecords = const [],
    this.error,
    this.sourceLang = 'English',
    this.targetLang = 'Vietnamese',
    required this.currentSessionId,
  });

  TranslationState copyWith({ bool? isLoading, List<TranslationRecord>? sessionRecords, String? error, String? sourceLang, String? targetLang, String? currentSessionId }) {
    return TranslationState(
      isLoading: isLoading ?? this.isLoading,
      sessionRecords: sessionRecords ?? this.sessionRecords,
      error: error,
      sourceLang: sourceLang ?? this.sourceLang,
      targetLang: targetLang ?? this.targetLang,
      currentSessionId: currentSessionId ?? this.currentSessionId,
    );
  }
}

class TranslationBloc extends Bloc<TranslationEvent, TranslationState> {
  final TranslationService _translationService = TranslationService();
  
  // Khởi tạo app với một mã phiên ngẫu nhiên
  TranslationBloc() : super(TranslationState(currentSessionId: DateTime.now().millisecondsSinceEpoch.toString())) {
    
    on<TranslateTextEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true, error: null));
      try {
        // Truyền thêm currentSessionId vào Service
        final record = await _translationService.executeTranslation(
          state.currentSessionId, // <-- CHỖ NÀY ĐÃ ĐƯỢC SỬA
          event.sourceText, 
          state.sourceLang, 
          state.targetLang
        );

        // Lưu vào DB Local
        await LocalDatabaseService().insertRecord(record);

        // Hiển thị lên UI
        final updatedList = List<TranslationRecord>.from(state.sessionRecords)..add(record);
        emit(state.copyWith(isLoading: false, sessionRecords: updatedList));
      } catch (e) {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      }
    });

    on<SwapLanguagesEvent>((event, emit) {
      emit(state.copyWith(sourceLang: state.targetLang, targetLang: state.sourceLang));
    });

    // NÚT MỚI: Reset ô chat và bốc một mã phiên (sessionId) hoàn toàn mới
    on<ClearSessionEvent>((event, emit) {
      emit(TranslationState(
        sourceLang: state.sourceLang, 
        targetLang: state.targetLang,
        currentSessionId: DateTime.now().millisecondsSinceEpoch.toString() 
      ));
    });

    // CLICK LỊCH SỬ CŨ: Tải lại toàn bộ đoạn chat từ Database
    on<LoadSessionEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true));
      final records = await LocalDatabaseService().getRecordsBySession(event.sessionId);
      if (records.isNotEmpty) {
        emit(state.copyWith(
          isLoading: false, 
          sessionRecords: records, 
          currentSessionId: event.sessionId, 
          sourceLang: records.first.sourceLang, 
          targetLang: records.first.targetLang
        ));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    });
  }
}