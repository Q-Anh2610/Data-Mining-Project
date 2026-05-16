---
title: Dich Thuat AI Nhom 05
emoji: 🌍
colorFrom: blue
colorTo: green
sdk: gradio
sdk_version: 5.0.1
app_file: app.py
pinned: false
python_version: '3.10'
---

# 🌐 Giao diện Web (Hugging Face Spaces)

Thư mục chứa mã nguồn Web App bằng **Gradio 5.x**, tối ưu để triển khai trực tiếp lên Hugging Face Spaces.

## Link Hugging Face
https://huggingface.co/spaces/Dich-Thuat-AI-Nhom-05/dich-thuat-api-nhom5

##  Tính năng chính
* **Dịch song ngữ:** Hỗ trợ hai chiều Anh ↔ Việt.
* **Lazy Loading:** Chỉ nạp mô hình vào RAM khi có yêu cầu dịch đầu tiên, tránh tràn bộ nhớ.
* **Knowledge Graph:** Kết nối Supabase qua REST API. Dùng Regex Masking/Restore để bảo vệ tên riêng khỏi bị dịch sai.
* **Caching:** Tối ưu hóa truy vấn bằng `@lru_cache`, kèm chức năng xóa cache khi cập nhật dữ liệu.
