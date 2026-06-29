import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkoutSetLog {
  final int setIndex;
  final int actualReps;
  final double weightKg;

  WorkoutSetLog({required this.setIndex, required this.actualReps, required this.weightKg});
}

class WorkoutExerciseLog {
  final String scheduledExerciseId;
  final String exerciseId;
  final List<WorkoutSetLog> sets;

  WorkoutExerciseLog({required this.scheduledExerciseId, required this.exerciseId, required this.sets});
}

class DailyWorkoutLog {
  final String id;
  final String date; // YYYY-MM-DD
  final List<WorkoutExerciseLog> exercises;

  DailyWorkoutLog({required this.id, required this.date, required this.exercises});
}

class WorkoutLogsNotifier extends Notifier<List<DailyWorkoutLog>> {
  @override
  List<DailyWorkoutLog> build() {
    return [];
  }

  void saveWorkoutLog(String date, List<WorkoutExerciseLog> exercises) {
    final newLog = DailyWorkoutLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: date,
      exercises: exercises,
    );
    // Overwrite if same date exists, or append
    state = [
      ...state.where((l) => l.date != date),
      newLog
    ];
  }
  
  bool isWorkoutCompletedToday(String date) {
    return state.any((l) => l.date == date);
  }
}

final workoutLogsProvider = NotifierProvider<WorkoutLogsNotifier, List<DailyWorkoutLog>>(() {
  return WorkoutLogsNotifier();
});
