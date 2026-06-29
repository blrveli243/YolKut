import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'nutrition_repository.dart';

final nutritionRepositoryProvider = Provider((ref) => NutritionRepository());

class NutritionState {
  final DateTime selectedDate;
  final AsyncValue<Map<String, dynamic>> summary;

  NutritionState({required this.selectedDate, required this.summary});

  NutritionState copyWith({DateTime? selectedDate, AsyncValue<Map<String, dynamic>>? summary}) {
    return NutritionState(
      selectedDate: selectedDate ?? this.selectedDate,
      summary: summary ?? this.summary,
    );
  }
}

class NutritionNotifier extends Notifier<NutritionState> {
  @override
  NutritionState build() {
    final today = DateTime.now();
    Future.microtask(() => fetchSummary(today));
    return NutritionState(selectedDate: today, summary: const AsyncValue.loading());
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> fetchSummary(DateTime date) async {
    state = state.copyWith(selectedDate: date, summary: const AsyncValue<Map<String, dynamic>>.loading());
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      final summary = await repo.fetchDailySummary(_formatDate(date));
      state = state.copyWith(summary: AsyncValue.data(summary));
    } catch (e, stack) {
      state = state.copyWith(summary: AsyncValue<Map<String, dynamic>>.error(e, stack));
    }
  }

  Future<void> changeDate(DateTime date) async {
    if (state.selectedDate.year == date.year && 
        state.selectedDate.month == date.month && 
        state.selectedDate.day == date.day) {
      return;
    }
    await fetchSummary(date);
  }

  Future<void> addFood(Map<String, dynamic> foodData) async {
    try {
      final repo = ref.read(nutritionRepositoryProvider);
      foodData['date'] = _formatDate(state.selectedDate);
      await repo.addFood(foodData);
      await fetchSummary(state.selectedDate);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> searchFood(String query) async {
    final repo = ref.read(nutritionRepositoryProvider);
    return await repo.searchFood(query);
  }

  Future<void> createCustomFood(Map<String, dynamic> data) async {
    final repo = ref.read(nutritionRepositoryProvider);
    await repo.createCustomFood(data);
  }
}

final nutritionProvider = NotifierProvider<NutritionNotifier, NutritionState>(() {
  return NutritionNotifier();
});
