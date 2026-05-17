import 'package:web/web.dart' as web;

class WebHistoryStorage {
  String? read(String key) => web.window.localStorage.getItem(key);

  Future<void> write(String key, String value) async {
    web.window.localStorage.setItem(key, value);
  }

  Future<void> remove(String key) async {
    web.window.localStorage.removeItem(key);
  }
}
