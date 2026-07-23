import '../../core/api_client.dart';

class ProgramsRepository {
  // --- Custom Exercises ---
  Future<List<dynamic>> getCustomExercises() async {
    final response = await apiClient.dio.get('/programs/custom-exercises');
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Özel hareketler yüklenemedi');
    }
  }

  Future<Map<String, dynamic>> createCustomExercise(
    String name,
    String category,
  ) async {
    final response = await apiClient.dio.post(
      '/programs/custom-exercises',
      data: {'name': name, 'category': category},
    );

    if (response.statusCode == 201) {
      return response.data;
    } else {
      throw Exception('Özel hareket oluşturulamadı');
    }
  }

  // --- Scheduled Exercises ---
  Future<List<dynamic>> getScheduledExercises() async {
    final response = await apiClient.dio.get('/programs/scheduled');
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Program yüklenemedi');
    }
  }

  Future<Map<String, dynamic>> addScheduledExercise(
    int weekday,
    String exerciseId,
    int targetSets,
    int targetReps,
  ) async {
    final response = await apiClient.dio.post(
      '/programs/scheduled',
      data: {
        'weekday': weekday,
        'exerciseId': exerciseId,
        'targetSets': targetSets,
        'targetReps': targetReps,
      },
    );

    if (response.statusCode == 201) {
      return response.data;
    } else {
      throw Exception('Programa hareket eklenemedi');
    }
  }

  Future<void> removeScheduledExercise(int id) async {
    final response = await apiClient.dio.delete('/programs/scheduled/$id');
    if (response.statusCode != 200) {
      throw Exception('Hareket programdan silinemedi');
    }
  }
}
