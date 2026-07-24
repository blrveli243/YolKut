import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';
import '../health/health_repository.dart';

class WorkoutTimerState {
  final int secondsElapsed;
  final bool isRunning;
  final int currentBpm;
  final String motivationMessage;

  WorkoutTimerState({
    required this.secondsElapsed,
    required this.isRunning,
    required this.currentBpm,
    required this.motivationMessage,
  });

  WorkoutTimerState copyWith({
    int? secondsElapsed,
    bool? isRunning,
    int? currentBpm,
    String? motivationMessage,
  }) {
    return WorkoutTimerState(
      secondsElapsed: secondsElapsed ?? this.secondsElapsed,
      isRunning: isRunning ?? this.isRunning,
      currentBpm: currentBpm ?? this.currentBpm,
      motivationMessage: motivationMessage ?? this.motivationMessage,
    );
  }
}

class WorkoutTimerNotifier extends Notifier<WorkoutTimerState> {
  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  final HealthRepository _healthRepo = HealthRepository();

  static const _keyStartTime = 'workout_start_time';
  static const _keyIsRunning = 'workout_is_running';
  static const _keySecondsElapsed = 'workout_seconds_elapsed';

  @override
  WorkoutTimerState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });

    _restoreState();

    return WorkoutTimerState(
      secondsElapsed: 0,
      isRunning: false,
      currentBpm: 0,
      motivationMessage: "Hazırlan, harika bir antrenman seni bekliyor!",
    );
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final isRunning = prefs.getBool(_keyIsRunning) ?? false;
    final savedSeconds = prefs.getInt(_keySecondsElapsed) ?? 0;

    if (isRunning) {
      final startTimeMs = prefs.getInt(_keyStartTime) ?? 0;
      if (startTimeMs > 0) {
        final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
        final elapsedSinceStart = DateTime.now().difference(startTime).inSeconds;
        final totalElapsed = savedSeconds + elapsedSinceStart;

        state = WorkoutTimerState(
          secondsElapsed: totalElapsed,
          isRunning: true,
          currentBpm: 0,
          motivationMessage: "Saatinizden nabız verisi bekleniyor...",
        );
        _startInternalTimer();
      }
    } else {
      state = WorkoutTimerState(
        secondsElapsed: savedSeconds,
        isRunning: false,
        currentBpm: 0,
        motivationMessage: savedSeconds > 0 
            ? "Antrenman duraklatıldı." 
            : "Hazırlan, harika bir antrenman seni bekliyor!",
      );
    }
  }

  Future<void> onAppResumed() async {
    if (!state.isRunning) return;
    final prefs = await SharedPreferences.getInstance();
    final startTimeMs = prefs.getInt(_keyStartTime) ?? 0;
    final savedSeconds = prefs.getInt(_keySecondsElapsed) ?? state.secondsElapsed;

    if (startTimeMs > 0) {
      final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
      final elapsedSinceStart = DateTime.now().difference(startTime).inSeconds;
      final totalElapsed = savedSeconds + elapsedSinceStart;

      state = state.copyWith(secondsElapsed: totalElapsed);
    }
  }

  Future<void> _persistRunningState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStartTime, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(_keySecondsElapsed, state.secondsElapsed);
    await prefs.setBool(_keyIsRunning, true);
  }

  Future<void> _persistPausedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsRunning, false);
    await prefs.setInt(_keySecondsElapsed, state.secondsElapsed);
    await prefs.remove(_keyStartTime);
  }

  Future<void> _clearPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStartTime);
    await prefs.remove(_keyIsRunning);
    await prefs.remove(_keySecondsElapsed);
  }

  Future<void> start() async {
    if (state.isRunning) return;
    
    await _healthRepo.requestPermissions();

    state = state.copyWith(
      isRunning: true, 
      motivationMessage: "Saatinizden nabız verisi bekleniyor...",
    );
    
    _persistRunningState();
    
    _notificationService.showOngoingNotification(
      id: 9996,
      title: '💪 Antrenman Devam Ediyor',
      body: 'Arka planda süreniz işliyor.',
      durationSeconds: state.secondsElapsed,
      taskType: 'workout',
      isPaused: false,
    );

    _startInternalTimer();
  }

  void pause() {
    if (!state.isRunning) return;
    _timer?.cancel();
    state = state.copyWith(
      isRunning: false,
      motivationMessage: "Antrenman duraklatıldı.",
    );
    _persistPausedState();

    _notificationService.showOngoingNotification(
      id: 9996,
      title: '⏸️ Antrenman Duraklatıldı',
      body: 'Dinlenmek iyidir. Hazır olduğunuzda devam edin.',
      durationSeconds: state.secondsElapsed,
      taskType: 'workout',
      isPaused: true,
    );
  }

  void stop() {
    _timer?.cancel();
    _notificationService.cancelOngoingNotification(9996);
    
    state = state.copyWith(
      isRunning: false,
      secondsElapsed: 0,
      currentBpm: 0,
      motivationMessage: "Hazırlan, harika bir antrenman seni bekliyor!",
    );
    _clearPersistedState();
  }

  void _startInternalTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final newElapsed = state.secondsElapsed + 1;
      
      // Every 5 seconds fetch heart rate
      if (newElapsed % 5 == 0 || newElapsed == 1) {
        final hr = await _healthRepo.fetchLatestHeartRate();
        if (hr != null) {
          String newMsg = state.motivationMessage;
          if (hr > 135) {
            newMsg = "Yağ yakım bölgesindesin! Süper gidiyorsun. 🔥";
          } else if (hr > 100) {
            newMsg = "Nabzın harika. Odaklan ve kaldır! 💪";
          } else if (hr > 0) {
            newMsg = "Haydi tempoyu biraz artıralım. 🚀";
          }
          
          state = state.copyWith(
            secondsElapsed: newElapsed,
            currentBpm: hr,
            motivationMessage: newMsg,
          );
          return;
        }
      }
      
      state = state.copyWith(secondsElapsed: newElapsed);
    });
  }
}

final workoutTimerProvider = NotifierProvider<WorkoutTimerNotifier, WorkoutTimerState>(() {
  return WorkoutTimerNotifier();
});
