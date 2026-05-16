import 'dart:async';

class ModelLoaderService {
  /// Giả lập kiểm tra file .tflite trong máy
  Future<bool> isModelDownloaded() async {
    // Đợi 0.5 giây để tạo cảm giác App đang quét hệ thống
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TRẢ VỀ FALSE: Để ép App vào màn hình Hướng dẫn (theo Flowchart nhánh NO)
    // Sau này khi làm tính năng download thật, bạn sẽ đổi logic check file ở đây.
    return false; 
  }
}