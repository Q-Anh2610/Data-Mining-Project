Kiểm thử Hiệu năng Dịch thuật (API Team vs. Google Translate)

Dự án này được thiết kế để kiểm thử và so sánh chất lượng dịch thuật giữa API của nhóm và công cụ Google Translate (thông qua thư viện `deep_translator`). Quá trình kiểm thử được thực hiện trên cả hai chiều: Tiếng Anh sang Tiếng Việt (En-Vi) và Tiếng Việt sang Tiếng Anh (Vi-En).

## Tổng quan dự án

Mục tiêu chính là tự động hóa việc gọi API dịch thuật, so sánh kết quả trả về với Google Translate và xuất ra báo cáo chi tiết dưới dạng tệp CSV để đánh giá độ chính xác (dựa trên việc so khớp chuỗi ký tự).

## Cấu trúc thư mục
Tất cả các tệp tin liên quan đều nằm trong thư mục `qa_testing`:

```text
└── qa_testing/
    ├── test.ipynb                # File notebook chứa mã nguồn chính
    ├── test_english.csv          # Chứa 100 câu mẫu tiếng Anh (Dữ liệu đầu vào)
    ├── test_vietnamese.csv       # Chứa 100 câu mẫu tiếng Việt (Dữ liệu đầu vào)
    ├── compareEnVi.csv           # Kết quả so sánh dịch Anh -> Việt (Dữ liệu đầu ra)
    └── compareViEn.csv           # Kết quả so sánh dịch Việt -> Anh (Dữ liệu đầu ra)
```
## Yêu cầu hệ thống
Để chạy được mã nguồn trong test.ipynb,cần cài đặt thư viện deep_translator để sử dụng Google Translator API.

Cài đặt thông qua pip:
```bash
pip install deep_translator
```
Ngoài ra, đảm bảo đã cài đặt các thư viện bổ trợ khác như pandas, requests.
