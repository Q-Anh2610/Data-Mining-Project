# Ứng dụng chuyển ngữ Anh – Việt sử dụng mô hình AI

## Giới thiệu

Project xây dựng ứng dụng chuyển ngữ Anh – Việt sử dụng mô hình AI, kết hợp với kho dữ liệu Supabase, ứng dụng Flutter, Hugging Face Space, hệ quản trị Drupal CMS và dashboard BI.

Hệ thống cho phép người dùng nhập văn bản, nhận kết quả dịch, lưu lịch sử dịch và hỗ trợ phân tích dữ liệu lịch sử thông qua dashboard trực quan hóa.

Project được thực hiện trong khuôn khổ môn Khai phá dữ liệu.

## Công nghệ sử dụng

- Supabase: lưu trữ dữ liệu
- DBeaver: quản lý và làm sạch dữ liệu
- Google Colab: huấn luyện và kiểm thử mô hình AI
- Hugging Face: lưu trữ model
- Hugging Face Space: triển khai demo/API model
- Flutter: xây dựng ứng dụng người dùng
- Drupal CMS: xây dựng hệ quản trị
- Apache Superset: trực quan hóa dữ liệu BI
- Docker Desktop: hỗ trợ triển khai các dịch vụ
- GitHub: quản lý mã nguồn

## Cấu trúc thư mục

| Thư mục | Mô tả |
|---|---|
| `ai_service/` | Chứa các phần liên quan đến mô hình AI như train model, export model và API inference. |
| `app_web/` | Chứa phần ứng dụng giao diện người dùng. |
| `bi_dashboard/` | Chứa ảnh dashboard BI trực quan hóa dữ liệu lịch sử dịch. |
| `cms_drupal/` | Chứa hệ quản trị Drupal CMS và file cấu hình Docker. |
| `data_ops/` | Chứa schema cơ sở dữ liệu, script xử lý dữ liệu và cấu hình mẫu. |
| `qa_testing/` | Chứa dữ liệu kiểm thử và kết quả đánh giá bản dịch. |
