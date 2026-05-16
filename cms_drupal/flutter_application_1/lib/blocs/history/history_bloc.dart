// File: lib/blocs/history/history_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/translation_record.dart';
import '../../services/local_database_service.dart';

// ==============================================================================
// EVENTS
// ==============================================================================
abstract class HistoryEvent {}

class LoadHistoryEvent extends HistoryEvent {}

class DeleteHistoryItemEvent extends HistoryEvent {
  final String sessionId; // Đổi biến id thành sessionId
  DeleteHistoryItemEvent(this.sessionId);
}

class ClearAllHistoryEvent extends HistoryEvent {}

// ==============================================================================
// STATES
// ==============================================================================
abstract class HistoryState {}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<TranslationRecord> records; // Chứa danh sách các câu đầu tiên của mỗi phiên
  HistoryLoaded(this.records);
}

class HistoryError extends HistoryState {
  final String message;
  HistoryError(this.message);
}

// ==============================================================================
// BLOC
// ==============================================================================
class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final LocalDatabaseService _localDb = LocalDatabaseService();

  HistoryBloc() : super(HistoryInitial()) {
    
    // TẢI DANH SÁCH CÁC PHIÊN CHAT
    on<LoadHistoryEvent>((event, emit) async {
      emit(HistoryLoading());
      try {
        // Lấy danh sách nhóm chat (Phiên) thay vì tất cả câu lẻ
        final sessions = await _localDb.getHistorySessions();
        emit(HistoryLoaded(sessions));
      } catch (e) {
        emit(HistoryError(e.toString()));
      }
    });

    // XÓA MỘT PHIÊN CHAT
    on<DeleteHistoryItemEvent>((event, emit) async {
      try {
        // Xóa sạch mọi câu dịch nằm trong sessionId này
        await _localDb.deleteSession(event.sessionId);
        add(LoadHistoryEvent()); // Tải lại danh sách sau khi xóa
      } catch (e) {
        emit(HistoryError(e.toString()));
      }
    });

    // XÓA TOÀN BỘ
    on<ClearAllHistoryEvent>((event, emit) async {
      try {
        await _localDb.clearAll();
        add(LoadHistoryEvent());
      } catch (e) {
        emit(HistoryError(e.toString()));
      }
    });
  }
}