# Data Operations (Data_Ops) - Translation & RAG System

Thư mục này chịu trách nhiệm cho toàn bộ Data Pipeline của dự án, bao gồm thu thập, làm sạch dữ liệu, xây dựng đồ thị tri thức và quản trị cơ sở dữ liệu.

## Kiến trúc Xử lý Dữ liệu (Data Pipeline)

Hệ thống Data_Ops được chia thành 3 luồng xử lý chính:

### 1. Data Cleaning (Tiền xử lý & Làm sạch dữ liệu)
* **Mục tiêu:** Chắt lọc 600,000 cặp câu Anh - Việt chất lượng cao từ hơn 1 triệu dòng dữ liệu thô (nguồn: https://huggingface.co/datasets/vinai/PhoMT).
* **Kỹ thuật áp dụng:**
  * Xóa bỏ tags HTML, URLs, và khoảng trắng thừa.
  * Sử dụng **Regex Whitelist** chặn 100% các ngôn ngữ khác (Cyrillic/Nga, CJK/Trung-Nhật-Hàn, Emoji) và lỗi `#VALUE!` của Excel.
  * Sử dụng thư viện `langdetect` để kiểm tra chéo mặt ngữ nghĩa (ngăn chặn các ngoại ngữ khác).
  * Lọc lệch pha (Alignment check): Giữ lại các cặp câu có tỷ lệ độ dài (Vi/En) từ `0.33` đến `3.0`.
  * Áp dụng kỹ thuật **Oversampling** để tối ưu hóa thời gian chạy thuật toán phát hiện ngôn ngữ.

### 2. Knowledge Graph (Đồ thị Tri thức cho RAG)
* **Mục tiêu:** Xây dựng cơ sở dữ liệu vector hóa cho hệ thống RAG để cải thiện ngữ cảnh dịch thuật.
* **Kỹ thuật áp dụng:**
  * Trích xuất Thực thể có tên (NER) bằng thư viện `spaCy` (chỉ lấy PERSON, ORG, GPE, PRODUCT).
  * Vector hóa các thực thể thành vector 384 chiều sử dụng `SentenceTransformers` (model: `all-MiniLM-L6-v2`).
  * Tích hợp lên cơ sở dữ liệu Supabase thông qua extension `pgvector`.

### 3. Mock Data Generator (Tạo dữ liệu giả lập)
* **Mục tiêu:** Sinh dữ liệu lịch sử dịch thuật phục vụ kiểm thử hệ thống Backend/App và vẽ biểu đồ báo cáo.
* **Kỹ thuật áp dụng:** Sinh ngẫu nhiên rating (1-5 sao) và dàn trải thời gian theo phân phối chuẩn trong 30 ngày.

---

## Hướng dẫn Cài đặt và Khởi chạy

### Yêu cầu hệ thống
* Python 3.9+
* Cơ sở dữ liệu PostgreSQL (Khuyến nghị dùng Supabase)

### 1. Cài đặt môi trường
Mở terminal và chạy lệnh sau để cài đặt các thư viện cần thiết:
```bash
pip install -r requirements.txt
python -m spacy download en_core_web_sm
```

### 2. Khởi chạy pipeline
Chạy các script theo đúng thứ tự sau:
Làm sạch dữ liệu -> Xây dựng Knowledge Graph -> Bơm dữ liệu giả lập

## Cấu trúc cơ sở dữ liệu
Dự án triển khai 3 bảng chính trên PostgreSQL (Xem chi tiết trong database_schema.sql):
1. raw_data: Lưu trữ dữ liệu huấn luyện, chia thành các tập train, val, test.
2. knowledge_graph: Lưu trữ thông tin từ vựng, ngữ cảnh và Vector 384-chiều.
3. translation_history: Bảng log lịch sử thao tác người dùng (lưu rating, từ vựng yêu thích).
