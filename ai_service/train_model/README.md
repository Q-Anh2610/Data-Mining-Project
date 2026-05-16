# Huấn luyện Mô hình (Training)

Thư mục này chứa các kịch bản Jupyter Notebook dùng để fine-tune mạng nơ-ron Seq2Seq phục vụ cho việc dịch thuật. Môi trường khuyến nghị để chạy các file này là **Google Colab (GPU Tesla T4)**.

## Các tệp Python
1. `Train_En_Vi.py`: Huấn luyện mô hình dịch từ tiếng Anh sang tiếng Việt.
2. `Train_Vi_En.py`: Huấn luyện mô hình dịch từ tiếng Việt sang tiếng Anh.

## link code colab
https://colab.research.google.com/drive/1OoWBJDXAGo_yzEdYGl2USJZ2MjcjaTwd?usp=sharing
https://colab.research.google.com/drive/1ELQTO7U0Lwl0yBKUpgtumyIZX9911PD-?usp=sharing

## Quy trình hoạt động
1. **Kết nối Database:** Cài đặt `psycopg2` và `sqlalchemy` để kéo dữ liệu đồ thị tri thức từ Supabase.
2. **Tiền xử lý:** Sử dụng `sentencepiece` và `sacremoses` để mã hóa (tokenize) văn bản.
3. **Huấn luyện:** Sử dụng thư viện `transformers` của Hugging Face để điều chỉnh trọng số mô hình.
4. **Lưu trữ:** Đẩy (Push) trực tiếp trọng số mô hình đã huấn luyện xong lên tổ chức Hugging Face Hub của nhóm (`Dich-Thuat-AI-Nhom-05`).
