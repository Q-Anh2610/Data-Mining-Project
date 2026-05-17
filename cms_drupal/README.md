# Drupal CMS

Thư mục này chứa các thành phần liên quan đến hệ quản trị CMS bằng Drupal trong project **Ứng dụng chuyển ngữ Anh – Việt sử dụng mô hình AI**.

Drupal CMS được sử dụng để xây dựng phần quản trị nội dung cho hệ thống, hỗ trợ nhóm quản lý thông tin giới thiệu, hướng dẫn sử dụng, liên kết tải ứng dụng và các nội dung liên quan đến project.

## Vai trò của Drupal CMS

Trong project, Drupal CMS đóng vai trò là hệ quản trị dành cho phía quản trị viên. Thành phần này không trực tiếp thực hiện chức năng dịch, nhưng hỗ trợ quản lý và tổ chức các nội dung liên quan đến hệ thống.

Một số mục đích sử dụng chính:

- Quản lý nội dung giới thiệu ứng dụng
- Quản lý thông tin nhóm phát triển
- Tạo trang hướng dẫn sử dụng
- Cung cấp liên kết tải file APK hoặc bản web
- Hỗ trợ trình bày sản phẩm trong quá trình demo

## Công nghệ sử dụng

- Drupal CMS
- Docker Desktop
- Docker Compose

## Cấu trúc thư mục
```text
cms_drupal/
├── modules/              # Thư mục chứa module Drupal
├── profiles/             # Thư mục chứa profile cài đặt Drupal
├── sites/default/        # Cấu hình site mặc định
├── themes/               # Thư mục chứa giao diện Drupal
├── docker-compose.yml    # File cấu hình chạy Drupal bằng Docker
└── README.md
