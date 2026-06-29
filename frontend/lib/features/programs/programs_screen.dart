import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/exercises_db.dart';
import 'programs_provider.dart';
import 'select_exercise_screen.dart';

class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  int _selectedWeekday = 1; // 1: Pazartesi ... 7: Pazar

  final List<String> _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    final programsState = ref.watch(programsProvider);
    final scheduledExercises = (programsState.scheduled.value ?? [])
        .where((e) => e.weekday == _selectedWeekday)
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Programlarım', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: Column(
        children: [
          // Weekly Calendar
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, index) {
                final weekday = index + 1;
                final isSelected = _selectedWeekday == weekday;
                return GestureDetector(
                  onTap: () => setState(() => _selectedWeekday = weekday),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF0A84FF) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isSelected ? Colors.transparent : Theme.of(context).dividerColor),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _days[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Exercises List
          Expanded(
            child: scheduledExercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text('Bu güne ait bir program yok', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: scheduledExercises.length,
                    itemBuilder: (context, index) {
                      final item = scheduledExercises[index];
                      final exercise = ExercisesDB.getById(item.exerciseId);
                      if (exercise == null) return const SizedBox.shrink();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A84FF).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(exercise.icon, color: const Color(0xFF0A84FF)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(exercise.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(exercise.category, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${item.targetSets} Set', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
                                Text('${item.targetReps} Tekrar', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                ref.read(programsProvider.notifier).removeExercise(item.id);
                              },
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => SelectExerciseScreen(weekday: _selectedWeekday),
          ));
        },
        backgroundColor: const Color(0xFF0A84FF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Hareket Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
