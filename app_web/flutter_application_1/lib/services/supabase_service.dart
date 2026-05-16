// File: lib/services/supabase_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/translation_record.dart';

class SupabaseService {
  // Lấy client từ singleton Supabase đã khởi tạo trong main.dart
  SupabaseClient get _client => Supabase.instance.client;

  /// Đẩy một bản dịch lên bảng translation_history trên Supabase
  Future<void> syncRecord(TranslationRecord record) async {
    try {
      await _client.from('translation_history').insert({
        // Không truyền 'id' để hệ thống tự sinh mã UUID bằng hàm Postgres mặc định
        'input_text': record.sourceText,
        'output_text': record.translatedText,
        'rating': 5, // Tạm thời để mặc định là 5 
        'created_at': record.createdAt.toIso8601String(),
        'is_favorite': false,
      });
      debugPrint('🚀 [Supabase] ✅ Đã lưu dữ liệu người dùng lên bảng translation_history thành công: "${record.sourceText}"');
    } catch (e) {
      debugPrint('❌ [Supabase] Lỗi khi lưu dữ liệu lịch sử người dùng: $e');
    }
  }

  /// Đẩy hàng loạt các bản ghi bị pending (offline) lên server
  Future<void> syncPendingOfflineRecords(List<TranslationRecord> offlineRecords) async {
    for (var record in offlineRecords) {
      await syncRecord(record);
    }
  }
}