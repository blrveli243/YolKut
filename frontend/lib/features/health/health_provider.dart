import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'health_repository.dart';
import '../../core/api_client.dart';

class HealthState {
  final bool isLoading;
  final bool hasError;
  final int steps;
  final double activeCalories;
  final List<Map<String, dynamic>> historicalSteps;
  final List<Map<String, dynamic>> allWorkouts;

  HealthState({
    this.isLoading = false,
    this.hasError = false,
    this.steps = 0,
    this.activeCalories = 0.0,
    this.historicalSteps = const [],
    this.allWorkouts = const [],
  });

  HealthState copyWith({
    bool? isLoading,
    bool? hasError,
    int? steps,
    double? activeCalories,
    List<Map<String, dynamic>>? historicalSteps,
    List<Map<String, dynamic>>? allWorkouts,
  }) {
    return HealthState(
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      steps: steps ?? this.steps,
      activeCalories: activeCalories ?? this.activeCalories,
      historicalSteps: historicalSteps ?? this.historicalSteps,
      allWorkouts: allWorkouts ?? this.allWorkouts,
    );
  }
}

class HealthSyncNotifier extends Notifier<HealthState> {
  @override
  HealthState build() {
    return HealthState();
  }

  Future<void> syncData() async {
    state = state.copyWith(isLoading: true, hasError: false);
    try {
      final repository = ref.read(healthRepositoryProvider);

      final hasPermissions = await repository.requestPermissions();
      if (!hasPermissions) {
        state = state.copyWith(isLoading: false, hasError: true);
        return;
      }

      final data = await repository.fetchHealthData();

      try {
        await apiClient.postHealthData(data);
      } catch (e) {
        debugPrint('Backend sync error (ignored for UI): $e');
      }

      state = state.copyWith(
        isLoading: false,
        hasError: false,
        steps: data['steps'] ?? 0,
        activeCalories: data['activeCalories'] ?? 0.0,
        historicalSteps: List<Map<String, dynamic>>.from(
          data['historicalSteps'] ?? [],
        ),
        allWorkouts: List<Map<String, dynamic>>.from(data['workouts'] ?? []),
      );
    } catch (e) {
      debugPrint('Health Sync Error: $e');
      state = state.copyWith(isLoading: false, hasError: true);
    }
  }
}

final healthRepositoryProvider = Provider((ref) => HealthRepository());
final healthSyncProvider = NotifierProvider<HealthSyncNotifier, HealthState>(
  () {
    return HealthSyncNotifier();
  },
);
