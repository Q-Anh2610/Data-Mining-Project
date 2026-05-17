import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/translation_record.dart';
import 'web_history_storage_stub.dart'
    if (dart.library.html) 'web_history_storage_web.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance =
      LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static const _dbName = 'translator_history.db';
  static const _webStorageKey = 'translator_history_records';
  static const _legacyWebStorageKey = 'flutter.$_webStorageKey';

  Database? _database;
  final WebHistoryStorage _webStorage = WebHistoryStorage();
  final List<TranslationRecord> _webMemoryDb = [];
  bool _webLoaded = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(_dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) => _createHistoryTable(db),
      onUpgrade: (db, oldVersion, newVersion) => _ensureHistorySchema(db),
      onOpen: (db) => _ensureHistorySchema(db),
    );
  }

  Future<void> _createHistoryTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS history (
        id TEXT PRIMARY KEY,
        session_id TEXT,
        source_text TEXT,
        translated_text TEXT,
        source_lang TEXT,
        target_lang TEXT,
        mode TEXT,
        created_at TEXT,
        updated_at TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        rating INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<void> _ensureHistorySchema(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'history'",
    );
    if (tables.isEmpty) {
      await _createHistoryTable(db);
      return;
    }

    final info = await db.rawQuery('PRAGMA table_info(history)');
    final columns = info.map((column) => column['name'] as String).toSet();

    Future<void> addColumn(String name, String definition) async {
      if (!columns.contains(name)) {
        await db.execute('ALTER TABLE history ADD COLUMN $name $definition');
      }
    }

    await addColumn('session_id', 'TEXT');
    await addColumn('source_text', 'TEXT');
    await addColumn('translated_text', 'TEXT');
    await addColumn('source_lang', 'TEXT');
    await addColumn('target_lang', 'TEXT');
    await addColumn('mode', 'TEXT');
    await addColumn('created_at', 'TEXT');
    await addColumn('updated_at', 'TEXT');
    await addColumn('is_favorite', 'INTEGER NOT NULL DEFAULT 0');
    await addColumn('rating', 'INTEGER NOT NULL DEFAULT 0');

    await db.execute(
      "UPDATE history SET session_id = id WHERE session_id IS NULL OR session_id = ''",
    );
    await db.execute(
      'UPDATE history SET updated_at = created_at WHERE updated_at IS NULL OR updated_at = ""',
    );
  }

  Future<void> insertRecord(TranslationRecord record) async {
    if (kIsWeb) {
      await _loadWebDb();
      final normalized = record;
      final index = _webMemoryDb.indexWhere((item) => item.id == normalized.id);
      if (index >= 0) {
        _webMemoryDb[index] = normalized;
      } else {
        _webMemoryDb.add(normalized);
      }
      await _persistWebDb();
      return;
    }

    final db = await database;
    await db.insert(
      'history',
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TranslationRecord>> getHistorySessions() async {
    if (kIsWeb) {
      await _loadWebDb();
      final firstBySession = <String, TranslationRecord>{};
      final latestBySession = <String, DateTime>{};
      final favoriteBySession = <String, bool>{};

      for (final record in _webMemoryDb) {
        final first = firstBySession[record.sessionId];
        if (first == null || record.createdAt.isBefore(first.createdAt)) {
          firstBySession[record.sessionId] = record;
        }

        final latest = latestBySession[record.sessionId];
        if (latest == null || record.updatedAt.isAfter(latest)) {
          latestBySession[record.sessionId] = record.updatedAt;
        }

        favoriteBySession[record.sessionId] =
            (favoriteBySession[record.sessionId] ?? false) || record.isFavorite;
      }

      final sessions = firstBySession.values.map((record) {
        return record.copyWith(
          updatedAt: latestBySession[record.sessionId],
          isFavorite: favoriteBySession[record.sessionId] ?? false,
        );
      });

      return TranslationRecord.sortHistorySessions(sessions);
    }

    final db = await database;
    final maps = await db.rawQuery('''
      SELECT
        h.id,
        h.session_id,
        h.source_text,
        h.translated_text,
        h.source_lang,
        h.target_lang,
        h.mode,
        h.created_at,
        meta.latest_at AS updated_at,
        meta.is_favorite AS is_favorite,
        h.rating
      FROM history h
      JOIN (
        SELECT
          session_id,
          MAX(COALESCE(updated_at, created_at)) AS latest_at,
          MAX(COALESCE(is_favorite, 0)) AS is_favorite
        FROM history
        GROUP BY session_id
      ) meta ON meta.session_id = h.session_id
      WHERE h.id = (
        SELECT h2.id
        FROM history h2
        WHERE h2.session_id = h.session_id
        ORDER BY h2.created_at ASC, h2.id ASC
        LIMIT 1
      )
      ORDER BY meta.is_favorite DESC, meta.latest_at DESC
    ''');

    return maps.map(TranslationRecord.fromMap).toList();
  }

  Future<List<TranslationRecord>> getFavoriteRecords() async {
    if (kIsWeb) {
      await _loadWebDb();
      final records = _webMemoryDb.where((record) => record.isFavorite).toList()
        ..sort(TranslationRecord.compareHistorySessions);
      return records;
    }

    final db = await database;
    final maps = await db.query(
      'history',
      where: 'is_favorite = ?',
      whereArgs: [1],
      orderBy: 'updated_at DESC, created_at DESC',
    );
    return maps.map(TranslationRecord.fromMap).toList();
  }

  Future<List<TranslationRecord>> getRecordsBySession(String sessionId) async {
    if (kIsWeb) {
      await _loadWebDb();
      final records =
          _webMemoryDb.where((record) => record.sessionId == sessionId).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return records;
    }

    final db = await database;
    final maps = await db.query(
      'history',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );
    return maps.map(TranslationRecord.fromMap).toList();
  }

  Future<void> setRecordFavorite(String recordId, bool isFavorite) async {
    final updatedAt = DateTime.now();
    final now = updatedAt.toIso8601String();

    if (kIsWeb) {
      await _loadWebDb();
      for (var i = 0; i < _webMemoryDb.length; i++) {
        final record = _webMemoryDb[i];
        if (record.id == recordId) {
          _webMemoryDb[i] = record.copyWith(
            isFavorite: isFavorite,
            updatedAt: updatedAt,
          );
        }
      }
      await _persistWebDb();
      return;
    }

    final db = await database;
    await db.update(
      'history',
      {'is_favorite': isFavorite ? 1 : 0, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  Future<void> setSessionFavorite(String sessionId, bool isFavorite) async {
    final updatedAt = DateTime.now();
    final now = updatedAt.toIso8601String();

    if (kIsWeb) {
      await _loadWebDb();
      for (var i = 0; i < _webMemoryDb.length; i++) {
        final record = _webMemoryDb[i];
        if (record.sessionId == sessionId) {
          _webMemoryDb[i] = record.copyWith(
            isFavorite: isFavorite,
            updatedAt: updatedAt,
          );
        }
      }
      await _persistWebDb();
      return;
    }

    final db = await database;
    await db.update(
      'history',
      {'is_favorite': isFavorite ? 1 : 0, 'updated_at': now},
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> clearFavoriteRecords(Iterable<String> recordIds) async {
    final ids = recordIds.toSet();
    if (ids.isEmpty) return;

    final updatedAt = DateTime.now();
    final now = updatedAt.toIso8601String();

    if (kIsWeb) {
      await _loadWebDb();
      for (var i = 0; i < _webMemoryDb.length; i++) {
        final record = _webMemoryDb[i];
        if (ids.contains(record.id)) {
          _webMemoryDb[i] = record.copyWith(
            isFavorite: false,
            updatedAt: updatedAt,
          );
        }
      }
      await _persistWebDb();
      return;
    }

    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.update(
      'history',
      {'is_favorite': 0, 'updated_at': now},
      where: 'id IN ($placeholders)',
      whereArgs: ids.toList(),
    );
  }

  Future<void> setRecordRating(String recordId, int rating) async {
    final normalizedRating = rating.clamp(0, 5).toInt();
    final updatedAt = DateTime.now();
    final now = updatedAt.toIso8601String();

    if (kIsWeb) {
      await _loadWebDb();
      for (var i = 0; i < _webMemoryDb.length; i++) {
        final record = _webMemoryDb[i];
        if (record.id == recordId) {
          _webMemoryDb[i] = record.copyWith(
            rating: normalizedRating,
            updatedAt: updatedAt,
          );
        }
      }
      await _persistWebDb();
      return;
    }

    final db = await database;
    await db.update(
      'history',
      {'rating': normalizedRating, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  Future<void> clearAll() async {
    if (kIsWeb) {
      await _loadWebDb();
      _webMemoryDb.clear();
      await _persistWebDb();
      return;
    }

    final db = await database;
    await db.delete('history');
  }

  Future<void> deleteSession(String sessionId) async {
    if (kIsWeb) {
      await _loadWebDb();
      _webMemoryDb.removeWhere((record) => record.sessionId == sessionId);
      await _persistWebDb();
      return;
    }

    final db = await database;
    await db.delete('history', where: 'session_id = ?', whereArgs: [sessionId]);
  }

  Future<void> _loadWebDb() async {
    if (_webLoaded) return;

    try {
      final rawRecords = await _readWebHistoryPayload();
      if (rawRecords == null || rawRecords.isEmpty) {
        _webLoaded = true;
        return;
      }

      _webMemoryDb
        ..clear()
        ..addAll(_decodeWebRecords(rawRecords));

      await _persistWebDb();
    } catch (error) {
      debugPrint('Local history web load failed: $error');
      _webMemoryDb.clear();
    } finally {
      _webLoaded = true;
    }
  }

  Future<void> _persistWebDb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = _webMemoryDb.map((record) => record.toMap()).toList();
      final payload = jsonEncode(records);
      await _webStorage.write(_webStorageKey, payload);
      await _webStorage.write(_legacyWebStorageKey, payload);
      await prefs.setString(_webStorageKey, payload);
    } catch (error) {
      debugPrint('Local history web save failed: $error');
    }
  }

  Future<String?> _readWebHistoryPayload() async {
    final directPayload = _webStorage.read(_webStorageKey);
    if (directPayload != null && directPayload.isNotEmpty) {
      return directPayload;
    }

    final legacyPayload = _webStorage.read(_legacyWebStorageKey);
    if (legacyPayload != null && legacyPayload.isNotEmpty) {
      return legacyPayload;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_webStorageKey);
  }

  List<TranslationRecord> _decodeWebRecords(String payload) {
    final decoded = jsonDecode(payload);
    if (decoded is! List) return const [];

    final records = <TranslationRecord>[];
    for (final item in decoded) {
      if (item is! Map) continue;

      try {
        records.add(TranslationRecord.fromMap(Map<String, dynamic>.from(item)));
      } catch (error) {
        debugPrint('Skipping invalid local history record: $error');
      }
    }
    return records;
  }
}
