import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'utils/theme.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/game_sessions_screen.dart';
import 'screens/splash_screen.dart';
import 'package:dndnb/screens/send_notification_screen.dart';
import 'package:dndnb/screens/archived_sessions_screen.dart';
import 'services/auth_service.dart';

class DndApp extends ConsumerWidget {
  final RouteObserver<PageRoute> routeObserver;
  const DndApp({super.key, required this.routeObserver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'D&D&B',
      navigatorObservers: [routeObserver],
      themeMode: ThemeMode.dark,
      darkTheme: DndTheme.dark,
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminScreen(),
        '/sessions': (context) => const GameSessionsScreen(),
        '/splash': (context) => const SplashScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/admin/notif': (context) => const SendNotificationScreen(),
        '/sessions/archived': (context) => const ArchivedSessionsScreen(),
      },
      home: authState.when(
        data: (user) =>
            user != null ? const HomeScreen() : const LoginScreen(),
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const LoginScreen(),
      ),
    );
  }
}
