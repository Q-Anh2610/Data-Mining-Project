import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/translation_record.dart';
import '../../services/local_database_service.dart';
import '../../services/supabase_service.dart';
import '../../services/huggingface_service.dart';
import '../../services/onnx_service.dart';

// =========================
// EVENTS
// =========================

abstract class TranslationEvent {}

class TranslateTextEvent extends TranslationEvent {
  final String sourceText;
  final bool isOffline;

  TranslateTextEvent(this.sourceText, {this.isOffline = false});
}

class SwapLanguagesEvent extends TranslationEvent {}

class ClearSessionEvent extends TranslationEvent {}

class LoadSessionEvent extends TranslationEvent {
  final String sessionId;

  LoadSessionEvent(this.sessionId);
}

class UpdateRecordFavoriteEvent extends TranslationEvent {
  final String recordId;
  final bool isFavorite;

  UpdateRecordFavoriteEvent({required this.recordId, required this.isFavorite});
}

class UpdateSessionFavoriteEvent extends TranslationEvent {
  final String sessionId;
  final bool isFavorite;

  UpdateSessionFavoriteEvent({
    required this.sessionId,
    required this.isFavorite,
  });
}

class UpdateRecordRatingEvent extends TranslationEvent {
  final String recordId;
  final int rating;

  UpdateRecordRatingEvent({required this.recordId, required this.rating});
}

// =========================
// STATE
// =========================

class TranslationState {
  final bool isLoading;

  final List<TranslationRecord> sessionRecords;

  final String? error;

  final String sourceLang;

  final String targetLang;

  final String currentSessionId;

  TranslationState({
    this.isLoading = false,
    this.sessionRecords = const [],
    this.error,
    this.sourceLang = 'English',
    this.targetLang = 'Vietnamese',
    required this.currentSessionId,
  });

  TranslationState copyWith({
    bool? isLoading,
    List<TranslationRecord>? sessionRecords,
    String? error,
    String? sourceLang,
    String? targetLang,
    String? currentSessionId,
  }) {
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

// =========================
// BLOC
// =========================

class TranslationBloc extends Bloc<TranslationEvent, TranslationState> {
  final SupabaseService _supabaseService = SupabaseService();

  final HuggingFaceService _huggingFaceService = HuggingFaceService();

  final OnnxTranslationService _onnxService = OnnxTranslationService();

  TranslationBloc()
    : super(
        TranslationState(
          currentSessionId: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      ) {
    // =========================
    // TRANSLATE EVENT
    // =========================

    on<TranslateTextEvent>((event, emit) async {
      // kiểm tra rỗng
      if (event.sourceText.trim().isEmpty) {
        emit(state.copyWith(error: 'Vui lòng nhập văn bản.'));

        return;
      }

      emit(state.copyWith(isLoading: true, error: null));

      try {
        // =========================
        // GỌI HUGGING FACE HOẶC ONNX
        // =========================

        String resultText = "";
        final String mode = state.sourceLang == 'English' ? 'en_vi' : 'vi_en';

        if (event.isOffline) {
          debugPrint("Dang dich bang ONNX (Offline)...");
          resultText = await _onnxService.translateText(event.sourceText, mode);
        } else {
          // NẾU CÓ MẠNG -> GỌI ĐỘNG CƠ HUGGING FACE
          print("🌐 Đang dịch bằng API Hugging Face (Online)...");
          resultText = await _huggingFaceService.translateText(
            event.sourceText,
            state.sourceLang,
          );
        }

        // =========================
        // CHECK ERROR
        // =========================

        if (resultText.startsWith('Lỗi') ||
            resultText.startsWith('HF Error') ||
            resultText.startsWith('Model đang') ||
            resultText.startsWith('Không')) {
          throw Exception(resultText);
        }

        // =========================
        // TẠO RECORD
        // =========================

        final record = TranslationRecord(
          id: DateTime.now().microsecondsSinceEpoch.toString(),

          sessionId: state.currentSessionId,

          sourceText: event.sourceText,

          translatedText: resultText,

          sourceLang: state.sourceLang,

          targetLang: state.targetLang,

          mode: 'text',

          createdAt: DateTime.now(),
        );

        // =========================
        // SAVE SQLITE
        // =========================

        await LocalDatabaseService().insertRecord(record);

        // =========================
        // SYNC SUPABASE
        // =========================

        try {
          await _supabaseService.syncRecord(record);
        } catch (e) {
          print('SUPABASE SYNC ERROR: $e');
        }

        // =========================
        // UPDATE UI
        // =========================

        final updatedList = List<TranslationRecord>.from(state.sessionRecords)
          ..add(record);

        emit(
          state.copyWith(
            isLoading: false,
            sessionRecords: updatedList,
            error: null,
          ),
        );
      } catch (e) {
        print('TRANSLATION ERROR: $e');

        final errorMsg = e.toString().replaceAll('Exception: ', '');

        emit(state.copyWith(isLoading: false, error: errorMsg));
      }
    });

    // =========================
    // SWAP LANGUAGE
    // =========================

    on<SwapLanguagesEvent>((event, emit) {
      emit(
        state.copyWith(
          sourceLang: state.targetLang,
          targetLang: state.sourceLang,
        ),
      );
    });

    // =========================
    // CLEAR SESSION
    // =========================

    on<ClearSessionEvent>((event, emit) {
      emit(
        TranslationState(
          sourceLang: state.sourceLang,

          targetLang: state.targetLang,

          currentSessionId: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      );
    });

    // =========================
    // LOAD SESSION
    // =========================

    on<LoadSessionEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true));

      try {
        final records = await LocalDatabaseService().getRecordsBySession(
          event.sessionId,
        );

        if (records.isNotEmpty) {
          emit(
            state.copyWith(
              isLoading: false,

              sessionRecords: records,

              currentSessionId: event.sessionId,

              sourceLang: records.first.sourceLang,

              targetLang: records.first.targetLang,

              error: null,
            ),
          );
        } else {
          emit(state.copyWith(isLoading: false, sessionRecords: []));
        }
      } catch (e) {
        emit(
          state.copyWith(isLoading: false, error: 'Không tải được lịch sử.'),
        );
      }
    });

    on<UpdateRecordFavoriteEvent>((event, emit) {
      if (state.sessionRecords.isEmpty) {
        return;
      }

      final updatedRecords = state.sessionRecords
          .map(
            (record) => record.id == event.recordId
                ? record.copyWith(isFavorite: event.isFavorite)
                : record,
          )
          .toList();

      emit(state.copyWith(sessionRecords: updatedRecords, error: null));
    });

    on<UpdateSessionFavoriteEvent>((event, emit) {
      if (state.currentSessionId != event.sessionId ||
          state.sessionRecords.isEmpty) {
        return;
      }

      final updatedRecords = state.sessionRecords
          .map((record) => record.copyWith(isFavorite: event.isFavorite))
          .toList();

      emit(state.copyWith(sessionRecords: updatedRecords, error: null));
    });

    on<UpdateRecordRatingEvent>((event, emit) async {
      final normalizedRating = event.rating.clamp(0, 5).toInt();

      final updatedRecords = state.sessionRecords
          .map(
            (record) => record.id == event.recordId
                ? record.copyWith(rating: normalizedRating)
                : record,
          )
          .toList();

      emit(state.copyWith(sessionRecords: updatedRecords, error: null));

      try {
        await LocalDatabaseService().setRecordRating(
          event.recordId,
          normalizedRating,
        );
      } catch (e) {
        emit(state.copyWith(error: 'Không lưu được đánh giá.'));
      }
    });
  }

  @override
  Future<void> close() {
    _onnxService.dispose();
    return super.close();
  }
}
