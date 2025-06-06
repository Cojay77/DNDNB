import '../screens/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/game_sessions_screen.dart';
import 'screens/splash_screen.dart';
import 'package:dndnb/screens/send_notification_screen.dart';
import 'package:dndnb/screens/archived_sessions_screen.dart';

class DndApp extends StatefulWidget {
  final RouteObserver<PageRoute> routeObserver;
  const DndApp({super.key, required this.routeObserver});

  @override
  State<DndApp> createState() => _DndAppState();
}

class _DndAppState extends State<DndApp> {
  Widget? initialScreen;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      initialScreen = user != null ? const HomeScreen() : const LoginScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'D&D&B',
      navigatorObservers: [widget.routeObserver],
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        primarySwatch: Colors.deepOrange,
        fontFamily: 'UncialAntiqua',
        textTheme: ThemeData.dark().textTheme.copyWith(
          headlineMedium: TextStyle(fontFamily: 'UncialAntiqua'),
          titleLarge: TextStyle(fontFamily: 'UncialAntiqua'),
        ),
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF4500), // feu
          secondary: Color(0xFF8B0000),
          surface: Color(0xFF1E1E1E),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white70,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: Color(0xFF1E1E1E),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFF4500),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [Locale('fr', 'FR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: '/',
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
      home:
          initialScreen ??
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}
