import 'package:dndnb/widgets/beer_stock_gauge.dart';
import 'package:dndnb/widgets/next_session_card.dart';
import 'package:dndnb/widgets/update_banner.dart';
import 'package:dndnb/utils/platform_utils.dart';
import 'package:dndnb/utils/theme.dart';
import 'package:dndnb/widgets/bottom_bar_widget.dart';
import 'package:dndnb/widgets/install_prompt_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../main.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with RouteAware {
  final AuthService _authService = AuthService();
  String? displayName;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    displayName = user?.displayName;
    if (user != null) _authService.refreshTokenIfNeeded(user.uid);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);
    final homeMessage = ref.watch(homeMessageStreamProvider);
    final releaseNote = ref.watch(releaseNoteStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Accueil"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Se déconnecter",
            onPressed: () async {
              await _authService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DndSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome
            Text(
              "Bienvenue, ${displayName ?? 'aventurier'} !",
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DndSpacing.md),

            // Next session hero card
            const NextSessionCard(),
            const SizedBox(height: DndSpacing.lg),

            // Navigation buttons
            _NavButton(
              icon: Icons.casino,
              label: "Voir les sessions",
              onTap: () => Navigator.pushNamed(context, '/sessions'),
            ),
            const SizedBox(height: DndSpacing.sm),
            isAdmin.when(
              data: (admin) => admin
                  ? _NavButton(
                      icon: Icons.shield,
                      label: "Espace Admin",
                      onTap: () => Navigator.pushNamed(context, '/admin'),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: DndSpacing.sm),
            _NavButton(
              icon: Icons.person,
              label: "Mon profil",
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            const SizedBox(height: DndSpacing.lg),

            // Message du MJ card
            _HomeMessageCard(
              homeMessage: homeMessage,
              releaseNote: releaseNote,
            ),
            const SizedBox(height: DndSpacing.lg),

            // Beer stock gauge (self-contained, reads its own providers)
            const BeerStockGauge(),
            const SizedBox(height: DndSpacing.lg),

            // PWA install prompts (web only)
            if (kIsWeb && !isIOSBrowser() && !isAppInstalled()) ...[
              const InstallPromptButton(),
              const SizedBox(height: DndSpacing.sm),
            ],
            if (kIsWeb && isIOSBrowser()) ...[
              const _IosInstallBanner(),
              const SizedBox(height: DndSpacing.sm),
            ],

            // Update notice
            const UpdateBanner(),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}

class _HomeMessageCard extends StatelessWidget {
  final AsyncValue<String> homeMessage;
  final AsyncValue<String> releaseNote;

  const _HomeMessageCard({
    required this.homeMessage,
    required this.releaseNote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DndSpacing.md),
        child: Column(
          children: [
            Icon(
              Icons.auto_stories,
              size: 28,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: DndSpacing.sm),
            homeMessage.when(
              data: (msg) => Text(
                msg,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              loading: () => const CircularProgressIndicator(strokeWidth: 2),
              error: (_, __) => Text(
                "Impossible de charger le message.",
                style: TextStyle(color: Colors.red.shade300, fontSize: 13),
              ),
            ),
            releaseNote.when(
              data: (note) => note.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        const Divider(height: DndSpacing.lg),
                        Row(
                          children: [
                            Icon(Icons.new_releases,
                                size: 18,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: DndSpacing.sm),
                            Text(
                              "Nouveautés",
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: DndSpacing.sm),
                        Text(note,
                            style: theme.textTheme.bodyMedium),
                      ],
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _IosInstallBanner extends StatelessWidget {
  const _IosInstallBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DndColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DndColors.fire.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(DndSpacing.md),
      child: const Row(
        children: [
          Icon(Icons.ios_share, color: Colors.white70, size: 26),
          SizedBox(width: DndSpacing.md),
          Expanded(
            child: Text(
              "Pour installer l'app sur iOS :\nAppuyez sur le bouton partage ↑ puis \"Ajouter à l'écran d'accueil\".",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
