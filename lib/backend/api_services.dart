import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:onechat/constant/api_urls.dart'; // Ensure path is correct

class ApiServices {
  final Dio _dio = Dio(); // Added missing declaration
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true), // Fixed aOption -> aOptions
  );

  ApiServices() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 50); // Fixed typo
    _dio.options.receiveTimeout = const Duration(seconds: 50);

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? token = await _storage.read(key: "access_token");
        if (token != null) {
          options.headers["Authorization"] = "Bearer $token";
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401) {
          bool success = await refreshToken(); // Fixed == to =
          if (success) return handler.resolve(await _dio.fetch(e.requestOptions));
        }
        return handler.next(e);
      },
    ));
  }

  Future<bool> refreshToken() async {
    String? refresh = await _storage.read(key: "refresh_token");
    if (refresh == null) return false;
    try {
      final response = await Dio().post(refreshBaseUrl,
          options: Options(headers: {"Authorization": "Bearer $refresh"}));
      await _storage.write(key: "access_token", value: response.data["access_token"]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Dio get client => _dio;
}

// Global instance
final api = ApiServices();
// Global storage instance to use in splash/functions
const storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
