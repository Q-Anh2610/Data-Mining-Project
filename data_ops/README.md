# Data Operations (Data_Ops) - Translation & RAG System

Thư mục này chịu trách nhiệm cho toàn bộ Data Pipeline của dự án, bao gồm thu thập, làm sạch dữ liệu, xây dựng đồ thị tri thức và quản trị cơ sở dữ liệu.

---

## Kiến trúc Xử lý Dữ liệu (Data Pipeline)

Hệ thống Data_Ops được chia thành 3 luồng xử lý chính:

### 1. Data Cleaning (Tiền xử lý & Làm sạch dữ liệu)

- **Mục tiêu:** Chắt lọc 600.000 cặp câu Anh – Việt chất lượng cao từ gần 3 triệu dòng dữ liệu thô (nguồn: https://huggingface.co/datasets/vinai/PhoMT).
- **Kỹ thuật áp dụng:**
  - Xóa bỏ tags HTML, URLs và khoảng trắng thừa.
  - Chuẩn hóa Unicode (NFC) để đảm bảo ký tự tiếng Việt có dấu được biểu diễn nhất quán.
  - Sử dụng **Regex Whitelist** chặn 100% các ngôn ngữ không liên quan (Cyrillic/Nga, CJK/Trung–Nhật–Hàn, Emoji) và lỗi `#VALUE!` của Excel – chỉ giữ lại ký tự Latinh, tiếng Việt có dấu, chữ số và dấu câu cơ bản.
  - Sử dụng thư viện `langdetect` để kiểm tra chéo mặt ngữ nghĩa, ngăn chặn các câu ngôn ngữ khác lọt qua bộ lọc Regex.
  - Áp dụng kỹ thuật **Oversampling** để tối ưu hóa thời gian chạy thuật toán phát hiện ngôn ngữ trên tập dữ liệu lớn.
  - Lọc lệch pha (Alignment check): Giữ lại các cặp câu có tỷ lệ độ dài (Vi/En) từ `0.33` đến `3.0`.
  - Lọc độ dài token: chỉ giữ câu có từ `5` đến `80` token.
  - Loại bỏ bản ghi trùng lặp và giá trị rỗng.

### 2. Knowledge Graph (Đồ thị Tri thức cho RAG)

- **Mục tiêu:** Xây dựng cơ sở dữ liệu vector hóa cho hệ thống RAG để cải thiện ngữ cảnh dịch thuật.
- **Kỹ thuật áp dụng:**
  - Trích xuất thực thể có tên (NER) bằng model `dslim/bert-base-NER` từ thư viện `transformers` (pipeline với `aggregation_strategy="simple"`), nhận diện các loại: `PERSON`, `ORG`, `LOCATION`, `OTHER`.
  - Bổ sung rule-based extraction để nhận diện các thực thể kỹ thuật (ngôn ngữ lập trình, framework, database, cloud, model AI) không được NER thống kê học phát hiện tốt.
  - Chuẩn hóa tên thực thể (normalize) và quản lý tên gọi thay thế (aliases) để đảm bảo nhất quán xuyên ngôn ngữ.
  - Vector hóa các thực thể thành vector **384 chiều** sử dụng `SentenceTransformers` (model: `intfloat/multilingual-e5-small`).
  - Tích hợp lên cơ sở dữ liệu Supabase thông qua extension `pgvector`.
  - Sử dụng cache cục bộ (`entity_cache`) để tránh truy vấn trùng lặp, tăng hiệu suất pipeline.

### 3. Mock Data Generator (Tạo dữ liệu giả lập)

- **Mục tiêu:** Sinh dữ liệu lịch sử dịch thuật phục vụ kiểm thử hệ thống Backend/App và vẽ biểu đồ báo cáo.
- **Kỹ thuật áp dụng:** Sinh ngẫu nhiên `rating` (1–5 sao) và `is_favorite`, dàn trải thời gian theo phân phối chuẩn trong 30 ngày, ghi vào bảng `translation_history` trên Supabase.

---

## Hướng dẫn Cài đặt và Khởi chạy

### Yêu cầu hệ thống

- Python 3.9+
- Cơ sở dữ liệu PostgreSQL (Khuyến nghị dùng Supabase)

### 1. Cấu hình kết nối Supabase

Tạo file `.env` ở thư mục gốc và điền các thông tin xác thực:

```env
SUPABASE_URL=https://<project-ref>.supabase.co
SUPABASE_KEY=<service_role_key>
```

> ⚠️ **Lưu ý bảo mật:** Sử dụng **Service Role Key** (không phải Anon Key) để pipeline có đủ quyền đọc/ghi tất cả các bảng. Không commit file `.env` lên repository.

Nếu cần kết nối trực tiếp qua PostgreSQL (dùng cho Google Colab hoặc SQLAlchemy):

```
postgresql://postgres:<password>@db.<project-ref>.supabase.co:5432/postgres
```

### 2. Cài đặt môi trường

```bash
pip install -r requirements.txt
```

### 3. Khởi chạy pipeline

Chạy các script theo đúng thứ tự sau:

```
1. Data Cleaning       →   Làm sạch và lọc dữ liệu thô từ PhoMT
2. Knowledge Graph     →   Trích xuất thực thể, sinh embedding, đẩy lên Supabase
3. Mock Data Generator →   Bơm dữ liệu giả lập vào bảng translation_history
```

---

## Cấu trúc cơ sở dữ liệu

Dự án triển khai **5 bảng chính** trên PostgreSQL/Supabase (xem chi tiết trong `database_schema.sql`):

### `raw_data`
Lưu trữ dữ liệu song ngữ Anh – Việt đã làm sạch, phục vụ huấn luyện mô hình.

| Trường | Kiểu | Mô tả |
|---|---|---|
| `id` | UUID | Khóa chính, tự động sinh |
| `english_text` | TEXT | Câu nguồn tiếng Anh |
| `vietnamese_text` | TEXT | Câu dịch tiếng Việt |
| `source` | VARCHAR | Nguồn dữ liệu (PhoMT, crawled...) |
| `created_at` | TIMESTAMP | Thời gian tạo bản ghi |

### `translation_history`
Bảng log lịch sử dịch thuật của người dùng, hỗ trợ đồng bộ offline.

| Trường | Kiểu | Mô tả |
|---|---|---|
| `id` | UUID | Khóa chính |
| `device_id` | VARCHAR | Mã thiết bị, hỗ trợ đồng bộ offline |
| `input_text` | TEXT | Nội dung người dùng nhập vào |
| `output_text` | TEXT | Kết quả bản dịch |
| `rating` | INT | Đánh giá chất lượng (1–5), có thể rỗng |
| `is_favorite` | BOOL | Đánh dấu yêu thích (mặc định false) |
| `model_version` | VARCHAR | Phiên bản mô hình AI sử dụng |
| `created_at` | TIMESTAMP TZ | Thời gian thực hiện |

### `knowledge_graph_entities`
Bảng trung tâm của Knowledge Graph, lưu thực thể và vector embedding.

| Trường | Kiểu | Mô tả |
|---|---|---|
| `id` | UUID | Khóa chính |
| `entity_name` | VARCHAR(255) | Tên thực thể gốc |
| `normalized_name` | VARCHAR | Tên chuẩn hóa (có đánh Index) |
| `entity_type` | VARCHAR | Loại thực thể (PERSON, ORG, LOCATION...) |
| `language` | VARCHAR | Ngôn ngữ của thực thể |
| `frequency` | INT | Số lần xuất hiện trong dataset |
| `preserve_in_translation` | BOOL | Giữ nguyên khi dịch (mặc định true) |
| `is_translatable` | BOOL | Có thể dịch hay không |
| `embedding` | VECTOR(384) | Vector embedding 384 chiều (pgvector) |
| `source` | VARCHAR | Nguồn dữ liệu |

### `knowledge_graph_aliases`
Lưu các tên gọi thay thế của cùng một thực thể.

| Trường | Kiểu | Mô tả |
|---|---|---|
| `id` | UUID | Khóa chính |
| `entity_id` | UUID (FK) | Tham chiếu đến `knowledge_graph_entities` |
| `alias` | VARCHAR | Tên gọi thay thế |
| `normalized_alias` | VARCHAR | Alias đã chuẩn hóa (có đánh Index) |
| `language` | VARCHAR | Ngôn ngữ của alias |
| `created_at` | TIMESTAMP TZ | Thời gian tạo bản ghi |

### `knowledge_graph_mentions`
Lưu ngữ cảnh xuất hiện của thực thể trong câu văn, phục vụ NER và contextual translation.

| Trường | Kiểu | Mô tả |
|---|---|---|
| `id` | UUID | Khóa chính |
| `entity_id` | UUID (FK) | Tham chiếu đến `knowledge_graph_entities` |
| `source_sentence` | TEXT | Câu văn gốc chứa thực thể |
| `detected_label` | VARCHAR | Nhãn thực thể được nhận diện |
| `confidence` | FLOAT | Độ tin cậy của nhận diện (0–1) |
| `language` | VARCHAR | Ngôn ngữ của câu nguồn |
| `created_at` | TIMESTAMP TZ | Thời gian tạo bản ghi |

> **Quan hệ:** Bảng `knowledge_graph_aliases` và `knowledge_graph_mentions` đều liên kết với `knowledge_graph_entities` qua khóa ngoại `entity_id`.

---

## Công nghệ sử dụng

| Thành phần | Công nghệ |
|---|---|
| Ngôn ngữ | Python 3.9+ |
| NER | `dslim/bert-base-NER` (transformers) |
| Embedding | `intfloat/multilingual-e5-small` (sentence-transformers), 384 chiều |
| Cơ sở dữ liệu | Supabase (PostgreSQL + pgvector) |
| Phát hiện ngôn ngữ | `langdetect` |
| Xử lý dữ liệu | `pandas`, `tqdm`, `unidecode` |
| Kết nối Supabase | `supabase-py` |
