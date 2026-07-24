import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/api_client.dart';
import '../../../core/services/notification_service.dart';

enum PaceStatus { perfect, tooSlow, tooFast, initializing }
enum PacerAudioMode { breath, beep }

class PacerState {
  final double targetSpeedKmH; // Hedef hız (km/s)
  final double currentSpeedKmH; // Anlık hız (km/s)
  final double distanceKm; // Toplam katedilen mesafe
  final int elapsedSeconds; // Geçen süre
  final PaceStatus status;
  final bool isRunning;
  final bool isPaused;
  
  // Nefes Koçu Değişkenleri
  final bool isInhaling; // True ise Nefes Al, False ise Nefes Ver
  final int breathingDurationMs; // Güncel ritme göre nefes alma/verme süresi
  final PacerAudioMode audioMode; // Müzikli (bip) veya Müziksiz (Nefes)
  final bool isCoachEnabled; // Koçu Aç/Kapat

  PacerState({
    required this.targetSpeedKmH,
    required this.currentSpeedKmH,
    required this.distanceKm,
    required this.elapsedSeconds,
    required this.status,
    required this.isRunning,
    required this.isPaused,
    required this.isInhaling,
    required this.breathingDurationMs,
    required this.audioMode,
    required this.isCoachEnabled,
  });

  PacerState copyWith({
    double? targetSpeedKmH,
    double? currentSpeedKmH,
    double? distanceKm,
    int? elapsedSeconds,
    PaceStatus? status,
    bool? isRunning,
    bool? isPaused,
    bool? isInhaling,
    int? breathingDurationMs,
    PacerAudioMode? audioMode,
    bool? isCoachEnabled,
  }) {
    return PacerState(
      targetSpeedKmH: targetSpeedKmH ?? this.targetSpeedKmH,
      currentSpeedKmH: currentSpeedKmH ?? this.currentSpeedKmH,
      distanceKm: distanceKm ?? this.distanceKm,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      status: status ?? this.status,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      isInhaling: isInhaling ?? this.isInhaling,
      breathingDurationMs: breathingDurationMs ?? this.breathingDurationMs,
      audioMode: audioMode ?? this.audioMode,
      isCoachEnabled: isCoachEnabled ?? this.isCoachEnabled,
    );
  }

  factory PacerState.initial() {
    return PacerState(
      targetSpeedKmH: 6.0,
      currentSpeedKmH: 0.0,
      distanceKm: 0.0,
      elapsedSeconds: 0,
      status: PaceStatus.initializing,
      isRunning: false,
      isPaused: false,
      isInhaling: true,
      breathingDurationMs: 1500, 
      audioMode: PacerAudioMode.breath, 
      isCoachEnabled: true, // Varsayılan olarak açık
    );
  }
}

class PacerNotifier extends Notifier<PacerState> {
  Timer? _timer;
  StreamSubscription<Position>? _positionStream;
  Position? _lastPosition;
  
  // Breathing Engine
  Timer? _breathingTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Haptic Feedback Cooldown
  DateTime? _lastWarningTime;

  final NotificationService _notificationService = NotificationService();

  @override
  PacerState build() {
    ref.onDispose(() {
      _timer?.cancel();
      _breathingTimer?.cancel();
      _positionStream?.cancel();
      _audioPlayer.dispose(); 
    });
    return PacerState.initial();
  }

  void toggleCoach() {
    final nextState = !state.isCoachEnabled;
    state = state.copyWith(isCoachEnabled: nextState);
    if (!nextState) {
      // Kapatıldıysa zamanlayıcıyı ve sesi durdur
      _breathingTimer?.cancel();
      _audioPlayer.stop();
    } else if (state.isRunning) {
      // Yeniden açıldıysa ve koşu devam ediyorsa döngüyü başlat
      _startBreathingCycle();
    }
  }

  Future<void> _configureAudioContext() async {
    // Ses moduna göre AudioContext ayarla
    if (state.audioMode == PacerAudioMode.breath) {
      // Nefes Modu: Müziği kısar (Ducking)
      await _audioPlayer.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.duckOthers},
        ),
        android: AudioContextAndroid(
          usageType: AndroidUsageType.media,
          contentType: AndroidContentType.sonification,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ));
    } else {
      // Bip Modu: Müziğin üzerine karışır, kısmaz (Mixing)
      await _audioPlayer.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          usageType: AndroidUsageType.media,
          contentType: AndroidContentType.sonification,
          audioFocus: AndroidAudioFocus.gainTransient, // Ducking yapmaz
        ),
      ));
    }
  }

  void setTargetSpeed(double speed) {
    state = state.copyWith(targetSpeedKmH: speed);
    if (state.isRunning) {
      _startBreathingCycle(); 
    }
  }

  void setAudioMode(PacerAudioMode mode) {
    state = state.copyWith(audioMode: mode);
  }

  Future<void> startPacer() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    state = state.copyWith(
      isRunning: true,
      isPaused: false,
      currentSpeedKmH: 0.0,
      distanceKm: 0.0,
      elapsedSeconds: 0,
      status: PaceStatus.initializing,
      isInhaling: true,
    );

    await _configureAudioContext(); // Mod değiştiğinde sesi yapılandır

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isRunning) return;
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });

    _startBreathingCycle();

    late LocationSettings locationSettings;

    if (Platform.isAndroid) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 1),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "PaceMaster arka planda koşunuzu takip ediyor",
          notificationTitle: "PaceMaster Aktif",
          enableWakeLock: true,
        ),
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        activityType: ActivityType.fitness,
        distanceFilter: 2,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2, 
      );
    }

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (!state.isRunning) return;
      double currentSpeed = position.speed * 3.6;
      if (currentSpeed < 0) currentSpeed = 0.0;

      double addedDistanceKm = 0.0;
      
      // JITTER FIX: Sadece 2 km/s (yürüme hızı) üzerinde hareket varsa mesafe ekle
      if (currentSpeed >= 2.0 && _lastPosition != null) {
        final timeDiffSeconds = position.timestamp.difference(_lastPosition!.timestamp).inSeconds;
        // Eğer aşırı büyük bir zaman farkı yoksa (GPS kesintisi) hız üzerinden mesafeyi entegre et
        if (timeDiffSeconds > 0 && timeDiffSeconds < 10) {
          double speedMetersPerSecond = currentSpeed / 3.6;
          addedDistanceKm = (speedMetersPerSecond * timeDiffSeconds) / 1000.0;
        }
      }
      _lastPosition = position;

      state = state.copyWith(distanceKm: state.distanceKm + addedDistanceKm);
      _evaluatePace(currentSpeed);
    });

    _updateNotification();
  }

  void pausePacer() {
    if (!state.isRunning || state.isPaused) return;
    _timer?.cancel();
    _breathingTimer?.cancel();
    _positionStream?.pause();
    _audioPlayer.pause();
    state = state.copyWith(isPaused: true);
    _updateNotification();
  }

  void resumePacer() {
    if (!state.isRunning || !state.isPaused) return;
    state = state.copyWith(isPaused: false);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!state.isRunning || state.isPaused) return;
      state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
    });
    
    _startBreathingCycle();
    _positionStream?.resume();
    _updateNotification();
  }

  void _updateNotification() {
    if (state.isRunning) {
      _notificationService.showOngoingNotification(
        id: 9995,
        title: state.isPaused ? '⏸️ PaceMaster Duraklatıldı' : '🏃‍♂️ PaceMaster Aktif',
        body: 'Mesafe: ${state.distanceKm.toStringAsFixed(2)} km - Süre: ${state.elapsedSeconds}s',
        durationSeconds: state.elapsedSeconds,
        taskType: 'pacer',
        isPaused: state.isPaused,
      );
    } else {
      _notificationService.cancelOngoingNotification(9995);
    }
  }

  void _startBreathingCycle() {
    _breathingTimer?.cancel();

    int durationMs = 1500;
    if (state.targetSpeedKmH >= 12.0) {
      durationMs = 700;
    } else if (state.targetSpeedKmH >= 8.0) {
      durationMs = 1000;
    } else {
      durationMs = 1500;
    }

    state = state.copyWith(breathingDurationMs: durationMs);

    _breathingTimer = Timer.periodic(Duration(milliseconds: durationMs), (timer) {
      if (!state.isRunning) {
        timer.cancel();
        return;
      }

      final nextInhaling = !state.isInhaling;
      state = state.copyWith(isInhaling: nextInhaling);

      // Sese karar ver
      String assetPath = '';
      if (state.audioMode == PacerAudioMode.breath) {
        assetPath = nextInhaling ? 'audio/inhale.wav' : 'audio/exhale.wav';
      } else {
        assetPath = nextInhaling ? 'audio/beep_high.wav' : 'audio/beep_low.wav';
      }

      _playBreathSound(assetPath, durationMs);
      
      // Haptic Feedback sadece düşük/orta hızlarda net anlaşılır, çok hızlıysa kapatılabilir
      if (durationMs > 700) {
        HapticFeedback.lightImpact(); 
      }
    });
  }

  Future<void> _playBreathSound(String assetPath, int targetDurationMs) async {
    try {
      // AUDIO SYNC FIX: 1200ms'lik ses dosyasının hızını hedef süreye göre ayarla
      double rate = 1200.0 / targetDurationMs.toDouble();
      if (rate < 0.5) rate = 0.5;
      if (rate > 2.0) rate = 2.0;

      await _audioPlayer.setPlaybackRate(rate);
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (e) {
      // Dosya bulunamadıysa görmezden gel
    }
  }

  void _evaluatePace(double currentSpeed) {
    if (currentSpeed < 1.0 && state.elapsedSeconds < 5) return;

    final target = state.targetSpeedKmH;
    final tolerance = 0.5; 

    PaceStatus newStatus = PaceStatus.perfect;

    if (currentSpeed < (target - tolerance)) {
      newStatus = PaceStatus.tooSlow;
      _triggerHaptic(PaceStatus.tooSlow);
    } else if (currentSpeed > (target + tolerance)) {
      newStatus = PaceStatus.tooFast;
      _triggerHaptic(PaceStatus.tooFast);
    } else {
      newStatus = PaceStatus.perfect;
    }

    state = state.copyWith(currentSpeedKmH: currentSpeed, status: newStatus);
  }

  void _triggerHaptic(PaceStatus status) {
    // SPAM KORUMASI: Kullanıcıyı her saniye titretme, minimum 10 saniye bekle
    if (_lastWarningTime != null) {
      final difference = DateTime.now().difference(_lastWarningTime!);
      if (difference.inSeconds < 10) return;
    }
    
    _lastWarningTime = DateTime.now();

    if (status == PaceStatus.tooSlow) {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 200), () {
        HapticFeedback.mediumImpact();
      });
    } else if (status == PaceStatus.tooFast) {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> stopPacer() async {
    _timer?.cancel();
    _breathingTimer?.cancel();
    _positionStream?.cancel();
    _lastPosition = null;
    
    final distance = state.distanceKm;
    final elapsed = state.elapsedSeconds;
    final targetSpeed = state.targetSpeedKmH;
    final avgSpeed = elapsed > 0 ? (distance / (elapsed / 3600)) : 0.0;
    
    state = state.copyWith(isRunning: false, isPaused: false);
    await _audioPlayer.stop();
    _updateNotification();

    if (distance > 0.01 && elapsed > 10) {
      try {
        await apiClient.dio.post('/runs', data: {
          'distanceKm': distance,
          'elapsedSeconds': elapsed,
          'targetSpeedKmH': targetSpeed,
          'averageSpeedKmH': avgSpeed,
          'date': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // İleride çevrimdışı kaydetme mekanizması eklenebilir
      }
    }
  }
}

final pacerProvider = NotifierProvider<PacerNotifier, PacerState>(() {
  return PacerNotifier();
});
