import 'dart:async';
import 'package:flutter/services.dart';

class ModelLoaderService {
  /// Kiểm tra file model trong thư mục assets (vì đã đóng gói kèm APK)
  Future<bool> isModelDownloaded() async {
    try {
      // Thử đọc 1 file để xác nhận Model đã được đóng gói thành công vào APK
      await rootBundle.load('assets/mobile_translator_en_vi/vocab.json');
      return true; 
    } catch (e) {
      print("❌ Lỗi không tìm thấy mô hình Offline: $e");
      return false; 
    }
  }
}