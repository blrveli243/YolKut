import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/auth_provider.dart';
import 'main_screen.dart';
import 'core/theme/app_theme_provider.dart';

import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(
    const ProviderScope(
      child: HealthApp(),
    ),
  );
}

class HealthApp extends ConsumerWidget {
  const HealthApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authCheck = ref.watch(authCheckProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Health App',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: authCheck.when(
        data: (isLoggedIn) => isLoggedIn ? const MainScreen() : const LoginScreen(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}
