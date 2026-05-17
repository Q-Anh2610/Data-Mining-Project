# Mobile App - AI Translator

AI Translator là ứng dụng dịch văn bản được xây dựng bằng Flutter. Ứng dụng hỗ trợ dịch hai chiều Anh - Việt và Việt - Anh, có thể chạy trên Android và Web. Mục tiêu của ứng dụng là cung cấp giao diện đơn giản để người dùng nhập văn bản, nhận kết quả dịch, nghe phát âm, lưu lại lịch sử dịch và đánh giá chất lượng bản dịch.

## Công nghệ sử dụng

Ứng dụng sử dụng Flutter và Dart để phát triển giao diện đa nền tảng. BLoC được dùng để quản lý trạng thái, giúp tách phần giao diện khỏi phần xử lý logic. Các chức năng dịch online được kết nối thông qua API, trong khi chế độ offline trên native sử dụng model ONNX được đóng gói cùng ứng dụng. Ngoài ra, ứng dụng còn sử dụng Flutter TTS để đọc văn bản, lưu trữ cục bộ để quản lý lịch sử và Supabase để hỗ trợ đồng bộ dữ liệu.

## Chức năng chính

- Dịch văn bản Anh - Việt và Việt - Anh.
- Chạy được trên Android và Web.
- Hỗ trợ dịch online thông qua API.
- Hỗ trợ dịch offline trên Android/native bằng model ONNX.
- Lưu lịch sử dịch trên thiết bị.
- Đánh dấu bản dịch yêu thích.
- Đánh giá bản dịch bằng số sao.
- Đọc văn bản bằng Flutter TTS.
- Build bản Web và deploy lên Netlify.

## Cài đặt môi trường

Trước khi chạy ứng dụng, cần cài đặt Flutter SDK, Dart SDK, Android Studio hoặc Visual Studio Code, Android SDK và Chrome nếu muốn chạy bản Web.

Kiểm tra môi trường Flutter:

```bash
flutter doctor
