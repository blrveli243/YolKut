import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';

import '../programs/programs_dashboard_screen.dart';
import '../programs/active_workout_screen.dart';
import '../nutrition/nutrition_provider.dart';
import '../tasks/tasks_provider.dart';
import 'water_provider.dart';
import '../../main_screen.dart';
import '../../core/utils/date_formatter.dart';
import 'health_provider.dart';
import '../sunbathing/sunbathing_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Verileri dinle
    final nutritionState = ref.watch(nutritionProvider);
    final tasksState = ref.watch(tasksProvider);
    final waterConsumed = ref.watch(waterProvider);
    final healthState = ref.watch(
      healthSyncProvider,
    ); // Sync with health provider

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Image.asset(
          'assets/kutyol_logo.png',
          height: 48,
          fit: BoxFit.contain,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                Icons.landscape_rounded,
                color: Theme.of(context).colorScheme.onSurface,
                size: 28,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProgramsDashboardScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(nutritionProvider.notifier).fetchSummary(DateTime.now()),
            ref.read(tasksProvider.notifier).fetchTasksForDate(DateTime.now()),
            ref.read(healthSyncProvider.notifier).syncData(),
          ]);
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                    child: Text(
                      DateFormatter.toTurkishDate(DateTime.now()),
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      '"Küçük adımlar, büyük hedeflere götürür."',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                _buildRingsSection(nutritionState, waterConsumed, context, ref),

                const SizedBox(height: 16),

                _buildWaterTracker(waterConsumed, ref, context),

                const SizedBox(height: 24),

                _buildWorkoutProgress(context),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _buildCTAButton(
                        context,
                        ref,
                        'Antrenman',
                        Icons.fitness_center,
                        AppColors.warning,
                        2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCTAButton(
                        context,
                        ref,
                        'Öğün',
                        Icons.restaurant_menu,
                        AppColors.info,
                        1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRouteButton(
                        context,
                        'Güneşlenme',
                        Icons.wb_sunny_rounded,
                        AppColors.warning,
                        const SunbathingScreen(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _buildTaskStats(tasksState, context),

                const SizedBox(height: 16),
                _buildDailyTasksTitle(context),
                const SizedBox(height: 16),
                _buildDailyTasks(tasksState, ref, context),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRingsSection(
    NutritionState state,
    int waterConsumed,
    BuildContext context,
    WidgetRef ref,
  ) {
    double caloriesProgress = 0.0;
    double proteinProgress = 0.0;
    double waterProgress = waterConsumed / 3000.0;

    const colorCalorie = AppColors.info;
    const colorProtein = AppColors.primary;
    const colorWater = AppColors.water;

    return state.summary.when(
      loading: () => SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: colorCalorie)),
      ),
      error: (_, __) => SizedBox(
        height: 200,
        child: Center(
          child: Text(
            "Hata",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ),
      data: (summary) {
        final consumed = (summary['consumedCalories'] ?? 0).toDouble();
        final tdee = (summary['tdee'] ?? 2000).toDouble();
        final bmr = (summary['bmr'] ?? 2000).toDouble();
        final targetCalories = (summary['targetCalories'] ?? tdee).toDouble();

        final healthState = ref.read(healthSyncProvider);
        final active = healthState.activeCalories;
        final expectedActive = tdee > bmr ? tdee - bmr : 0.0;
        final extraActive = active > expectedActive
            ? active - expectedActive
            : 0.0;

        final adjustedTarget = targetCalories + extraActive;
        caloriesProgress = adjustedTarget > 0 ? consumed / adjustedTarget : 0.0;

        final protein = (summary['macros']?['protein'] ?? 0).toDouble();
        final targetProtein = (summary['targets']?['protein'] ?? 100)
            .toDouble();
        proteinProgress = targetProtein > 0 ? protein / targetProtein : 0.0;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor, width: 1),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: CircularProgressIndicator(
                        value: min(caloriesProgress, 1.0),
                        strokeWidth: 12,
                        backgroundColor: colorCalorie.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          colorCalorie,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CircularProgressIndicator(
                        value: min(proteinProgress, 1.0),
                        strokeWidth: 12,
                        backgroundColor: colorProtein.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          colorProtein,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: min(waterProgress, 1.0),
                        strokeWidth: 12,
                        backgroundColor: colorWater.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          colorWater,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildRingLegend(
                      'Kalori',
                      '${consumed.round()}/${adjustedTarget.round()}',
                      colorCalorie,
                      context,
                    ),
                    const SizedBox(height: 12),
                    _buildRingLegend(
                      'Protein',
                      '${protein.round()}g/${targetProtein.round()}g',
                      colorProtein,
                      context,
                    ),
                    const SizedBox(height: 12),
                    _buildRingLegend(
                      'Su',
                      '${(waterConsumed / 1000).toStringAsFixed(1)}L/3L',
                      colorWater,
                      context,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRingLegend(
    String title,
    String value,
    Color color,
    BuildContext context,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWaterTracker(int consumed, WidgetRef ref, BuildContext context) {
    const colorWater = AppColors.water;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Su Tüketimi',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$consumed / 3000 ml',
                style: const TextStyle(
                  color: colorWater,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWaterButton(
                Icons.remove,
                () => ref.read(waterProvider.notifier).removeWater(),
                colorWater,
              ),
              Icon(
                Icons.local_drink_rounded,
                color: colorWater.withValues(alpha: 0.8),
                size: 36,
              ),
              _buildWaterButton(
                Icons.add,
                () => ref.read(waterProvider.notifier).addWater(),
                colorWater,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaterButton(IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildWorkoutProgress(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Haftalık Antrenman',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                '3 / 5 Gün',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 3 / 5,
              minHeight: 6,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStats(TasksState state, BuildContext context) {
    return state.stats.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (stats) {
        final double dailyRate = (stats['dailyRate'] ?? 0).toDouble();
        final double overallRate = (stats['overallRate'] ?? 0).toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCircularGraph(
                'Günlük Başarı',
                dailyRate,
                AppColors.primary,
                context,
              ),
              _buildCircularGraph(
                'Genel Başarı',
                overallRate,
                AppColors.info,
                context,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCircularGraph(
    String title,
    double rate,
    Color color,
    BuildContext context,
  ) {
    return Column(
      children: [
        SizedBox(
          width: 90,
          height: 90,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: rate / 100,
                strokeWidth: 10,
                backgroundColor: Theme.of(
                  context,
                ).dividerColor.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeCap: StrokeCap.round,
              ),
              Center(
                child: Text(
                  '${rate.round()}%',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTasksTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        'Günlük Planım',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCTAButton(
    BuildContext context,
    WidgetRef ref,
    String text,
    IconData icon,
    Color color,
    int tabIndex,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(mainTabIndexProvider.notifier).setIndex(tabIndex);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    Widget destination,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              text,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyTasks(
    TasksState state,
    WidgetRef ref,
    BuildContext context,
  ) {
    return state.tasks.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.info)),
      error: (_, __) => Center(
        child: Text(
          'Görevler yüklenemedi',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Bugün için harika bir gün! Yeni görev ekle.',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          );
        }

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final selectedDay = DateTime(
          state.selectedDate.year,
          state.selectedDate.month,
          state.selectedDate.day,
        );
        final isPastDate = selectedDay.isBefore(today);

        final displayTasks = tasks.take(4).toList();

        return Column(
          children: displayTasks.asMap().entries.map((entry) {
            final int index = entry.key;
            final task = entry.value;
            final isCompleted = task['isCompleted'] ?? false;
            final isLast = index == displayTasks.length - 1;

            return IntrinsicHeight(
              child: Opacity(
                opacity: isPastDate && !isCompleted ? 0.6 : 1.0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Beyaz Yol (Roadmap Line)
                    SizedBox(
                      width: 40,
                      child: Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(top: 16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? AppColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: isCompleted
                                    ? AppColors.primary
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: isCompleted
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.2),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Task Card
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12, top: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          onTap: () {
                            if (isPastDate) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Geçmişteki görevler değiştirilemez.',
                                  ),
                                ),
                              );
                              return;
                            }
                            if (task['isWorkout'] == true && !isCompleted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ActiveWorkoutScreen(
                                    date: state.selectedDate,
                                  ),
                                ),
                              );
                            } else if (task['isWorkout'] != true) {
                              ref
                                  .read(tasksProvider.notifier)
                                  .toggleTaskCompletion(
                                    task['id'],
                                    isCompleted,
                                  );
                            }
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          title: Row(
                            children: [
                              if (task['isWorkout'] == true)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8.0),
                                  child: Icon(
                                    Icons.fitness_center,
                                    size: 18,
                                    color: AppColors.info,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  task['title'],
                                  style: TextStyle(
                                    color: isCompleted
                                        ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.5)
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                    fontWeight: task['isWorkout'] == true
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (task['isWorkout'] == true && !isCompleted)
                                const Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
