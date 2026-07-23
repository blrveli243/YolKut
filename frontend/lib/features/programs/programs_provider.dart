import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'programs_repository.dart';
import '../../core/data/exercises_db.dart';

final programsRepositoryProvider = Provider((ref) => ProgramsRepository());

class ScheduledExercise {
  final int id;
  final int weekday; // 1 = Monday, ..., 7 = Sunday
  final String exerciseId;
  final int targetSets;
  final int targetReps;

  ScheduledExercise({
    required this.id,
    required this.weekday,
    required this.exerciseId,
    required this.targetSets,
    required this.targetReps,
  });
}

class ProgramsState {
  final AsyncValue<List<ScheduledExercise>> scheduled;
  final AsyncValue<List<Exercise>> customExercises;

  ProgramsState({required this.scheduled, required this.customExercises});

  ProgramsState copyWith({
    AsyncValue<List<ScheduledExercise>>? scheduled,
    AsyncValue<List<Exercise>>? customExercises,
  }) {
    return ProgramsState(
      scheduled: scheduled ?? this.scheduled,
      customExercises: customExercises ?? this.customExercises,
    );
  }
}

class ProgramsNotifier extends Notifier<ProgramsState> {
  @override
  ProgramsState build() {
    Future.microtask(() => _fetchData());
    return ProgramsState(
      scheduled: const AsyncValue.loading(),
      customExercises: const AsyncValue.loading(),
    );
  }

  Future<void> _fetchData() async {
    state = state.copyWith(
      scheduled: const AsyncValue.loading(),
      customExercises: const AsyncValue.loading(),
    );
    try {
      final repo = ref.read(programsRepositoryProvider);

      final customFuture = repo.getCustomExercises();
      final scheduledFuture = repo.getScheduledExercises();

      final results = await Future.wait([customFuture, scheduledFuture]);
      final customData = results[0];
      final scheduledData = results[1];

      final customExercisesList = customData.map((e) {
        return Exercise(
          id: 'custom_${e['id']}', // prepend custom_ to avoid clashes
          name: e['name'],
          category: e['category'],
          icon: ExercisesDB.getIconForCategory(e['category']),
        );
      }).toList();

      final scheduledList = scheduledData.map((e) {
        return ScheduledExercise(
          id: e['id'],
          weekday: e['weekday'],
          exerciseId: e['exerciseId'],
          targetSets: e['targetSets'],
          targetReps: e['targetReps'],
        );
      }).toList();

      state = state.copyWith(
        customExercises: AsyncValue.data(customExercisesList),
        scheduled: AsyncValue.data(scheduledList),
      );
    } catch (e, stack) {
      state = state.copyWith(
        customExercises: AsyncValue.error(e, stack),
        scheduled: AsyncValue.error(e, stack),
      );
    }
  }

  Future<void> addExercise(
    int weekday,
    String exerciseId,
    int targetSets,
    int targetReps,
  ) async {
    try {
      final repo = ref.read(programsRepositoryProvider);
      await repo.addScheduledExercise(
        weekday,
        exerciseId,
        targetSets,
        targetReps,
      );
      await _fetchData();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeExercise(int id) async {
    try {
      final repo = ref.read(programsRepositoryProvider);
      await repo.removeScheduledExercise(id);
      await _fetchData();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createCustomExercise(String name, String category) async {
    try {
      final repo = ref.read(programsRepositoryProvider);
      await repo.createCustomExercise(name, category);
      await _fetchData();
    } catch (e) {
      rethrow;
    }
  }
}

final programsProvider = NotifierProvider<ProgramsNotifier, ProgramsState>(() {
  return ProgramsNotifier();
});
