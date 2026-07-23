import '../../core/theme/app_colors.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/exercises_db.dart';
import '../tasks/tasks_provider.dart';
import 'programs_provider.dart';
import 'workout_logs_provider.dart';
import '../health/health_repository.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final DateTime date;

  const ActiveWorkoutScreen({super.key, required this.date});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen>
    with SingleTickerProviderStateMixin {
  // Map representation: { "scheduledExerciseId": [ { "set": 1, "reps": 10, "kg": 50.0 }, ... ] }
  final Map<String, List<Map<String, dynamic>>> _workoutData = {};

  bool _isStarted = false;
  int _secondsElapsed = 0;
  Timer? _timer;

  int _currentBpm = 0; // 0 means fetching or unavailable
  String _motivationMessage = "Hazırlan, harika bir antrenman seni bekliyor!";

  late AnimationController _heartbeatController;
  late Animation<double> _heartbeatAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize data structure
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scheduledWorkouts =
          (ref.read(programsProvider).scheduled.value ?? [])
              .where((e) => e.weekday == widget.date.weekday)
              .toList();
      for (var exercise in scheduledWorkouts) {
        _workoutData[exercise.id.toString()] = List.generate(
          exercise.targetSets,
          (index) => {'set': index + 1, 'reps': exercise.targetReps, 'kg': 0.0},
        );
      }
      setState(() {});
    });

    // Heartbeat animation setup
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heartbeatAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _heartbeatController.dispose();
    super.dispose();
  }

  void _startWorkout() async {
    setState(() {
      _isStarted = true;
      _currentBpm = 0;
      _motivationMessage = "Saatinizden nabız verisi bekleniyor...";
    });

    _heartbeatController.repeat(reverse: true);

    // Request permission once at the start
    final repo = HealthRepository();
    await repo.requestPermissions();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() {
        _secondsElapsed++;
      });

      // Fetch real heart rate every 5 seconds
      if (_secondsElapsed % 5 == 0 || _secondsElapsed == 1) {
        final hr = await repo.fetchLatestHeartRate();

        if (hr != null && mounted) {
          setState(() {
            _currentBpm = hr;

            if (_currentBpm > 135) {
              _motivationMessage =
                  "Yağ yakım bölgesindesin! Süper gidiyorsun. 🔥";
            } else if (_currentBpm > 100) {
              _motivationMessage = "Nabzın harika. Odaklan ve kaldır! 💪";
            } else if (_currentBpm > 0) {
              _motivationMessage = "Haydi tempoyu biraz artıralım. 🚀";
            }

            // Adjust heartbeat speed based on BPM
            int durationMs = (60000 / (_currentBpm > 0 ? _currentBpm : 60))
                .round();
            if (durationMs > 1000) durationMs = 1000;
            if (durationMs < 300) durationMs = 300;

            _heartbeatController.duration = Duration(milliseconds: durationMs);
            if (_heartbeatController.isAnimating) {
              _heartbeatController.repeat(reverse: true);
            }
          });
        }
      }
    });
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _finishWorkout() {
    _timer?.cancel();
    _heartbeatController.stop();

    final scheduledWorkouts = (ref.read(programsProvider).scheduled.value ?? [])
        .where((e) => e.weekday == widget.date.weekday)
        .toList();
    List<WorkoutExerciseLog> logs = [];

    for (var scheduled in scheduledWorkouts) {
      final setsData = _workoutData[scheduled.id.toString()] ?? [];
      final setsLogs = setsData
          .map(
            (s) => WorkoutSetLog(
              setIndex: s['set'],
              actualReps: s['reps'],
              weightKg: s['kg'],
            ),
          )
          .toList();

      logs.add(
        WorkoutExerciseLog(
          scheduledExerciseId: scheduled.id.toString(),
          exerciseId: scheduled.exerciseId,
          sets: setsLogs,
        ),
      );
    }

    final dateStr =
        '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}';
    ref.read(workoutLogsProvider.notifier).saveWorkoutLog(dateStr, logs);

    // Refresh tasks to show completed status
    ref.read(tasksProvider.notifier).fetchTasksForDate(widget.date);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tebrikler! $_formatTime dakika boyunca antrenman yaptınız. 💪',
        ),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduledWorkouts =
        (ref.watch(programsProvider).scheduled.value ?? [])
            .where((e) => e.weekday == widget.date.weekday)
            .toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Günün Antrenmanı',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        body: scheduledWorkouts.isEmpty
            ? Center(
                child: Text(
                  'Bugün için planlanmış antrenman yok.',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              )
            : !_isStarted
            ? _buildStartScreen(context)
            : _buildActiveWorkoutScreen(context, scheduledWorkouts),
        bottomNavigationBar: (scheduledWorkouts.isEmpty || !_isStarted)
            ? null
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _finishWorkout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Antrenmanı Bitir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStartScreen(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fitness_center,
                size: 80,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Hazır mısın?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ağırlıkları ayarla, suyunu yanına al ve kronometreyi başlat!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _startWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  shadowColor: AppColors.info.withOpacity(0.5),
                ),
                child: const Text(
                  'Antrenmanı Başlat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveWorkoutScreen(
    BuildContext context,
    List<ScheduledExercise> scheduledWorkouts,
  ) {
    return Column(
      children: [
        // Timer and Heart Rate Header
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SÜRE',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(_secondsElapsed),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Theme.of(context).dividerColor,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'NABIZ (BPM)',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          ScaleTransition(
                            scale: _heartbeatAnimation,
                            child: const Icon(
                              Icons.favorite,
                              color: AppColors.error,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _currentBpm > 0 ? '$_currentBpm' : '--',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _motivationMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Exercise List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scheduledWorkouts.length,
            itemBuilder: (context, index) {
              final scheduled = scheduledWorkouts[index];
              final exercise = ExercisesDB.getById(scheduled.exerciseId);
              final setsData = _workoutData[scheduled.id.toString()] ?? [];

              if (exercise == null) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(exercise.icon, color: AppColors.info, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          exercise.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Sets Builder
                    ...setsData.asMap().entries.map((entry) {
                      int setIndex = entry.key;
                      var setData = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${setIndex + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: setData['reps'].toString(),
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: 'Tekrar',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onChanged: (val) {
                                  setData['reps'] = int.tryParse(val) ?? 0;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: setData['kg'].toString(),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: 'Kg',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                onChanged: (val) {
                                  setData['kg'] = double.tryParse(val) ?? 0.0;
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
