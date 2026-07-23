import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/primary_button.dart';
import 'pacer_service.dart';
import 'active_pace_screen.dart';

class PaceSetupScreen extends ConsumerStatefulWidget {
  const PaceSetupScreen({super.key});

  @override
  ConsumerState<PaceSetupScreen> createState() => _PaceSetupScreenState();
}

class _PaceSetupScreenState extends ConsumerState<PaceSetupScreen> {
  double _targetSpeed = 6.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PaceMaster',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hedef Hızını Belirle',
                style: TextStyle(
                  color: AppColors.darkText,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sabit ve ritmik bir koşu için hedefini ayarla. Koşu boyunca akıllı saatin veya telefonun sensörleri seni titreşimlerle yönlendirecek.',
                style: TextStyle(
                  color: AppColors.darkText.withValues(alpha: 0.7),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const Spacer(),

              // Hız Ayarı
              Center(
                child: Column(
                  children: [
                    Text(
                      '${_targetSpeed.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 84,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -2.0,
                      ),
                    ),
                    Text(
                      'km / saat',
                      style: TextStyle(
                        color: AppColors.darkText.withValues(alpha: 0.5),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Slider
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.darkDivider,
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withValues(alpha: 0.2),
                  trackHeight: 8,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 16,
                  ),
                ),
                child: Slider(
                  value: _targetSpeed,
                  min: 3.0,
                  max: 20.0,
                  divisions: 170, // Her 0.1 için
                  onChanged: (value) {
                    setState(() {
                      _targetSpeed = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 32),
              
              // Ses Modu Seçimi
              Text(
                'Ses Modu',
                style: TextStyle(
                  color: AppColors.darkText.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, child) {
                  final audioMode = ref.watch(pacerProvider).audioMode;
                  return Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ref.read(pacerProvider.notifier).setAudioMode(PacerAudioMode.breath),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: audioMode == PacerAudioMode.breath ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: audioMode == PacerAudioMode.breath ? AppColors.primary : AppColors.darkDivider,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.air, color: audioMode == PacerAudioMode.breath ? AppColors.primary : AppColors.darkText.withValues(alpha: 0.5)),
                                const SizedBox(height: 8),
                                Text(
                                  'Gerçek Nefes',
                                  style: TextStyle(
                                    color: audioMode == PacerAudioMode.breath ? AppColors.primary : AppColors.darkText.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Müziği kısar',
                                  style: TextStyle(
                                    color: AppColors.darkText.withValues(alpha: 0.3),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => ref.read(pacerProvider.notifier).setAudioMode(PacerAudioMode.beep),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: audioMode == PacerAudioMode.beep ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: audioMode == PacerAudioMode.beep ? AppColors.primary : AppColors.darkDivider,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.music_note, color: audioMode == PacerAudioMode.beep ? AppColors.primary : AppColors.darkText.withValues(alpha: 0.5)),
                                const SizedBox(height: 8),
                                Text(
                                  'Bip (Metronom)',
                                  style: TextStyle(
                                    color: audioMode == PacerAudioMode.beep ? AppColors.primary : AppColors.darkText.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Müzikle karışır',
                                  style: TextStyle(
                                    color: AppColors.darkText.withValues(alpha: 0.3),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              
              const Spacer(),
              
              SizedBox(
                width: double.infinity,
                height: 64,
                child: PrimaryButton(
                  text: 'KOŞUYA BAŞLA',
                  onPressed: () {
                    // Ayarı provider'a kaydet (ses modu tıklanınca ayarlanıyor zaten)
                    ref.read(pacerProvider.notifier).setTargetSpeed(_targetSpeed);
                    
                    // Aktif koşu ekranına geç
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActivePaceScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
