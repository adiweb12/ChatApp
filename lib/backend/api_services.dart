import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:onechat/constant/api_urls.dart';

class ApiServices {
  final Dio _dio = Dio();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  ApiServices() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 50);
    _dio.options.receiveTimeout = const Duration(seconds: 50);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: "access_token");

          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }

          return handler.next(options);
        },

        onError: (DioException e, handler) async {
          // 🚨 Prevent infinite loop
          if (e.response?.statusCode == 401 &&
              e.requestOptions.extra["retry"] != true) {
            
            bool success = await _refreshToken();

            if (success) {
              final newToken = await _storage.read(key: "access_token");

              // 🔥 Mark request as retried
              e.requestOptions.extra["retry"] = true;

              // 🔥 Update header
              e.requestOptions.headers["Authorization"] = "Bearer $newToken";

              return handler.resolve(await _dio.fetch(e.requestOptions));
            }
          }

          return handler.next(e);
        },
      ),
    );
  }

  // 🔄 REFRESH TOKEN
  Future<bool> _refreshToken() async {
    final refresh = await _storage.read(key: "refresh_token");

    if (refresh == null) return false;

    try {
      final response = await Dio().post(
        refreshBaseUrl,
        options: Options(
          headers: {"Authorization": "Bearer $refresh"},
        ),
      );

      await _storage.write(
        key: "access_token",
        value: response.data["access_token"],
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  Dio get client => _dio;
}

// ✅ GLOBAL INSTANCE
final api = ApiServices();

// ✅ GLOBAL STORAGE
const storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);
Future<String?> getToken() async {
  return await storage.read(key: "access_token");
}
