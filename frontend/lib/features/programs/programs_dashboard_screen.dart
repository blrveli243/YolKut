import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'sports_program_screen.dart';
import 'language_program_screen.dart';
import 'study_program_screen.dart';
import 'personal_dev_program_screen.dart';
import 'other_program_screen.dart';
import 'yolkut_analytics_screen.dart';

class ProgramsDashboardScreen extends StatelessWidget {
  const ProgramsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Program Kategorileri',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: AppColors.info),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => YolKutAnalyticsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Hangi alanda program oluşturmak istersiniz?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          _buildCategoryCard(
            context,
            title: 'Spor Programı',
            subtitle: 'Haftalık egzersiz, set ve tekrarlarınızı planlayın.',
            icon: Icons.fitness_center,
            color: AppColors.warning, // Orange for sports
            destination: const SportsProgramScreen(),
          ),
          _buildCategoryCard(
            context,
            title: 'Ders / Eğitim',
            subtitle: 'Ders çalışma saatlerinizi ve konularınızı yönetin.',
            icon: Icons.menu_book,
            color: AppColors.info, // Blue for study
            destination: const StudyProgramScreen(),
          ),
          _buildCategoryCard(
            context,
            title: 'Dil Öğrenimi',
            subtitle: 'Günlük kelime pratiği ve çalışma rutinleri.',
            icon: Icons.language,
            color: AppColors.primary, // Green for language
            destination: const LanguageProgramScreen(),
          ),
          _buildCategoryCard(
            context,
            title: 'Kişisel Gelişim',
            subtitle: 'Kitap okuma, meditasyon, yeni alışkanlıklar.',
            icon: Icons.psychology,
            color: const Color(0xFF8B5CF6), // Purple for personal dev
            destination: const PersonalDevProgramScreen(),
          ),
          _buildCategoryCard(
            context,
            title: 'Diğer',
            subtitle: 'Kendi özel programınızı oluşturun.',
            icon: Icons.star,
            color: const Color(0xFFEC4899), // Pink for other
            destination: const OtherProgramScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
