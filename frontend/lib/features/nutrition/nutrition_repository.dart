import '../../core/api_client.dart';

class NutritionRepository {
  Future<Map<String, dynamic>> fetchDailySummary(String date) async {
    final response = await apiClient.dio.get('/nutrition/daily-summary?date=$date');
    return response.data;
  }

  Future<List<dynamic>> searchFood(String query) async {
    final response = await apiClient.dio.get('/nutrition/search-food?q=$query');
    return response.data as List<dynamic>;
  }

  Future<void> addFood(Map<String, dynamic> data) async {
    await apiClient.dio.post('/nutrition/food', data: data);
  }

  Future<void> createCustomFood(Map<String, dynamic> data) async {
    await apiClient.dio.post('/nutrition/custom-food', data: data);
  }
}
