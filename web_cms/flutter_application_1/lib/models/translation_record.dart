// File: lib/models/translation_record.dart
class TranslationRecord {
  final String id;
  final String sessionId; // <--- THÊM MỚI: Mã nhóm các câu dịch vào 1 phiên
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final String mode; 
  final DateTime createdAt;

  TranslationRecord({
    required this.id, required this.sessionId, required this.sourceText,
    required this.translatedText, required this.sourceLang, required this.targetLang,
    required this.mode, required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'session_id': sessionId, 'source_text': sourceText, 'translated_text': translatedText, 'source_lang': sourceLang, 'target_lang': targetLang, 'mode': mode, 'created_at': createdAt.toIso8601String()};
  }

  factory TranslationRecord.fromMap(Map<String, dynamic> map) {
    return TranslationRecord(id: map['id'], sessionId: map['session_id'], sourceText: map['source_text'], translatedText: map['translated_text'], sourceLang: map['source_lang'], targetLang: map['target_lang'], mode: map['mode'], createdAt: DateTime.parse(map['created_at']));
  }
}