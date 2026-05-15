markdown_content = """# Dự án So sánh Hiệu năng Dịch thuật (API Team vs. Google Translate)

Dự án này được thiết kế để kiểm thử và so sánh chất lượng dịch thuật giữa API của nhóm chúng tôi và công cụ Google Translate (thông qua thư viện `deep_translator`). Quá trình kiểm thử được thực hiện trên cả hai chiều: Tiếng Anh sang Tiếng Việt (En-Vi) và Tiếng Việt sang Tiếng Anh (Vi-En).

## 📌 Tổng quan dự án

Mục tiêu chính của repository này là tự động hóa việc gọi API dịch thuật, so sánh kết quả trả về với Google Translate và xuất ra báo cáo chi tiết dưới dạng tệp CSV để đánh giá độ chính xác (dựa trên việc so khớp chuỗi ký tự).

## 📁 Cấu trúc thư mục

```text
├── github/
│   ├── test_english.csv      # Chứa 100 câu mẫu tiếng Anh
│   └── test_vietnamese.csv   # Chứa 100 câu mẫu tiếng Việt
├── test.ipynb                # File notebook chứa mã nguồn chính
├── compareEnVi.csv           # Kết quả so sánh dịch Anh -> Việt (sinh ra sau khi chạy code)
├── compareViEn.csv           # Kết quả so sánh dịch Việt -> Anh (sinh ra sau khi chạy code)
└── README.md                 # Hướng dẫn sử dụng
