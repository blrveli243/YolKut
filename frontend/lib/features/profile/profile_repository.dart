import 'package:dio/dio.dart';
import '../../core/api_client.dart';

class ProfileRepository {
  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await apiClient.dio.get('/users/me');
    return response.data;
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await apiClient.dio.patch('/users/me', data: data);
  }

  Future<void> uploadProfilePhoto(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    await apiClient.dio.post('/users/me/photo', data: formData);
  }
}
