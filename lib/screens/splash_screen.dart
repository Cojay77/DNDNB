import 'package:dndnb/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _redirect();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _redirect() async {
    // Wait for animation + minimum display time
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    // Use the Riverpod auth state instead of direct Firebase call
    final authState = ref.read(authStateProvider);
    authState.whenData((user) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        user != null ? '/home' : '/login',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fire glow background
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      DndColors.fire.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Logo + title centred
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Emblem glow ring
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DndColors.surface,
                        border: Border.all(
                          color: DndColors.fire.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: DndColors.fire.withValues(alpha: 0.4),
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          "⚔️",
                          style: TextStyle(fontSize: 46),
                        ),
                      ),
                    ),
                    const SizedBox(height: DndSpacing.lg),
                    Text(
                      "D&D&B",
                      style: TextStyle(
                        fontFamily: 'UncialAntiqua',
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: DndColors.fire,
                        shadows: [
                          Shadow(
                            color: DndColors.fire.withValues(alpha: 0.7),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DndSpacing.xs),
                    Text(
                      "Dispo des Bros",
                      style: TextStyle(
                        fontFamily: 'UncialAntiqua',
                        fontSize: 13,
                        color: DndColors.onSurfaceMuted,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: DndSpacing.xxl),
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: DndColors.fire.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
