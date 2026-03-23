// File: lib/shared/app_translations.dart
class AppTrans {
  static String t(String lang, String key) {
    final Map<String, Map<String, String>> dict = {
      'English': {
        // ... (giữ nguyên các từ cũ) ...
        'title': 'Translator',
        'home': 'Home',
        'history': 'History',
        'settings': 'Settings',
        'start_chat': 'Start translation chat...',
        'type_here': 'Type text to translate...',
        'clear_all': 'Clear all',
        'empty_history': 'Empty No History',
        'delete_all': 'Delete All',
        'delete_confirm': 'Are you sure you want to\ndelete translate history?',
        'delete': 'Delete',
        'cancel': 'Cancel',
        'text_size': 'Text Size',
        'app_lang': 'App Language',
        'English': 'English',
        'Vietnamese': 'Vietnamese',
        'no_data': 'No data available',
        'theme': 'Theme',
        'light': 'Light',
        'dark': 'Dark',
        
        // --- TỪ MỚI CHO START SCREEN ---
        'app_name': 'ACDHL\'s Translator',
        'app_desc': 'Translate everything!',
        'i_accept': 'I accept the ',
        'privacy_policy': 'Privacy policy',
        'start_btn': 'START',
        'ok_btn': 'OK',
        'privacy_content': '1. Information Collection\nWe do not collect any personal data. All translation history is stored locally on your device.\n\n2. Usage\nThis app requires an internet connection to perform translations.\n\n3. Third-party Services\nWe use Google translation APIs to process your text.',
      },
      'Vietnamese': {
        // ... (giữ nguyên các từ cũ) ...
        'title': 'Trình Dịch',
        'home': 'Trang chủ',
        'history': 'Lịch sử',
        'settings': 'Cài đặt',
        'start_chat': 'Bắt đầu cuộc trò chuyện dịch thuật...',
        'type_here': 'Nhập văn bản cần dịch...',
        'clear_all': 'Xóa tất cả',
        'empty_history': 'Chưa có lịch sử dịch',
        'delete_all': 'Xóa tất cả',
        'delete_confirm': 'Bạn có chắc chắn muốn\nxóa toàn bộ lịch sử dịch?',
        'delete': 'Xóa',
        'cancel': 'Hủy',
        'text_size': 'Kích cỡ chữ',
        'app_lang': 'Ngôn ngữ ứng dụng',
        'English': 'Tiếng Anh',
        'Vietnamese': 'Tiếng Việt',
        'no_data': 'Không có dữ liệu',
        'theme': 'Giao diện',
        'light': 'Sáng',
        'dark': 'Tối',
        
        // --- TỪ MỚI CHO START SCREEN ---
        'app_name': 'Trình dịch ACDHL',
        'app_desc': 'Dịch mọi thứ!',
        'i_accept': 'Tôi đồng ý với ',
        'privacy_policy': 'Chính sách bảo mật',
        'start_btn': 'BẮT ĐẦU',
        'ok_btn': 'ĐỒNG Ý',
        'privacy_content': '1. Thu thập thông tin\nChúng tôi không thu thập bất kỳ dữ liệu cá nhân nào. Mọi lịch sử dịch được lưu trực tiếp trên máy của bạn.\n\n2. Sử dụng\nỨng dụng cần kết nối mạng để thực hiện việc dịch thuật.\n\n3. Dịch vụ bên thứ ba\nChúng tôi sử dụng API dịch của Google để xử lý văn bản.',
      }
    };
    return dict[lang]?[key] ?? key;
  }
}