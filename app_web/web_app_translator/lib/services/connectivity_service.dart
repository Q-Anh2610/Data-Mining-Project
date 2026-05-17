import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  Future<bool> hasInternetConnection() async {
    // Sửa lỗi kiểu dữ liệu: checkConnectivity trả về ConnectivityResult đơn lẻ
    final connectivityResult = await _connectivity.checkConnectivity();
    
    // Kiểm tra nếu không phải là none thì là có mạng
    return connectivityResult != ConnectivityResult.none;
  }

  Stream<bool> get onConnectivityChanged {
    // Sửa lỗi mapping
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }
}