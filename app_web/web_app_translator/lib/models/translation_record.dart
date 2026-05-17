class TranslationRecord {
  final String id;
  final String sessionId;
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final String mode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final int rating;

  TranslationRecord({
    required this.id,
    required this.sessionId,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.mode,
    required this.createdAt,
    DateTime? updatedAt,
    this.isFavorite = false,
    this.rating = 0,
  }) : updatedAt = updatedAt ?? createdAt;

  TranslationRecord copyWith({
    String? id,
    String? sessionId,
    String? sourceText,
    String? translatedText,
    String? sourceLang,
    String? targetLang,
    String? mode,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    int? rating,
  }) {
    return TranslationRecord(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      sourceLang: sourceLang ?? this.sourceLang,
      targetLang: targetLang ?? this.targetLang,
      mode: mode ?? this.mode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'source_text': sourceText,
      'translated_text': translatedText,
      'source_lang': sourceLang,
      'target_lang': targetLang,
      'mode': mode,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
      'rating': rating,
    };
  }

  factory TranslationRecord.fromMap(Map<String, dynamic> map) {
    final createdAt = DateTime.parse(map['created_at'] as String);
    final updatedAtValue = map['updated_at'];
    final favoriteValue = map['is_favorite'];
    final ratingValue = map['rating'];
    final parsedRating = ratingValue is int
        ? ratingValue
        : int.tryParse(ratingValue?.toString() ?? '') ?? 0;

    return TranslationRecord(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      sourceText: map['source_text'] as String,
      translatedText: map['translated_text'] as String,
      sourceLang: map['source_lang'] as String,
      targetLang: map['target_lang'] as String,
      mode: map['mode'] as String,
      createdAt: createdAt,
      updatedAt: updatedAtValue is String && updatedAtValue.isNotEmpty
          ? DateTime.parse(updatedAtValue)
          : createdAt,
      isFavorite: favoriteValue == true || favoriteValue == 1,
      rating: parsedRating.clamp(0, 5).toInt(),
    );
  }

  static List<TranslationRecord> sortHistorySessions(
    Iterable<TranslationRecord> records,
  ) {
    final sorted = List<TranslationRecord>.from(records);
    sorted.sort(compareHistorySessions);
    return sorted;
  }

  static int compareHistorySessions(TranslationRecord a, TranslationRecord b) {
    if (a.isFavorite != b.isFavorite) {
      return a.isFavorite ? -1 : 1;
    }

    final updatedCompare = b.updatedAt.compareTo(a.updatedAt);
    if (updatedCompare != 0) return updatedCompare;

    return b.createdAt.compareTo(a.createdAt);
  }
}
