import '../../core/api_client.dart';

class GoalsRepository {
  static Future<List<dynamic>> getGoals() async {
    final response = await apiClient.dio.get('/goals');
    return response.data;
  }

  static Future<dynamic> createGoal(Map<String, dynamic> goalData) async {
    final response = await apiClient.dio.post('/goals', data: goalData);
    return response.data;
  }
}
