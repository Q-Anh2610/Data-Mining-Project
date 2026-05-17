import 'dart:convert';
import 'package:http/http.dart' as http;

class HuggingFaceService {
  // Base URL của Space (Không cần tự định vị host như code cũ nữa)
  final String _baseUrl =
      'https://dich-thuat-ai-nhom-05-dich-thuat-api-nhom5.hf.space';

  // Token của bạn
  final String _hfToken = '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';

  Future<String> translateText(String text, String sourceLang) async {
    String mode = (sourceLang == 'English' || sourceLang == 'en')
        ? 'Anh -> Việt'
        : 'Việt -> Anh';

    print("=========================================");
    print("🚀 BẮT ĐẦU VÀO HÀNG ĐỢI (GRADIO QUEUE)...");
    print("📝 Câu gốc: $text | Chế độ: $mode");

    try {
      // ---------------------------------------------------------
      // BƯỚC 1: XẾP HÀNG LẤY VÉ (Dùng đúng /call/translate_logic)
      // ---------------------------------------------------------
      final String queueUrl = '$_baseUrl/gradio_api/call/translate_logic';
      print("🎫 Đang lấy vé chờ tại: $queueUrl");

      final joinResponse = await http.post(
        Uri.parse(queueUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_hfToken',
        },
        body: jsonEncode({
          "data": [text, mode, true], // text, mode, use_kg
        }),
      );

      if (joinResponse.statusCode != 200) {
        return "Lỗi xếp hàng (${joinResponse.statusCode}): ${joinResponse.body}";
      }

      // Rút thẻ chờ (Event ID)
      final String eventId = jsonDecode(joinResponse.body)['event_id'];
      print("✅ Đã lấy được vé: $eventId. Đang chờ AI dịch...");

      // ---------------------------------------------------------
      // BƯỚC 2: LẮNG NGHE LUỒNG DỮ LIỆU BẰNG EVENT_ID
      // ---------------------------------------------------------
      final streamResponse = await http.get(
        Uri.parse('$queueUrl/$eventId'),
        headers: {'Authorization': 'Bearer $_hfToken'},
      );

      print("📦 Đã nhận luồng phản hồi, đang giải mã...");

      // Quét từng dòng stream để tìm sự kiện hoàn thành
      final lines = streamResponse.body.split('\n');
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('event: complete')) {
          // Lấy dòng data ngay bên dưới sự kiện complete
          if (i + 1 < lines.length && lines[i + 1].startsWith('data: ')) {
            String jsonData = lines[i + 1].substring(6); // Cắt bỏ chữ "data: "

            var parsed = jsonDecode(jsonData);
            if (parsed is List && parsed.isNotEmpty) {
              String ketQua = parsed[0].toString();
              print("🎉 THÀNH CÔNG RỰC RỠ: $ketQua");
              return ketQua;
            }
          }
        } else if (lines[i].startsWith('event: error')) {
          print("❌ Server báo lỗi trong lúc dịch.");
          return "Lỗi: Backend trả về sự kiện error.";
        }
      }

      return "Lỗi: Không tìm thấy sự kiện hoàn thành từ server.";
    } catch (e) {
      print("❌ LỖI NGOẠI LỆ: $e");
      return "Lỗi kết nối: $e";
    }
  }

  Future<String> doRefresh() async {
    try {
      final String queueUrl = '$_baseUrl/gradio_api/call/do_refresh';
      print("🎫 Đang lấy vé chờ tại: $queueUrl");

      final joinResponse = await http.post(
        Uri.parse(queueUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_hfToken',
        },
        body: jsonEncode({"data": []}),
      );

      if (joinResponse.statusCode != 200) {
        return "Lỗi xếp hàng (${joinResponse.statusCode}): ${joinResponse.body}";
      }

      // Rút thẻ chờ (Event ID)
      final String eventId = jsonDecode(joinResponse.body)['event_id'];
      print("✅ Đã lấy được vé refresh: $eventId. Đang chờ phản hồi...");

      // LẮNG NGHE LUỒNG DỮ LIỆU BẰNG EVENT_ID
      final streamResponse = await http.get(
        Uri.parse('$queueUrl/$eventId'),
        headers: {'Authorization': 'Bearer $_hfToken'},
      );

      final lines = streamResponse.body.split('\n');
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('event: complete')) {
          if (i + 1 < lines.length && lines[i + 1].startsWith('data: ')) {
            String jsonData = lines[i + 1].substring(6);
            var parsed = jsonDecode(jsonData);
            if (parsed is List && parsed.isNotEmpty) {
              print("🎉 THÀNH CÔNG RỰC RỠ!!!");
              return parsed[0].toString();
            }
          }
        } else if (lines[i].startsWith('event: error')) {
          return "Lỗi: Backend trả về sự kiện error.";
        }
      }
      return "Lỗi: Không tìm thấy sự kiện hoàn thành từ server.";
    } catch (e) {
      print("❌ LỖI NGOẠI LỆ: $e");
      return "Lỗi kết nối: $e";
    }
  }
}
