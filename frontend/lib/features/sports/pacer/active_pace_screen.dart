import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import 'pacer_service.dart';

class ActivePaceScreen extends ConsumerStatefulWidget {
  const ActivePaceScreen({super.key});

  @override
  ConsumerState<ActivePaceScreen> createState() => _ActivePaceScreenState();
}

class _ActivePaceScreenState extends ConsumerState<ActivePaceScreen> {
  @override
  void initState() {
    super.initState();
    // Ekran açıldığında koşuyu başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pacerProvider.notifier).startPacer();
    });
  }

  @override
  void dispose() {
    // Ekrandan çıkarken pacer'ı durdur (Eğer arka planda çalışması istenirse bu kaldırılabilir)
    // Provider'ın stopPacer metodunu doğrudan widget'ın dispose'undan çağırıyoruz ki Timer sızıntısı olmasın.
    ref.read(pacerProvider.notifier).stopPacer();
    super.dispose();
  }

  void _finishRun() {
    ref.read(pacerProvider.notifier).stopPacer();
    Navigator.pop(context); // Geri dön
  }

  String _formatDuration(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final pacerState = ref.watch(pacerProvider);

    // Duruma göre renkler ve metinler
    Color statusColor = AppColors.primary; // Perfect
    String statusText = "RİTİM HARİKA";
    IconData statusIcon = Icons.check_circle_outline;

    if (pacerState.status == PaceStatus.tooSlow) {
      statusColor = AppColors.warning; // Sarı/Turuncu uyarı
      statusText = "HIZLAN! GERİDE KALDIN";
      statusIcon = Icons.arrow_upward_rounded;
    } else if (pacerState.status == PaceStatus.tooFast) {
      statusColor = AppColors.error; // Kırmızı uyarı
      statusText = "YAVAŞLA! ÇOK HIZLISIN";
      statusIcon = Icons.arrow_downward_rounded;
    } else if (pacerState.status == PaceStatus.initializing) {
      statusColor = AppColors.darkDivider;
      statusText = "SENSÖRLER BEKLENİYOR...";
      statusIcon = Icons.sensors;
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Üst Bilgi (Süre ve Mesafe)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SÜRE',
                        style: TextStyle(
                          color: AppColors.darkText.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        _formatDuration(pacerState.elapsedSeconds),
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'MESAFE',
                        style: TextStyle(
                          color: AppColors.darkText.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '${pacerState.distanceKm.toStringAsFixed(2)} km',
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Merkez: Anlık Hız
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.1),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ANLIK HIZ',
                    style: TextStyle(
                      color: AppColors.darkText.withValues(alpha: 0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pacerState.currentSpeedKmH.toStringAsFixed(1),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 84,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.0,
                    ),
                  ),
                  Text(
                    'km / saat',
                    style: TextStyle(
                      color: AppColors.darkText.withValues(alpha: 0.5),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Nefes Koçu Görseli (Animated Breathing)
            const SizedBox(height: 16),
            if (pacerState.isCoachEnabled)
              Column(
                children: [
                  Text(
                    pacerState.isInhaling ? 'NEFES AL' : 'NEFES VER',
                    style: TextStyle(
                      color: AppColors.info.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedContainer(
                    duration: Duration(milliseconds: pacerState.breathingDurationMs),
                    curve: Curves.easeInOutSine,
                    width: pacerState.isInhaling ? 80 : 30,
                    height: pacerState.isInhaling ? 80 : 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.info.withValues(alpha: pacerState.isInhaling ? 0.8 : 0.3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.info.withValues(alpha: 0.5),
                          blurRadius: pacerState.isInhaling ? 30 : 10,
                          spreadRadius: pacerState.isInhaling ? 10 : 2,
                        )
                      ]
                    ),
                  ),
                ],
              )
            else
              const SizedBox(height: 115), // Görsel kapalıyken layout kaymasını önlemek için boşluk

            const SizedBox(height: 16),

            // Nefes Koçu Aç/Kapat Butonu
            GestureDetector(
              onTap: () => ref.read(pacerProvider.notifier).toggleCoach(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: pacerState.isCoachEnabled 
                      ? AppColors.info.withValues(alpha: 0.1) 
                      : AppColors.darkDivider.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: pacerState.isCoachEnabled 
                        ? AppColors.info.withValues(alpha: 0.5) 
                        : AppColors.darkDivider.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      pacerState.isCoachEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      color: pacerState.isCoachEnabled ? AppColors.info : AppColors.darkText.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pacerState.isCoachEnabled ? 'KOÇ AÇIK' : 'KOÇ KAPALI',
                      style: TextStyle(
                        color: pacerState.isCoachEnabled ? AppColors.info : AppColors.darkText.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Durum Uyarısı (Hızlan / Yavaşla)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Alt Bilgi: Hedef Hız ve Bitir Butonu
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HEDEF',
                        style: TextStyle(
                          color: AppColors.darkText.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '${pacerState.targetSpeedKmH.toStringAsFixed(1)} km/s',
                        style: const TextStyle(
                          color: AppColors.darkText,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _finishRun,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.error, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.stop_rounded,
                          color: AppColors.error,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
