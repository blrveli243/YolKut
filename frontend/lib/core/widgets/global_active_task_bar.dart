import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/sunbathing/sunbathing_provider.dart';
import '../../features/sunbathing/sunbathing_screen.dart';
import '../../features/sports/pacer/pacer_service.dart';
import '../../features/sports/pacer/active_pace_screen.dart';
import '../theme/app_colors.dart';

class GlobalActiveTaskBar extends ConsumerWidget {
  const GlobalActiveTaskBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sunbathingState = ref.watch(sunbathingProvider);
    final sunbathingNotifier = ref.read(sunbathingProvider.notifier);

    // If sunbathing is running, show the bar
    if (sunbathingState.isRunning) {
      final int minutes = sunbathingState.remainingSeconds ~/ 60;
      final int seconds = sunbathingState.remainingSeconds % 60;
      final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      final sideText = sunbathingState.isFrontSide ? 'Ön Yüz' : 'Arka Yüz';

      return GestureDetector(
        onTap: () {
          // Navigate to Sunbathing Screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SunbathingScreen()),
          );
        },
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Güneşlenme',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$sideText • $timeString kaldı',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.pause_rounded, color: Colors.white),
                onPressed: () {
                  sunbathingNotifier.pause();
                },
              ),
              IconButton(
                icon: const Icon(Icons.stop_rounded, color: Colors.white),
                onPressed: () {
                  sunbathingNotifier.stop();
                },
              ),
            ],
          ),
        ),
      );
    }

    final pacerState = ref.watch(pacerProvider);
    final pacerNotifier = ref.read(pacerProvider.notifier);

    // If pacer is running, show the bar
    if (pacerState.isRunning) {
      final int minutes = pacerState.elapsedSeconds ~/ 60;
      final int seconds = pacerState.elapsedSeconds % 60;
      final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      final distanceStr = pacerState.distanceKm.toStringAsFixed(2);

      return GestureDetector(
        onTap: () {
          // Navigate to Active Pace Screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ActivePaceScreen()),
          );
        },
        child: Container(
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.directions_run_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'PaceMaster (Koşu)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$distanceStr km • Süre: $timeString',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.stop_rounded, color: Colors.white),
                onPressed: () {
                  pacerNotifier.stopPacer();
                },
              ),
            ],
          ),
        ),
      );
    }

    // Return empty widget if no active tasks
    return const SizedBox.shrink();
  }
}
