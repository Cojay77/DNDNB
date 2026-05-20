import 'package:dndnb/models/update_banner.dart';
import 'package:dndnb/utils/platform_utils.dart';
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

    // Register/refresh token on app open
    if (user != null) {
      _authService.refreshTokenIfNeeded(user.uid);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  Color _stockColor(double stock) {
    switch (stock) {
      case >= 15:
        return Colors.green;
      case < 15 && >= 8:
        return Colors.orange;
      case < 8:
        return Colors.red;
      default:
        return const Color.fromARGB(0, 158, 158, 158);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = ref.watch(isAdminProvider);
    final homeMessage = ref.watch(homeMessageStreamProvider);
    final releaseNote = ref.watch(releaseNoteStreamProvider);
    final beerStock = ref.watch(beerStockStreamProvider);
    final upcomingContributions = ref.watch(upcomingBeerContributionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Accueil"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Bienvenue, ${displayName ?? 'utilisateur'} !"),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/sessions');
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text("Voir les sessions"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            isAdmin.when(
              data: (admin) => admin
                  ? ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/admin');
                      },
                      icon: const Icon(Icons.shield),
                      label: const Text("Espace Admin"),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              icon: const Icon(Icons.person),
              label: const Text("Mettre à jour le profil"),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Home message card — now realtime
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    homeMessage.when(
                      data: (msg) => Text(
                        msg,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (e, _) => Text(
                        "Erreur de chargement",
                        style: TextStyle(color: Colors.red.shade300),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Icon(
                      Icons.new_releases,
                      size: 30,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    releaseNote.when(
                      data: (note) => note.isEmpty
                          ? const SizedBox.shrink()
                          : Text(
                              note,
                              textAlign: TextAlign.left,
                              style: theme.textTheme.bodyMedium,
                            ),
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            // PWA install prompts
            if (kIsWeb && !isIOSBrowser() && !isAppInstalled()) ...[
              const InstallPromptButton(),
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

            // Beer stock gauge — now realtime
            beerStock.when(
              data: (stock) {
                final contributions = upcomingContributions.valueOrNull ?? 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          "🍻 Réserve + Apports",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Container(
                            height: 20,
                            width: double.infinity,
                            color: Colors.grey.shade800,
                          ),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (stock / 50).clamp(0.0, 1.0),
                            child: Container(
                              height: 20,
                              color: _stockColor(stock),
                            ),
                          ),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor:
                                ((stock + contributions) / 50).clamp(0.0, 1.0),
                            child: Container(
                              height: 20,
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          Center(
                            child: Text(
                              "${(stock + contributions).clamp(0, 50).toInt()} bières",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Stock actuel : ${stock.toInt()}  |  Apports prévus : $contributions",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Text(
                "Erreur chargement stock",
                style: TextStyle(color: Colors.red.shade300),
              ),
            ),

            const UpdateBanner(),
          ],
        ),
      ),
      bottomNavigationBar: BottomBar(),
    );
  }
}
