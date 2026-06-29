import 'package:health/health.dart';

class HealthRepository {
  final Health _health = Health();

  Future<bool> requestPermissions() async {
    final types = [
      HealthDataType.STEPS,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.BASAL_ENERGY_BURNED,
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.WORKOUT,
      HealthDataType.HEART_RATE,
    ];

    final permissions = types.map((e) => HealthDataAccess.READ).toList();

    bool requested = await _health.requestAuthorization(types, permissions: permissions);
    return requested;
  }

  Future<Map<String, dynamic>> fetchHealthData() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Daily Steps (Today)
    int? todaySteps = await _health.getTotalStepsInInterval(midnight, now);

    // Active Calories (Today)
    List<HealthDataPoint> activeEnergy = await _health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: midnight,
        endTime: now);

    double totalActiveEnergy = 0;
    for (var p in activeEnergy) {
      if (p.value is NumericHealthValue) {
        totalActiveEnergy += (p.value as NumericHealthValue).numericValue.toDouble();
      }
    }

    // Historical Steps (Last 30 Days)
    List<Map<String, dynamic>> historicalSteps = [];
    for (int i = 0; i < 30; i++) {
      final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final end = start.add(const Duration(days: 1));
      // For today, end is now, but interval doesn't matter much if we use end of day
      final dailySteps = await _health.getTotalStepsInInterval(start, i == 0 ? now : end);
      
      historicalSteps.add({
        'date': "${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}",
        'steps': dailySteps ?? 0,
      });
    }

    // Workouts (Last 30 Days)
    List<HealthDataPoint> workoutData = await _health.getHealthDataFromTypes(
        types: [HealthDataType.WORKOUT],
        startTime: thirtyDaysAgo,
        endTime: now);

    List<Map<String, dynamic>> workouts = [];
    for (var p in workoutData) {
      if (p.value is WorkoutHealthValue) {
        final wv = p.value as WorkoutHealthValue;
        
        String activityType = wv.workoutActivityType.toString().split('.').last;
        // Translate some common ones to Turkish
        if (activityType == 'SWIMMING') activityType = 'Yüzme';
        else if (activityType == 'RUNNING') activityType = 'Koşu';
        else if (activityType == 'CYCLING') activityType = 'Bisiklet';
        else if (activityType == 'WALKING') activityType = 'Yürüyüş';
        else if (activityType == 'TRADITIONAL_STRENGTH_TRAINING') activityType = 'Ağırlık Antrenmanı';

        final durationMins = p.dateTo.difference(p.dateFrom).inMinutes;
        final burnedCals = wv.totalEnergyBurned ?? 0;

        workouts.add({
          'id': p.uuid, // Use uuid if provided, else rely on date
          'type': activityType,
          'durationMinutes': durationMins,
          'caloriesBurned': burnedCals,
          'date': p.dateFrom.toIso8601String(),
        });
      }
    }

    // Sort workouts by date descending
    workouts.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

    return {
      'steps': todaySteps ?? 0,
      'activeCalories': totalActiveEnergy,
      'historicalSteps': historicalSteps,
      'workouts': workouts,
      'date': now.toIso8601String(),
    };
  }

  Future<int?> fetchLatestHeartRate() async {
    final now = DateTime.now();
    // Son 15 dakikanın nabız verilerini getir (Apple Watch genelde sık günceller)
    final startTime = now.subtract(const Duration(minutes: 15));
    
    try {
      List<HealthDataPoint> hrData = await _health.getHealthDataFromTypes(
          types: [HealthDataType.HEART_RATE],
          startTime: startTime,
          endTime: now);
          
      if (hrData.isNotEmpty) {
        // En güncel olanı almak için tarihe göre sırala
        hrData.sort((a, b) => b.dateTo.compareTo(a.dateTo));
        final latest = hrData.first;
        if (latest.value is NumericHealthValue) {
          return (latest.value as NumericHealthValue).numericValue.toInt();
        }
      }
    } catch (e) {
      print("Heart rate fetch error: $e");
    }
    return null;
  }
}
