import 'package:dndnb/models/update_banner.dart';
import 'package:dndnb/widgets/bottom_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_session.dart';
import '../services/firebase_service.dart';

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

  int countAvailable(GameSession session) {
    return session.availability.values.where((v) => v == true).length;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmée':
        return Colors.green;
      case 'annulée':
        return Colors.red;
      case 'modifiée':
        return Colors.orange;
      default:
        return const Color.fromARGB(0, 158, 158, 158);
    }
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
                    return _SessionCard(
                      session: session,
                      userId: _userId,
                      beerController: beerController,
                      gameService: gameService,
                      usernameCache: usernameCache,
                      statusColor: _statusColor,
                      countAvailable: countAvailable,
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

/// Extracted session card widget for cleaner code
class _SessionCard extends StatelessWidget {
  final GameSession session;
  final String userId;
  final TextEditingController beerController;
  final FirebaseGameService gameService;
  final UsernameCacheNotifier usernameCache;
  final Color Function(String) statusColor;
  final int Function(GameSession) countAvailable;
  final ThemeData theme;

  const _SessionCard({
    required this.session,
    required this.userId,
    required this.beerController,
    required this.gameService,
    required this.usernameCache,
    required this.statusColor,
    required this.countAvailable,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final currentValue = session.availability[userId];

    return Stack(
      children: [
        Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: ExpansionTile(
            leading: const Icon(Icons.expand_more),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            title: Text(
              "📅 ${session.date.substring(0, session.date.length > 5 ? session.date.length - 5 : session.date.length)}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${countAvailable(session)} joueur(s) disponible(s)",
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            trailing: DropdownButton<bool?>(
              value: currentValue,
              icon: const Icon(Icons.arrow_drop_down),
              underline: Container(),
              items: const [
                DropdownMenuItem(
                  value: true,
                  child: Text("Présent"),
                ),
                DropdownMenuItem(
                  value: false,
                  child: Text("Absent"),
                ),
                DropdownMenuItem(
                  value: null,
                  child: Text("Non répondu"),
                ),
              ],
              onChanged: (value) async {
                await gameService.toggleAvailability(
                    session.id, userId, value!);
              },
            ),
            children: [
              // Beer contribution input
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: beerController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "🍺 Apport",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final input = beerController.text.trim();
                        final apport = int.tryParse(input);

                        if (apport == null || apport < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("❌ Nombre invalide"),
                            ),
                          );
                          return;
                        }

                        await gameService.setBeerContribution(
                          session.id,
                          userId,
                          apport,
                        );
                        beerController.clear();
                      },
                      icon: const Icon(Icons.check),
                      label: const Text("OK"),
                    ),
                  ],
                ),
              ),

              // Availability list
              _AvailabilityList(
                session: session,
                usernameCache: usernameCache,
              ),

              // Beer contributions list
              _BeerContributionsList(
                session: session,
                gameService: gameService,
              ),
            ],
          ),
        ),

        // Status badge
        if (statusColor(session.status) != const Color.fromARGB(0, 158, 158, 158))
          Positioned(
            right: -8,
            top: 20,
            child: Transform.rotate(
              angle: 0.8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                color: statusColor(session.status),
                child: Text(
                  session.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Extracted widget for the availability list inside a session card
class _AvailabilityList extends StatefulWidget {
  final GameSession session;
  final UsernameCacheNotifier usernameCache;

  const _AvailabilityList({
    required this.session,
    required this.usernameCache,
  });

  @override
  State<_AvailabilityList> createState() => _AvailabilityListState();
}

class _AvailabilityListState extends State<_AvailabilityList> {
  List<MapEntry<String, bool?>> _resolvedEntries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolveUsernames();
  }

  @override
  void didUpdateWidget(covariant _AvailabilityList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-resolve if session data changed
    if (oldWidget.session.availability != widget.session.availability) {
      _resolveUsernames();
    }
  }

  Future<void> _resolveUsernames() async {
    final entries = await Future.wait(
      widget.session.availability.entries.map((entry) async {
        final username =
            await widget.usernameCache.getUsername(entry.key);
        return MapEntry(username, entry.value as bool?);
      }),
    );

    if (mounted) {
      setState(() {
        _resolvedEntries = entries;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: CircularProgressIndicator(),
      );
    }

    final present =
        _resolvedEntries.where((e) => e.value == true).map((e) => e.key).toList();
    final absent =
        _resolvedEntries.where((e) => e.value == false).map((e) => e.key).toList();
    final unknown =
        _resolvedEntries.where((e) => e.value == null).map((e) => e.key).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (present.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "✅ Présents",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...present.map(
            (name) => ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(name),
            ),
          ),
        ],
        if (absent.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "❌ Absents",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...absent.map(
            (name) => ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: Text(name),
            ),
          ),
        ],
        if (unknown.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "❓ Sans réponse",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...unknown.map(
            (name) => ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.grey),
              title: Text(name),
            ),
          ),
        ],
      ],
    );
  }
}

/// Extracted widget for beer contributions display
class _BeerContributionsList extends StatelessWidget {
  final GameSession session;
  final FirebaseGameService gameService;

  const _BeerContributionsList({
    required this.session,
    required this.gameService,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: gameService.getBeerContributions(session),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final contributions = snapshot.data!;
        if (contributions.isEmpty ||
            contributions.values.fold(0, (p, c) => p + c) < 1) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Personne n'a indiqué apporter des bières."),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("🍻 Contributions :"),
              ...contributions.entries.map(
                (entry) => FutureBuilder<String>(
                  future: gameService.getUserName(entry.key),
                  builder: (context, nameSnap) {
                    if (!nameSnap.hasData || entry.value < 1) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      "${nameSnap.data} : + ${entry.value} 🍺",
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
