import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';

class SunbathingState {
  final int totalDurationSeconds;
  final int remainingSeconds;
  final bool isRunning;
  final bool isFrontSide; // true = Front, false = Back
  final bool isFinished;

  SunbathingState({
    required this.totalDurationSeconds,
    required this.remainingSeconds,
    required this.isRunning,
    required this.isFrontSide,
    required this.isFinished,
  });

  SunbathingState copyWith({
    int? totalDurationSeconds,
    int? remainingSeconds,
    bool? isRunning,
    bool? isFrontSide,
    bool? isFinished,
  }) {
    return SunbathingState(
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
      isFrontSide: isFrontSide ?? this.isFrontSide,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

class SunbathingNotifier extends Notifier<SunbathingState> {
  Timer? _timer;
  final NotificationService _notificationService = NotificationService();
  static const MethodChannel _liveActivityChannel = MethodChannel('com.velibilir.yolkut/live_activity');

  // SharedPreferences keys
  static const _keyStartTime = 'sunbathing_start_time';
  static const _keyTotalDuration = 'sunbathing_total_duration';
  static const _keyIsFrontSide = 'sunbathing_is_front_side';
  static const _keyIsRunning = 'sunbathing_is_running';
  static const _keyPausedRemaining = 'sunbathing_paused_remaining';

  @override
  SunbathingState build() {
    ref.onDispose(() {
      _timer?.cancel();
    });

    // Restore state from disk on build
    _restoreState();

    return SunbathingState(
      totalDurationSeconds: 15 * 60,
      remainingSeconds: 15 * 60,
      isRunning: false,
      isFrontSide: true,
      isFinished: false,
    );
  }

  /// Restore timer state from SharedPreferences.
  /// If app was killed while running, recalculate remaining time.
  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final isRunning = prefs.getBool(_keyIsRunning) ?? false;
    final totalDuration = prefs.getInt(_keyTotalDuration) ?? 15 * 60;
    final isFrontSide = prefs.getBool(_keyIsFrontSide) ?? true;

    if (isRunning) {
      // Timer was active when app was closed/backgrounded
      final startTimeMs = prefs.getInt(_keyStartTime) ?? 0;
      if (startTimeMs > 0) {
        final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
        final elapsed = DateTime.now().difference(startTime).inSeconds;
        final remaining = totalDuration - elapsed;

        if (remaining > 0) {
          // Timer still has time left - resume!
          state = SunbathingState(
            totalDurationSeconds: totalDuration,
            remainingSeconds: remaining,
            isRunning: true,
            isFrontSide: isFrontSide,
            isFinished: false,
          );
          _startInternalTimer();
          _startLiveActivity();
        } else {
          // Time already expired while app was closed
          await _clearPersistedState();
          _onTimeUp();
        }
      }
    } else {
      // Check if there's a paused state
      final pausedRemaining = prefs.getInt(_keyPausedRemaining) ?? 0;
      if (pausedRemaining > 0) {
        state = SunbathingState(
          totalDurationSeconds: totalDuration,
          remainingSeconds: pausedRemaining,
          isRunning: false,
          isFrontSide: isFrontSide,
          isFinished: false,
        );
      }
    }
  }

  /// Called when app comes back to foreground
  Future<void> onAppResumed() async {
    if (!state.isRunning) return;

    final prefs = await SharedPreferences.getInstance();
    final startTimeMs = prefs.getInt(_keyStartTime) ?? 0;
    final totalDuration = prefs.getInt(_keyTotalDuration) ?? state.totalDurationSeconds;

    if (startTimeMs > 0) {
      final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      final remaining = totalDuration - elapsed;

      if (remaining > 0) {
        state = state.copyWith(remainingSeconds: remaining);
      } else {
        await _clearPersistedState();
        _onTimeUp();
      }
    }
  }

  /// Persist running state to disk
  Future<void> _persistRunningState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyStartTime, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(_keyTotalDuration, state.totalDurationSeconds);
    await prefs.setBool(_keyIsFrontSide, state.isFrontSide);
    await prefs.setBool(_keyIsRunning, true);
    await prefs.remove(_keyPausedRemaining);
  }

  /// Persist paused state to disk
  Future<void> _persistPausedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsRunning, false);
    await prefs.setInt(_keyPausedRemaining, state.remainingSeconds);
    await prefs.setInt(_keyTotalDuration, state.totalDurationSeconds);
    await prefs.setBool(_keyIsFrontSide, state.isFrontSide);
    await prefs.remove(_keyStartTime);
  }

  /// Clear all persisted state
  Future<void> _clearPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStartTime);
    await prefs.remove(_keyTotalDuration);
    await prefs.remove(_keyIsFrontSide);
    await prefs.remove(_keyIsRunning);
    await prefs.remove(_keyPausedRemaining);
  }

  void setDuration(int minutes) {
    if (state.isRunning) return;
    
    final seconds = minutes * 60;
    state = state.copyWith(
      totalDurationSeconds: seconds,
      remainingSeconds: seconds,
      isFinished: false,
    );
  }

  void start() {
    if (state.isRunning || state.isFinished) return;

    state = state.copyWith(isRunning: true);
    
    // Persist to disk so timer survives app kill
    _persistRunningState();

    // Schedule alarm notification for when time expires
    final title = state.isFrontSide ? 'Ön Yüz Süresi Doldu!' : 'Arka Yüz Süresi Doldu!';
    final body = state.isFrontSide 
        ? 'Yanmamak için lütfen arkanızı dönün ve süreyi tekrar başlatın.' 
        : 'Güneşlenme tamamlandı! Güneş kreminizi yenilemeyi unutmayın.';

    _notificationService.scheduleSunbathingAlarm(
      durationSeconds: state.remainingSeconds,
      title: title,
      body: body,
    );

    _notificationService.showOngoingNotification(
      id: 9998,
      title: '☀️ Güneşlenme Modu Aktif',
      body: state.isFrontSide ? 'Ön Yüz (Göğüs/Karın)' : 'Arka Yüz (Sırt/Bacak)',
      durationSeconds: state.remainingSeconds,
      taskType: 'sunbathing',
      isPaused: false,
    );

    _startLiveActivity();
    _startInternalTimer();
  }

  void _startInternalTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _startLiveActivity() {
    try {
      _liveActivityChannel.invokeMethod('start', {
        'totalDurationSeconds': state.totalDurationSeconds,
        'isFrontSide': state.isFrontSide,
      });
    } catch (e) {
      debugPrint('Live Activity start error: $e');
    }
  }

  void _tick(Timer timer) {
    if (state.remainingSeconds > 0) {
      state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      try {
        _liveActivityChannel.invokeMethod('update', {
          'remainingSeconds': state.remainingSeconds,
        });
      } catch (e) {
        // ignore
      }
    } else {
      _onTimeUp();
    }
  }

  void pause() {
    if (!state.isRunning) return;
    _timer?.cancel();
    _notificationService.cancelSunbathingAlarm();
    state = state.copyWith(isRunning: false);
    _persistPausedState();
    
    // Update notification to show paused state with resume button
    _notificationService.showOngoingNotification(
      id: 9998,
      title: '⏸️ Güneşlenme Duraklatıldı',
      body: state.isFrontSide ? 'Ön Yüz (Göğüs/Karın)' : 'Arka Yüz (Sırt/Bacak)',
      durationSeconds: state.remainingSeconds,
      taskType: 'sunbathing',
      isPaused: true,
    );

    try {
      _liveActivityChannel.invokeMethod('stop');
    } catch (_) {}
  }

  void stop() {
    _timer?.cancel();
    _notificationService.cancelSunbathingAlarm();
    _notificationService.cancelOngoingNotification(9998);
    state = state.copyWith(
      isRunning: false,
      remainingSeconds: state.totalDurationSeconds,
    );
    _clearPersistedState();
    
    try {
      _liveActivityChannel.invokeMethod('stop');
    } catch (_) {}
  }
  
  void resetSide() {
    _timer?.cancel();
    _notificationService.cancelSunbathingAlarm();
    _notificationService.cancelOngoingNotification(9998);
    state = state.copyWith(
      isRunning: false,
      isFinished: false,
      isFrontSide: true,
      remainingSeconds: state.totalDurationSeconds,
    );
    _clearPersistedState();
    
    try {
      _liveActivityChannel.invokeMethod('stop');
    } catch (_) {}
  }

  void _onTimeUp() {
    _timer?.cancel();
    _notificationService.cancelOngoingNotification(9998);
    _clearPersistedState();
    
    try {
      _liveActivityChannel.invokeMethod('stop');
    } catch (_) {}
    
    if (state.isFrontSide) {
      state = state.copyWith(
        isRunning: false,
        isFrontSide: false,
        remainingSeconds: state.totalDurationSeconds,
      );
    } else {
      // Both sides done
      state = state.copyWith(
        isRunning: false,
        isFinished: true,
      );
    }
  }

}

final sunbathingProvider = NotifierProvider<SunbathingNotifier, SunbathingState>(() {
  return SunbathingNotifier();
});
