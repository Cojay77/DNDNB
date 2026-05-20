import 'package:dndnb/utils/platform_utils.dart';
import 'package:dndnb/utils/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();

  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showError("Veuillez remplir email et mot de passe.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await _authService.login(email, password);
      if (user != null) {
        await _authService.registerToken(user.uid);
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError("Une erreur inattendue s'est produite.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final displayName = _displayNameCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showError("Veuillez remplir email et mot de passe.");
      return;
    }
    if (displayName.isEmpty) {
      _showError("Veuillez choisir un pseudo.");
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = await _authService.register(email, password, displayName);
      if (user != null) {
        await _authService.registerToken(user.uid);
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError("Une erreur inattendue s'est produite.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Gradient background ──────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A0000), Colors.black],
                stops: [0.0, 0.55],
              ),
            ),
          ),

          // ── Fire glow orb (top accent) ───────────────────────────────
          Positioned(
            top: -60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      DndColors.fire.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ─────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: DndSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: DndSpacing.xxl),

                  // Title
                  Text(
                    "D&D&B",
                    style: TextStyle(
                      fontFamily: 'UncialAntiqua',
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      color: DndColors.fire,
                      shadows: [
                        Shadow(
                          color: DndColors.fire.withValues(alpha: 0.6),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Dispo des Bros",
                    style: TextStyle(
                      fontFamily: 'UncialAntiqua',
                      fontSize: 14,
                      color: DndColors.onSurfaceMuted,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: DndSpacing.xxl),

                  // Card with tab switcher
                  Container(
                    decoration: BoxDecoration(
                      color: DndColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: DndColors.fire.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: DndColors.fire.withValues(alpha: 0.08),
                          blurRadius: 32,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Tab bar
                        Container(
                          margin: const EdgeInsets.all(DndSpacing.sm),
                          decoration: BoxDecoration(
                            color: DndColors.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              color: DndColors.fire,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelColor: Colors.white,
                            unselectedLabelColor: DndColors.onSurfaceMuted,
                            labelStyle: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                            tabs: const [
                              Tab(text: "Se connecter"),
                              Tab(text: "Créer un compte"),
                            ],
                          ),
                        ),

                        // Tab views
                        SizedBox(
                          height: 280,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _LoginForm(
                                emailCtrl: _emailCtrl,
                                passwordCtrl: _passwordCtrl,
                                obscurePassword: _obscurePassword,
                                isLoading: _isLoading,
                                onToggleObscure: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                onSubmit: _handleLogin,
                              ),
                              _SignUpForm(
                                emailCtrl: _emailCtrl,
                                passwordCtrl: _passwordCtrl,
                                displayNameCtrl: _displayNameCtrl,
                                obscurePassword: _obscurePassword,
                                isLoading: _isLoading,
                                onToggleObscure: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                                onSubmit: _handleSignUp,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DndSpacing.lg),

                  // iOS / PWA install banners
                  if (kIsWeb && !isIOSBrowser() && !isAppInstalled())
                    OutlinedButton.icon(
                      onPressed: promptInstall,
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text("Installer l'application"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DndColors.onSurfaceMuted,
                        side: BorderSide(
                            color: DndColors.fire.withValues(alpha: 0.4)),
                      ),
                    ),
                  if (kIsWeb && isIOSBrowser())
                    _IosHint(),
                  const SizedBox(height: DndSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Login form ───────────────────────────────────────────────────────────────

class _LoginForm extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _LoginForm({
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.obscurePassword,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DndSpacing.md, DndSpacing.sm, DndSpacing.md, DndSpacing.md),
      child: Column(
        children: [
          _EmailField(controller: emailCtrl),
          const SizedBox(height: DndSpacing.sm),
          _PasswordField(
            controller: passwordCtrl,
            obscure: obscurePassword,
            onToggle: onToggleObscure,
            onSubmitted: (_) => onSubmit(),
          ),
          const Spacer(),
          _SubmitButton(
            label: "Se connecter",
            icon: Icons.login,
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

// ─── Sign-up form ─────────────────────────────────────────────────────────────

class _SignUpForm extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController displayNameCtrl;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  const _SignUpForm({
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.displayNameCtrl,
    required this.obscurePassword,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DndSpacing.md, DndSpacing.sm, DndSpacing.md, DndSpacing.md),
      child: Column(
        children: [
          _EmailField(controller: emailCtrl),
          const SizedBox(height: DndSpacing.sm),
          _PasswordField(
            controller: passwordCtrl,
            obscure: obscurePassword,
            onToggle: onToggleObscure,
          ),
          const SizedBox(height: DndSpacing.sm),
          TextField(
            controller: displayNameCtrl,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
            decoration: const InputDecoration(
              labelText: "Pseudo",
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const Spacer(),
          _SubmitButton(
            label: "Créer mon compte",
            icon: Icons.person_add,
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

// ─── Shared field widgets ─────────────────────────────────────────────────────

class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  const _EmailField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      decoration: const InputDecoration(
        labelText: "Email",
        prefixIcon: Icon(Icons.mail_outline),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String>? onSubmitted;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction:
          onSubmitted != null ? TextInputAction.done : TextInputAction.next,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: "Mot de passe",
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              size: 20),
          onPressed: onToggle,
          tooltip: obscure ? "Afficher" : "Masquer",
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? const SizedBox(
              key: ValueKey('loading'),
              height: 48,
              width: 48,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          : SizedBox(
              key: const ValueKey('button'),
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 18),
                label: Text(label),
              ),
            ),
    );
  }
}

class _IosHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DndSpacing.md),
      decoration: BoxDecoration(
        color: DndColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DndColors.fire.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.ios_share, color: Colors.white70, size: 22),
          SizedBox(width: DndSpacing.md),
          Expanded(
            child: Text(
              "Pour installer sur iOS :\nBouton partage ↑ → \"Ajouter à l'écran d'accueil\"",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
