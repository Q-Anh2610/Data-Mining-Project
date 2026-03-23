// File: lib/services/supabase_service.dart
// Lưu ý: Cần thêm package 'supabase_flutter' để code này hoạt động thật
import '../models/translation_record.dart';

class SupabaseService {
  // Giả lập instance của Supabase
  // Khi có thật, sẽ dùng: final _client = Supabase.instance.client;

  Future<void> syncRecord(TranslationRecord record) async {
    try {
      // Logic đẩy dữ liệu lên table 'translation_history'
      // await _client.from('translation_history').insert(record.toMap());
      
      print('🚀 [Supabase] Đã đồng bộ thành công bản dịch: ${record.sourceText}');
    } catch (e) {
      print('❌ [Supabase] Lỗi đồng bộ: $e');
    }
  }

  // Hàm này sẽ được gọi ngầm để đẩy các bản ghi offline bị kẹt lên server
  Future<void> syncPendingOfflineRecords(List<TranslationRecord> offlineRecords) async {
    // Duyệt qua danh sách và đẩy lên
    for (var record in offlineRecords) {
      await syncRecord(record);
    }
  }
}