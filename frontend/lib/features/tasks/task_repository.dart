import '../../core/api_client.dart';

class TaskRepository {
  Future<List<dynamic>> fetchTasks(String date) async {
    final response = await apiClient.dio.get('/tasks?date=$date');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchTaskStats(String date) async {
    final response = await apiClient.dio.get('/tasks/stats?date=$date');
    return response.data;
  }

  Future<Map<String, dynamic>> createTask(
    String title,
    String date, {
    String? scheduledTime,
    String? location,
  }) async {
    final response = await apiClient.dio.post(
      '/tasks',
      data: {
        'title': title,
        'date': date,
        'scheduledTime': ?scheduledTime,
        'location': ?location,
      },
    );
    return response.data;
  }

  Future<void> updateTask(int id, Map<String, dynamic> data) async {
    await apiClient.dio.patch('/tasks/$id', data: data);
  }

  Future<void> deleteTask(int id) async {
    await apiClient.dio.delete('/tasks/$id');
  }
}
