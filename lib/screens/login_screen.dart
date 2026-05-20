import 'package:dndnb/utils/platform_utils.dart';
import 'package:dndnb/widgets/bottom_bar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController displayNameController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    displayNameController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Veuillez remplir tous les champs.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(email, password);

      if (user != null) {
        await _authService.registerToken(user.uid);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError("Une erreur inattendue s'est produite.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> handleSignUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final displayName = displayNameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Veuillez remplir email et mot de passe.");
      return;
    }

    if (displayName.isEmpty) {
      _showError("Veuillez entrer un pseudo pour créer un compte.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.register(email, password, displayName);

      if (user != null) {
        await _authService.registerToken(user.uid);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError("Une erreur inattendue s'est produite.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Connexion", style: TextStyle(fontSize: 24)),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Pseudo (si tu crées un compte)',
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => handleLogin(),
                ),
                const SizedBox(height: 20),
                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  ElevatedButton(
                    onPressed: handleLogin,
                    child: const Text("Se connecter"),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: handleSignUp,
                    child: const Text("Créer un compte"),
                  ),
                ],
                if (kIsWeb && !isIOSBrowser() && !isAppInstalled()) ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => promptInstall(),
                    child: const Text("Installer l'application"),
                  ),
                ],
                if (kIsWeb && isIOSBrowser()) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.ios_share, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Pour installer l'application :\nAppuyez sur "
                              "le bouton de partage (en bas de l'écran), "
                              "puis \"Ajouter à l'écran d'accueil\".",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomBar(),
    );
  }
}
