import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/translation_record.dart';
import '../../services/local_database_service.dart';

abstract class HistoryEvent {}

class LoadHistoryEvent extends HistoryEvent {}

class DeleteHistoryItemEvent extends HistoryEvent {
  final String sessionId;

  DeleteHistoryItemEvent(this.sessionId);
}

class ClearAllHistoryEvent extends HistoryEvent {}

class ClearFavoriteRecordsEvent extends HistoryEvent {
  final List<String> recordIds;

  ClearFavoriteRecordsEvent(this.recordIds);
}

class ToggleHistoryFavoriteEvent extends HistoryEvent {
  final String recordId;
  final bool isFavorite;

  ToggleHistoryFavoriteEvent({
    required this.recordId,
    required this.isFavorite,
  });
}

class ToggleHistorySessionFavoriteEvent extends HistoryEvent {
  final String sessionId;
  final bool isFavorite;

  ToggleHistorySessionFavoriteEvent({
    required this.sessionId,
    required this.isFavorite,
  });
}

abstract class HistoryState {}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<TranslationRecord> records;
  final List<TranslationRecord> favoriteRecords;

  HistoryLoaded(
    List<TranslationRecord> records, {
    List<TranslationRecord> favoriteRecords = const [],
  }) : records = TranslationRecord.sortHistorySessions(records),
       favoriteRecords = TranslationRecord.sortHistorySessions(favoriteRecords);
}

class HistoryError extends HistoryState {
  final String message;

  HistoryError(this.message);
}

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  final LocalDatabaseService _localDb = LocalDatabaseService();

  HistoryBloc() : super(HistoryInitial()) {
    on<LoadHistoryEvent>((event, emit) async {
      emit(HistoryLoading());
      try {
        final sessions = await _localDb.getHistorySessions();
        final favorites = await _localDb.getFavoriteRecords();
        emit(HistoryLoaded(sessions, favoriteRecords: favorites));
      } catch (error) {
        emit(HistoryError(error.toString()));
      }
    });

    on<ToggleHistoryFavoriteEvent>((event, emit) async {
      final previousState = state;
      final now = DateTime.now();

      if (previousState is HistoryLoaded) {
        final optimisticRecords = previousState.records.map((record) {
          if (record.id != event.recordId) return record;
          return record.copyWith(isFavorite: event.isFavorite, updatedAt: now);
        });
        final optimisticFavorites = previousState.favoriteRecords.map((record) {
          if (record.id != event.recordId) return record;
          return record.copyWith(isFavorite: event.isFavorite, updatedAt: now);
        });
        emit(
          HistoryLoaded(
            optimisticRecords.toList(),
            favoriteRecords: optimisticFavorites
                .where((record) => record.isFavorite)
                .toList(),
          ),
        );
      }

      try {
        await _localDb.setRecordFavorite(event.recordId, event.isFavorite);
        final sessions = await _localDb.getHistorySessions();
        final favorites = await _localDb.getFavoriteRecords();
        emit(HistoryLoaded(sessions, favoriteRecords: favorites));
      } catch (error) {
        if (previousState is HistoryLoaded) {
          emit(previousState);
        }
        emit(HistoryError(error.toString()));
      }
    });

    on<ToggleHistorySessionFavoriteEvent>((event, emit) async {
      try {
        await _localDb.setSessionFavorite(event.sessionId, event.isFavorite);
        final sessions = await _localDb.getHistorySessions();
        final favorites = await _localDb.getFavoriteRecords();
        emit(HistoryLoaded(sessions, favoriteRecords: favorites));
      } catch (error) {
        emit(HistoryError(error.toString()));
      }
    });

    on<DeleteHistoryItemEvent>((event, emit) async {
      try {
        await _localDb.deleteSession(event.sessionId);
        final sessions = await _localDb.getHistorySessions();
        final favorites = await _localDb.getFavoriteRecords();
        emit(HistoryLoaded(sessions, favoriteRecords: favorites));
      } catch (error) {
        emit(HistoryError(error.toString()));
      }
    });

    on<ClearAllHistoryEvent>((event, emit) async {
      try {
        await _localDb.clearAll();
        emit(HistoryLoaded(const []));
      } catch (error) {
        emit(HistoryError(error.toString()));
      }
    });

    on<ClearFavoriteRecordsEvent>((event, emit) async {
      try {
        await _localDb.clearFavoriteRecords(event.recordIds);
        final sessions = await _localDb.getHistorySessions();
        final favorites = await _localDb.getFavoriteRecords();
        emit(HistoryLoaded(sessions, favoriteRecords: favorites));
      } catch (error) {
        emit(HistoryError(error.toString()));
      }
    });
  }
}
