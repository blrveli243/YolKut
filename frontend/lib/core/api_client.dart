import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  late final Dio dio;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        // Fiziksel telefon bağlantısı için Mac'inizin yerel IP adresi kullanıldı
        baseUrl: 'http://192.168.85.159:3001',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = await _storage
                .read(key: 'jwt_token')
                .timeout(const Duration(seconds: 3));
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (e) {
            // Ignore timeout or storage errors, just send without token or let it fail downstream
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await _storage.delete(key: 'jwt_token');
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> postHealthData(Map<String, dynamic> data) async {
    try {
      await dio.post('/health-data', data: data);
    } catch (e) {
      rethrow;
    }
  }
}

final apiClient = ApiClient();
