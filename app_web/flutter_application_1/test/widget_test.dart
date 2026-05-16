import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/translation_record.dart';
import 'package:flutter_application_1/shared/translator_ui.dart';

void main() {
  test(
    'sorts favorite history sessions before regular sessions by latest time',
    () {
      final baseTime = DateTime(2026, 1, 1);
      final regularNewest = _record(
        id: 'regular-newest',
        sessionId: 'regular-newest',
        updatedAt: baseTime.add(const Duration(hours: 3)),
      );
      final favoriteOld = _record(
        id: 'favorite-old',
        sessionId: 'favorite-old',
        updatedAt: baseTime.add(const Duration(hours: 1)),
        isFavorite: true,
      );
      final favoriteNewest = _record(
        id: 'favorite-newest',
        sessionId: 'favorite-newest',
        updatedAt: baseTime.add(const Duration(hours: 2)),
        isFavorite: true,
      );

      final sorted = TranslationRecord.sortHistorySessions([
        regularNewest,
        favoriteOld,
        favoriteNewest,
      ]);

      expect(sorted.map((record) => record.id), [
        'favorite-newest',
        'favorite-old',
        'regular-newest',
      ]);
    },
  );

  test('resolves English and US labels to US flag', () {
    expect(TranslatorLanguageFlags.resolve('English'), TranslatorFlagType.us);
    expect(TranslatorLanguageFlags.resolve('US'), TranslatorFlagType.us);
    expect(TranslatorLanguageFlags.resolve('Mỹ'), TranslatorFlagType.us);
  });

  test('resolves Vietnamese and VN labels to Vietnam flag', () {
    expect(
      TranslatorLanguageFlags.resolve('Vietnamese'),
      TranslatorFlagType.vietnam,
    );
    expect(TranslatorLanguageFlags.resolve('VN'), TranslatorFlagType.vietnam);
    expect(
      TranslatorLanguageFlags.resolve('Việt Nam'),
      TranslatorFlagType.vietnam,
    );
  });
}

TranslationRecord _record({
  required String id,
  required String sessionId,
  required DateTime updatedAt,
  bool isFavorite = false,
}) {
  return TranslationRecord(
    id: id,
    sessionId: sessionId,
    sourceText: 'hello',
    translatedText: 'xin chao',
    sourceLang: 'English',
    targetLang: 'Vietnamese',
    mode: 'text',
    createdAt: updatedAt.subtract(const Duration(minutes: 1)),
    updatedAt: updatedAt,
    isFavorite: isFavorite,
  );
}
