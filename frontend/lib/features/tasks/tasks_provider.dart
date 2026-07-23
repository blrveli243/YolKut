import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/date_formatter.dart';
import '../programs/programs_provider.dart';
import '../programs/workout_logs_provider.dart';
import 'task_repository.dart';

final taskRepositoryProvider = Provider((ref) => TaskRepository());

class TasksState {
  final DateTime selectedDate;
  final AsyncValue<List<dynamic>> tasks;
  final AsyncValue<Map<String, dynamic>> stats;

  TasksState({
    required this.selectedDate,
    required this.tasks,
    required this.stats,
  });

  TasksState copyWith({
    DateTime? selectedDate,
    AsyncValue<List<dynamic>>? tasks,
    AsyncValue<Map<String, dynamic>>? stats,
  }) {
    return TasksState(
      selectedDate: selectedDate ?? this.selectedDate,
      tasks: tasks ?? this.tasks,
      stats: stats ?? this.stats,
    );
  }
}

class TasksNotifier extends Notifier<TasksState> {
  @override
  TasksState build() {
    final today = DateTime.now();
    // Fetch initially for today
    Future.microtask(() => fetchTasksForDate(today));
    return TasksState(
      selectedDate: today,
      tasks: const AsyncValue.loading(),
      stats: const AsyncValue.loading(),
    );
  }

  String _formatDate(DateTime date) => DateFormatter.toApiDate(date);

  Future<void> fetchTasksForDate(DateTime date) async {
    state = state.copyWith(
      selectedDate: date,
      tasks: const AsyncValue.loading(),
      stats: const AsyncValue.loading(),
    );
    try {
      final repo = ref.read(taskRepositoryProvider);

      final statsFuture = repo.fetchTaskStats(_formatDate(date));
      final tasksFuture = repo.fetchTasks(_formatDate(date));

      final results = await Future.wait([statsFuture, tasksFuture]);
      final stats = results[0] as Map<String, dynamic>;
      final tasks = results[1] as List<dynamic>;

      final programsState = ref.read(programsProvider);
      final scheduledList = programsState.scheduled.value ?? [];
      final hasWorkout = scheduledList.any((e) => e.weekday == date.weekday);

      if (hasWorkout) {
        final isCompleted = ref
            .read(workoutLogsProvider.notifier)
            .isWorkoutCompletedToday(_formatDate(date));
        // Create a synthetic task map
        tasks.insert(0, {
          'id': 'workout_${_formatDate(date)}',
          'title': 'Günün Spor Programı',
          'isCompleted': isCompleted,
          'isWorkout': true,
        });

        // Dynamically update stats based on synthetic workout task
        final dailyTotal =
            (stats['dailyTotal'] as num?)?.toInt() ?? tasks.length;
        final dailyCompleted =
            (stats['dailyCompleted'] as num?)?.toInt() ??
            tasks.where((t) => t['isCompleted'] == true).length;
        final newDailyRate = dailyTotal > 0
            ? (dailyCompleted / dailyTotal) * 100
            : 0.0;
        stats['dailyRate'] = newDailyRate;
      }

      state = state.copyWith(
        tasks: AsyncValue.data(tasks),
        stats: AsyncValue.data(stats),
      );
    } catch (e, stack) {
      state = state.copyWith(
        tasks: AsyncValue.error(e, stack),
        stats: AsyncValue.error(e, stack),
      );
    }
  }

  Future<void> changeDate(DateTime date) async {
    if (state.selectedDate.year == date.year &&
        state.selectedDate.month == date.month &&
        state.selectedDate.day == date.day) {
      return;
    }
    await fetchTasksForDate(date);
  }

  Future<void> createTask(
    String title, {
    DateTime? scheduledTime,
    String? location,
    int reminderOffsetMinutes = 15,
  }) async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      final newTask = await repo.createTask(
        title,
        _formatDate(state.selectedDate),
        scheduledTime: scheduledTime?.toIso8601String(),
        location: location,
      );

      if (scheduledTime != null && newTask['id'] != null) {
        await NotificationService().scheduleTaskReminder(
          id: newTask['id'],
          title: 'Hatırlatma: $title',
          body: 'Planladığınız görev saati yaklaşıyor. Hazır mısınız?',
          scheduledTime: scheduledTime,
          minutesBefore: reminderOffsetMinutes,
        );
      }

      await fetchTasksForDate(state.selectedDate);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleTaskCompletion(int id, bool currentStatus) async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.updateTask(id, {'isCompleted': !currentStatus});
      await fetchTasksForDate(state.selectedDate);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rescheduleTask(int id, DateTime newDate) async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.updateTask(id, {'date': newDate.toIso8601String()});
      await fetchTasksForDate(state.selectedDate);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      await repo.deleteTask(id);
      await NotificationService().cancelReminder(id);
      await fetchTasksForDate(state.selectedDate);
    } catch (e) {
      rethrow;
    }
  }
}

final tasksProvider = NotifierProvider<TasksNotifier, TasksState>(() {
  return TasksNotifier();
});
