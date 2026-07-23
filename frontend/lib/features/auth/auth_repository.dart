import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/api_client.dart';

class AuthRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token';

  Future<void> register(String email, String password) async {
    final response = await apiClient.dio.post(
      '/auth/register',
      data: {'email': email, 'password': password},
    );
    final token = response.data['access_token'];
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> login(String email, String password) async {
    final response = await apiClient.dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final token = response.data['access_token'];
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<bool> verifyToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;
      
      final response = await apiClient.dio.get('/auth/verify');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
