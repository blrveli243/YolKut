import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../core/services/notification_service.dart';

class StudyTimerState {
  final int secondsRemaining;
  final bool isRunning;
  final bool isBreak;
  final int completedPomodoros;

  StudyTimerState({
    required this.secondsRemaining,
    required this.isRunning,
    required this.isBreak,
    required this.completedPomodoros,
  });

  StudyTimerState copyWith({
    int? secondsRemaining,
    bool? isRunning,
    bool? isBreak,
    int? completedPomodoros,
  }) {
    return StudyTimerState(
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isRunning: isRunning ?? this.isRunning,
      isBreak: isBreak ?? this.isBreak,
      completedPomodoros: completedPomodoros ?? this.completedPomodoros,
    );
  }
}

class StudyTimerNotifier extends Notifier<StudyTimerState> {
  Timer? _timer;
  final NotificationService _notificationService = NotificationService();

  static const _keyStartTime = 'study_start_time';
  static const _keyIsRunning = 'study_is_running';
  static const _keyIsBreak = 'study_is_break';
  static const _keySecondsRemaining = 'study_seconds_remaining';
  static const _keyCompletedPomodoros = 'study_completed_pomodoros';

  @override
  StudyTimerState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });

    _restoreState();

    return StudyTimerState(
      secondsRemaining: 25 * 60,
      isRunning: false,
      isBreak: false,
      completedPomodoros: 0,
    );
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final isRunning = prefs.getBool(_keyIsRunning) ?? false;
    final isBreak = prefs.getBool(_keyIsBreak) ?? false;
    final completedPomodoros = prefs.getInt(_keyCompletedPomodoros) ?? 0;
    final savedSeconds = prefs.getInt(_keySecondsRemaining) ?? (isBreak ? 5 * 60 : 25 * 60);

    if (isRunning) {
      final startTimeMs = prefs.getInt(_keyStartTime) ?? 0;
      if (startTimeMs > 0) {
        final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
        final elapsed = DateTime.now().difference(startTime).inSeconds;
        final remaining = savedSeconds - elapsed;

        if (remaining > 0) {
          state = StudyTimerState(
            secondsRemaining: remaining,
            isRunning: true,
            isBreak: isBreak,
            completedPomodoros: completedPomodoros,
          );
          _startInternalTimer();
        } else {
          // Time expired in background
          state = StudyTimerState(
            secondsRemaining: 0,
            isRunning: false,
            isBreak: isBreak,
            completedPomodoros: completedPomodoros,
          );
          await _clearPersistedState();
          _handleTimerCompletion();
        }
      }
    } else {
      state = StudyTimerState(
        secondsRemaining: savedSeconds,
        isRunning: false,
        isBreak: isBreak,
        completedPomodoros: completedPomodoros,
      );
    }
  }

  Future<void> onAppResumed() async {
    if (!state.isRunning) return;
    final prefs = await SharedPreferences.getInstance();
    final startTimeMs = prefs.getInt(_keyStartTime) ?? 0;
    
    // We saved the seconds remaining AT the moment of start/resume
    final savedSeconds = prefs.getInt(_keySecondsRemaining) ?? state.secondsRemaining;

    if (startTimeMs > 0) {
      final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      final remaining = savedSeconds - elapsed;

      if (remaining > 0) {
        state = state.copyWith(secondsRemaining: remaining);
      } else {
        await _clearPersistedState();
        _handleTimerCompletion();
      }
    }
  }

  Future<void> _persistRunningState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStartTime, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(_keySecondsRemaining, state.secondsRemaining);
    await prefs.setBool(_keyIsRunning, true);
    await prefs.setBool(_keyIsBreak, state.isBreak);
    await prefs.setInt(_keyCompletedPomodoros, state.completedPomodoros);
  }

  Future<void> _persistPausedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsRunning, false);
    await prefs.setInt(_keySecondsRemaining, state.secondsRemaining);
    await prefs.remove(_keyStartTime);
  }

  Future<void> _clearPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStartTime);
    await prefs.remove(_keyIsRunning);
    // Keep completed pomodoros and break status so user doesn't lose context
  }

  void toggleTimer() {
    if (state.isRunning) {
      pause();
    } else {
      start();
    }
  }

  void start() {
    if (state.isRunning) return;
    
    state = state.copyWith(isRunning: true);
    _persistRunningState();
    
    _notificationService.showOngoingNotification(
      id: 9997,
      title: state.isBreak ? '☕ Mola Zamanı' : '📚 Odaklanma Zamanı',
      body: 'Arka planda sayacınız işlemeye devam ediyor.',
      durationSeconds: state.secondsRemaining,
      taskType: 'study',
      isPaused: false,
    );

    _startInternalTimer();
  }

  void pause() {
    if (!state.isRunning) return;
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
    _persistPausedState();

    _notificationService.showOngoingNotification(
      id: 9997,
      title: '⏸️ Sayaç Duraklatıldı',
      body: state.isBreak ? 'Mola duraklatıldı.' : 'Odaklanma duraklatıldı.',
      durationSeconds: state.secondsRemaining,
      taskType: 'study',
      isPaused: true,
    );
  }

  void resetTimer() {
    _timer?.cancel();
    _notificationService.cancelOngoingNotification(9997);
    
    final resetTime = state.isBreak ? 5 * 60 : 25 * 60;
    state = state.copyWith(
      isRunning: false,
      secondsRemaining: resetTime,
    );
    _clearPersistedState();
    
    _persistPausedState();
  }

  void stop() {
    resetTimer();
  }

  void _startInternalTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.secondsRemaining > 0) {
        state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
      } else {
        _timer?.cancel();
        _handleTimerCompletion();
      }
    });
  }

  Future<void> _handleTimerCompletion() async {
    _notificationService.cancelOngoingNotification(9997);
    
    if (!state.isBreak) {
      // Completed a Pomodoro
      final newCompleted = state.completedPomodoros + 1;
      state = state.copyWith(
        isRunning: false,
        isBreak: true,
        secondsRemaining: 5 * 60, // 5 min break
        completedPomodoros: newCompleted,
      );
      
      // Save log automatically
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyCompletedPomodoros, newCompleted);
      
      final logsRaw = prefs.getString('study_logs') ?? '[]';
      final logs = List<Map<String, dynamic>>.from(json.decode(logsRaw));
      logs.insert(0, {
        'date': DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
        'subject': 'Pomodoro Oturumu',
        'duration': 25,
        'questions': 0,
      });
      await prefs.setString('study_logs', json.encode(logs));
      
      _notificationService.scheduleSunbathingAlarm(
        durationSeconds: 0,
        title: '🎉 Tebrikler! Pomodoro Bitti',
        body: '25 dakikalık çalışma tamamlandı. Şimdi 5 dakika mola zamanı!',
      );
    } else {
      // Completed break
      state = state.copyWith(
        isRunning: false,
        isBreak: false,
        secondsRemaining: 25 * 60,
      );
      
      _notificationService.scheduleSunbathingAlarm(
        durationSeconds: 0,
        title: '☕ Mola Bitti',
        body: 'Molanız sona erdi. Yeni bir Pomodoro seansına hazır mısınız?',
      );
    }
    
    _persistPausedState();
  }
}

final studyTimerProvider = NotifierProvider<StudyTimerNotifier, StudyTimerState>(() {
  return StudyTimerNotifier();
});
