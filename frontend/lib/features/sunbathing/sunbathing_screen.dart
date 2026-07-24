import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'sunbathing_provider.dart';

class SunbathingScreen extends ConsumerWidget {
  const SunbathingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sunbathingProvider);
    final notifier = ref.read(sunbathingProvider.notifier);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Güneşlenme Modu'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Side indicator (Front vs Back)
              Text(
                state.isFinished 
                    ? 'Güneşlenme Tamamlandı!' 
                    : (state.isFrontSide ? 'Ön Yüz (Göğüs/Karın)' : 'Arka Yüz (Sırt/Bacak)'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: state.isFinished ? AppColors.info : AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                state.isFinished 
                    ? 'Güneş kreminizi yenilemeyi unutmayın.' 
                    : 'Lütfen seçtiğiniz yüzeyin güneşe dönük olduğundan emin olun.',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Timer Circular Progress
              _buildTimerCircle(context, state),
              
              const SizedBox(height: 40),

              // Controls
              if (!state.isRunning && !state.isFinished)
                _buildDurationSelector(context, state, notifier),
              
              const SizedBox(height: 40),
              
              _buildActionButtons(context, state, notifier),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerCircle(BuildContext context, SunbathingState state) {
    final double progress = state.totalDurationSeconds > 0 
        ? 1.0 - (state.remainingSeconds / state.totalDurationSeconds) 
        : 0.0;
        
    final int minutes = state.remainingSeconds ~/ 60;
    final int seconds = state.remainingSeconds % 60;
    final timeString = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 250,
          height: 250,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 16,
            backgroundColor: Theme.of(context).dividerColor.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              state.isFinished ? AppColors.info : AppColors.warning,
            ),
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wb_sunny_rounded,
              size: 40,
              color: state.isFinished ? AppColors.info : AppColors.warning,
            ),
            const SizedBox(height: 12),
            Text(
              timeString,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDurationSelector(BuildContext context, SunbathingState state, SunbathingNotifier notifier) {
    return Column(
      children: [
        Text(
          'Yüzey Başına Süre Seçin:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [5, 10, 15, 20, 30].map((mins) {
            final isSelected = state.totalDurationSeconds == (mins * 60);
            return GestureDetector(
              onTap: () => notifier.setDuration(mins),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.warning : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? AppColors.warning : Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: Text(
                  '$mins dk',
                  style: TextStyle(
                    color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, SunbathingState state, SunbathingNotifier notifier) {
    if (state.isFinished) {
      return ElevatedButton.icon(
        onPressed: notifier.resetSide,
        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        label: const Text('Baştan Başla', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (state.isRunning) ...[
          _buildCircleButton(
            context, 
            icon: Icons.pause_rounded, 
            color: AppColors.info, 
            onTap: notifier.pause,
          ),
          const SizedBox(width: 24),
          _buildCircleButton(
            context, 
            icon: Icons.stop_rounded, 
            color: AppColors.error, 
            onTap: notifier.stop,
          ),
        ] else ...[
          _buildCircleButton(
            context, 
            icon: Icons.play_arrow_rounded, 
            color: AppColors.warning, 
            size: 80,
            iconSize: 40,
            onTap: notifier.start,
          ),
        ],
      ],
    );
  }

  Widget _buildCircleButton(BuildContext context, {
    required IconData icon, 
    required Color color, 
    required VoidCallback onTap,
    double size = 64,
    double iconSize = 32,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }
}
