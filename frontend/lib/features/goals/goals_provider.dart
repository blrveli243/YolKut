import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'goals_repository.dart';

class GoalsState {
  final AsyncValue<List<dynamic>> goals;
  final bool isCreating;

  GoalsState({required this.goals, this.isCreating = false});

  GoalsState copyWith({AsyncValue<List<dynamic>>? goals, bool? isCreating}) {
    return GoalsState(
      goals: goals ?? this.goals,
      isCreating: isCreating ?? this.isCreating,
    );
  }
}

class GoalsNotifier extends Notifier<GoalsState> {
  @override
  GoalsState build() {
    fetchGoals();
    return GoalsState(goals: const AsyncValue.loading());
  }

  Future<void> fetchGoals() async {
    state = state.copyWith(goals: const AsyncValue.loading());
    try {
      final data = await GoalsRepository.getGoals();
      state = state.copyWith(goals: AsyncValue.data(data));
    } catch (e, st) {
      state = state.copyWith(goals: AsyncValue.error(e, st));
    }
  }

  Future<void> createGoal(Map<String, dynamic> data) async {
    state = state.copyWith(isCreating: true);
    try {
      await GoalsRepository.createGoal(data);
      await fetchGoals(); // Refresh goals after creation
    } finally {
      state = state.copyWith(isCreating: false);
    }
  }
}

final customGoalsProvider = NotifierProvider<GoalsNotifier, GoalsState>(() {
  return GoalsNotifier();
});
