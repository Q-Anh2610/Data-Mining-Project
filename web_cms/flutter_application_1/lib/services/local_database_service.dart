// File: lib/services/local_database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/translation_record.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Database? _database;
  final List<TranslationRecord> _webMemoryDb = [];

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('translator_history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, // <--- Nâng version lên 2 để cập nhật bảng
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS history');
        await db.execute('''CREATE TABLE history (id TEXT PRIMARY KEY, session_id TEXT, source_text TEXT, translated_text TEXT, source_lang TEXT, target_lang TEXT, mode TEXT, created_at TEXT)''');
      },
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE history (id TEXT PRIMARY KEY, session_id TEXT, source_text TEXT, translated_text TEXT, source_lang TEXT, target_lang TEXT, mode TEXT, created_at TEXT)''');
      },
    );
  }

  Future<void> insertRecord(TranslationRecord record) async {
    if (kIsWeb) { _webMemoryDb.add(record); return; }
    final db = await database;
    await db.insert('history', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // --- LẤY DANH SÁCH CÁC PHIÊN CHAT (DÙNG CHO SIDEBAR) ---
  Future<List<TranslationRecord>> getHistorySessions() async {
    if (kIsWeb) {
      final Map<String, TranslationRecord> sessions = {};
      for (var r in _webMemoryDb) { if (!sessions.containsKey(r.sessionId)) sessions[r.sessionId] = r; }
      return sessions.values.toList().reversed.toList();
    }
    final db = await database;
    // GROUP BY session_id để lấy câu đầu tiên của mỗi phiên làm tiêu đề
    final List<Map<String, dynamic>> maps = await db.rawQuery('SELECT * FROM history GROUP BY session_id ORDER BY created_at DESC');
    return List.generate(maps.length, (i) => TranslationRecord.fromMap(maps[i]));
  }

  // --- LẤY TOÀN BỘ CÂU DỊCH TRONG 1 PHIÊN CỤ THỂ ---
  Future<List<TranslationRecord>> getRecordsBySession(String sessionId) async {
    if (kIsWeb) { return _webMemoryDb.where((r) => r.sessionId == sessionId).toList(); }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('history', where: 'session_id = ?', whereArgs: [sessionId], orderBy: 'created_at ASC');
    return List.generate(maps.length, (i) => TranslationRecord.fromMap(maps[i]));
  }

  Future<void> clearAll() async {
    if (kIsWeb) { _webMemoryDb.clear(); return; }
    final db = await database; await db.delete('history');
  }

  Future<void> deleteSession(String sessionId) async {
    if (kIsWeb) { _webMemoryDb.removeWhere((r) => r.sessionId == sessionId); return; }
    final db = await database; await db.delete('history', where: 'session_id = ?', whereArgs: [sessionId]);
  }
}