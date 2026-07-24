import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  SunbathingState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _notificationService.cancelSunbathingAlarm();
    });

    return SunbathingState(
      totalDurationSeconds: 15 * 60, // Default 15 mins
      remainingSeconds: 15 * 60,
      isRunning: false,
      isFrontSide: true,
      isFinished: false,
    );
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
    
    final title = state.isFrontSide ? 'Ön Yüz Süresi Doldu!' : 'Arka Yüz Süresi Doldu!';
    final body = state.isFrontSide 
        ? 'Yanmamak için lütfen arkanızı dönün ve süreyi tekrar başlatın.' 
        : 'Güneşlenme tamamlandı! Güneş kreminizi yenilemeyi unutmayın.';

    _notificationService.scheduleSunbathingAlarm(
      durationSeconds: state.remainingSeconds,
      title: title,
      body: body,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 0) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _onTimeUp();
      }
    });
  }

  void pause() {
    if (!state.isRunning) return;
    _timer?.cancel();
    _notificationService.cancelSunbathingAlarm();
    state = state.copyWith(isRunning: false);
  }

  void stop() {
    _timer?.cancel();
    _notificationService.cancelSunbathingAlarm();
    state = state.copyWith(
      isRunning: false,
      remainingSeconds: state.totalDurationSeconds,
    );
  }
  
  void resetSide() {
    _timer?.cancel();
    _notificationService.cancelSunbathingAlarm();
    state = state.copyWith(
      isRunning: false,
      isFinished: false,
      remainingSeconds: state.totalDurationSeconds,
    );
  }

  void _onTimeUp() {
    _timer?.cancel();
    
    if (state.isFrontSide) {
      // First side done, switch to back
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
