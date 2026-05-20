import 'package:dndnb/widgets/update_banner.dart';
import 'package:dndnb/widgets/bottom_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../widgets/session_card.dart';

class GameSessionsScreen extends ConsumerStatefulWidget {
  const GameSessionsScreen({super.key});

  @override
  ConsumerState<GameSessionsScreen> createState() =>
      _GameSessionsScreenState();
}

class _GameSessionsScreenState extends ConsumerState<GameSessionsScreen> {
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController beerController = TextEditingController();

  @override
  void dispose() {
    beerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessionsAsync = ref.watch(sessionsStreamProvider);
    final gameService = ref.read(gameServiceProvider);
    final usernameCache = ref.read(usernameCacheProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text("Sessions de jeu")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/sessions/archived');
        },
        label: const Text("Historique"),
        icon: const Icon(Icons.history),
      ),
      body: Column(
        children: [
          const UpdateBanner(),
          Expanded(
            child: sessionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade300, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      "Erreur de chargement des sessions",
                      style: TextStyle(color: Colors.red.shade300),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(sessionsStreamProvider),
                      child: const Text("Réessayer"),
                    ),
                  ],
                ),
              ),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const Center(
                    child: Text(
                      "Aucune session prévue pour le moment.",
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return SessionCard(
                      session: session,
                      userId: _userId,
                      beerController: beerController,
                      gameService: gameService,
                      usernameCache: usernameCache,
                      theme: theme,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(),
    );
  }
}


