# Tối ưu hóa Mô hình cho Di động (ONNX & Quantization)

Để ứng dụng Flutter có thể chạy mô hình dịch thuật trực tiếp trên điện thoại mà không cần Internet (Offline Mode), mô hình gốc cần được thu gọn kích thước tối đa.

## Các tệp Notebook
* `Mobile_En_Vi.ipynb`
* `Mobile_Vi_En.ipynb`

## Link code Colab
https://colab.research.google.com/drive/1o8L9BvekrqGnB9Gcb5huOUu9LGPNsmaV?usp=sharing
https://colab.research.google.com/drive/13CtsFT-RXApjhMfIbIaDmSd7oIC1q0bO?usp=sharing

## Kỹ thuật sử dụng
Các notebook này thực hiện quy trình "ép cân" (Quantization) tự động bằng công cụ `optimum-cli`:
1. **Export ONNX:** Chuyển đổi đồ thị tính toán của PyTorch sang định dạng ONNX.
2. **Lượng tử hóa 8-bit:** Ép các trọng số 32-bit xuống số nguyên 8-bit. Quá trình này giúp giảm kích thước mô hình từ hàng trăm MB xuống **dưới 100MB** (khoảng 98MB) mà vẫn giữ được chất lượng dịch thuật.
3. **Đóng gói:** Các file `.onnx` và tokenizer (`.spm`) được gom lại thành file `.zip` để đưa vào mã nguồn Flutter.
