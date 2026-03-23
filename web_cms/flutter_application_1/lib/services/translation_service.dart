// File: lib/services/translation_service.dart

// ĐÃ SỬA LỖI: Dùng đường dẫn chuẩn xác để trỏ tới file Model
import 'package:flutter_application_1/models/translation_record.dart';

class TranslationService {
  
  Future<TranslationRecord> executeTranslation(
    String sessionId, // Tham số này dùng để nhóm các câu chat
    String sourceText, 
    String sourceLang, 
    String targetLang
  ) async {
    
    // Giả lập delay mạng 2 giây
    await Future.delayed(const Duration(seconds: 2));

    if (sourceText.trim().toLowerCase() == "error") {
      throw Exception("Mất kết nối tới máy chủ Hugging Face (Mock Error)!");
    }

    return TranslationRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sessionId: sessionId, // Gắn Session ID vào Record
      sourceText: sourceText,
      translatedText: "Xin chào (Mock Data): $sourceText",
      sourceLang: sourceLang,
      targetLang: targetLang,
      mode: 'online',
      createdAt: DateTime.now(),
    );
  }
}