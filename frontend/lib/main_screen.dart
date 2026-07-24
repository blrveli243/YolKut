import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import 'features/health/dashboard_screen.dart';
import 'features/nutrition/nutrition_screen.dart';
import 'features/sports/sports_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/tasks/tasks_screen.dart';
import 'features/community/community_screen.dart';
import 'core/widgets/global_active_task_bar.dart';
import 'features/sunbathing/sunbathing_provider.dart';

class MainTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final mainTabIndexProvider = NotifierProvider<MainTabIndexNotifier, int>(() {
  return MainTabIndexNotifier();
});

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {
  final PageController _pageController = PageController(initialPage: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Sync sunbathing timer when app comes back to foreground
      ref.read(sunbathingProvider.notifier).onAppResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainTabIndexProvider);

    final List<Widget> screens = [
      const DashboardScreen(),
      const NutritionScreen(),
      const SportsScreen(),
      const TasksScreen(),
      const ProfileScreen(),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        children: [
          // Sayfa 0: Ana Uygulama (Alt Menülü)
          Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: IndexedStack(index: currentIndex, children: screens),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).bottomNavigationBarTheme.backgroundColor?.withValues(alpha: 0.9),
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GlobalActiveTaskBar(),
                  ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: BottomNavigationBar(
                        currentIndex: currentIndex,
                        onTap: (index) {
                          ref.read(mainTabIndexProvider.notifier).setIndex(index);
                        },
                        backgroundColor: Colors.transparent,
                        type: BottomNavigationBarType.fixed,
                        elevation: 0,
                        selectedItemColor: Theme.of(
                          context,
                        ).bottomNavigationBarTheme.selectedItemColor,
                        unselectedItemColor: Theme.of(
                          context,
                        ).bottomNavigationBarTheme.unselectedItemColor,
                        selectedFontSize: 12,
                        unselectedFontSize: 12,
                        items: const [
                          BottomNavigationBarItem(
                            icon: Icon(Icons.dashboard_rounded),
                            label: 'Özet',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.local_fire_department_rounded),
                            label: 'Beslenme',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.fitness_center_rounded),
                            label: 'Antrenman',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.check_circle_outline_rounded),
                            label: 'Görevler',
                          ),
                          BottomNavigationBarItem(
                            icon: Icon(Icons.person_rounded),
                            label: 'Profil',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Sayfa 1: Topluluk Ekranı
          const CommunityScreen(),
        ],
      ),
    );
  }
}
