import 'package:dndnb/models/update_banner.dart';
import 'package:dndnb/utils/share_ics.dart';
import 'package:dndnb/widgets/bottom_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_session.dart';
import '../services/firebase_service.dart';
import '../utils/ics_generator.dart';

class GameSessionsScreen extends StatefulWidget {
  const GameSessionsScreen({super.key});

  @override
  State<GameSessionsScreen> createState() => _GameSessionsScreenState();
}

class _GameSessionsScreenState extends State<GameSessionsScreen> {
  final FirebaseGameService _gameService = FirebaseGameService();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;

  List<GameSession> sessions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadSessions();
  }

  Future<void> loadSessions() async {
    final data = await _gameService.fetchSessions();
    setState(() {
      sessions = data;
      loading = false;
    });
  }

  Future<void> toggleAvailability(GameSession session, bool value) async {
    await _gameService.toggleAvailability(session.id, _userId, value);
    await loadSessions(); // recharge les données après changement
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
          const UpdateBanner(), // Bannière de mise à jour
          Expanded(
            child:
                loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
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
                                  "📅 ${session.date}",
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
                                trailing: Switch(
                                  value: session.availability[_userId] ?? false,
                                  onChanged:
                                      (val) => toggleAvailability(session, val),
                                ),
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.local_drink),
                                      const SizedBox(width: 8),
                                      const Text("J’apporte :"),
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 50,
                                        child: TextFormField(
                                          initialValue:
                                              session.beerContributions[_userId]
                                                  ?.toString() ??
                                              '',
                                          keyboardType: TextInputType.number,
                                          onFieldSubmitted: (value) async {
                                            final quantity =
                                                int.tryParse(value) ?? 0;
                                            if (quantity < 0) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "❌ Le nombre de bières ne peut pas être négatif.",
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            await _gameService
                                                .setBeerContribution(
                                                  session.id,
                                                  _userId,
                                                  quantity,
                                                );
                                            await loadSessions();
                                          },
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 6,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  //BOUTON MASQUÉ
                                  if (true == false)
                                    ListTile(
                                      title: Text(
                                        "Ajouter au calendrier",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      leading: Icon(
                                        Icons.calendar_today,
                                        color: theme.colorScheme.primary,
                                      ),
                                      onTap: () {
                                        final content = generateICSContent(
                                          title: session.title,
                                          description: "Session D&D&B",
                                          start: session.parsedDate,
                                          end: session.parsedDate.add(
                                            const Duration(hours: 3),
                                          ),
                                        );
                                        shareICSFile(
                                          context,
                                          "session.ics",
                                          content,
                                        );
                                      },
                                    ),
                                  FutureBuilder<List<String>>(
                                    future: _gameService
                                        .getAvailablePlayerNames(session),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: CircularProgressIndicator(),
                                        );
                                      }
                                      final players = snapshot.data ?? [];
                                      if (players.isEmpty) {
                                        return const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Text(
                                            "Aucun joueur disponible",
                                          ),
                                        );
                                      }
                                      return Column(
                                        children:
                                            players
                                                .map(
                                                  (username) => ListTile(
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                        ),
                                                    dense: true,
                                                    leading: const Icon(
                                                      Icons.person,
                                                    ),
                                                    title: Text(username),
                                                  ),
                                                )
                                                .toList(),
                                      );
                                    },
                                  ),
                                  FutureBuilder<Map<String, int>>(
                                    future: _gameService.getBeerContributions(
                                      session,
                                    ),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const SizedBox.shrink();
                                      }

                                      final contributions = snapshot.data!;
                                      if (contributions.isEmpty ||
                                          contributions.values.fold(
                                                0,
                                                (p, c) => p + c,
                                              ) <
                                              1) {
                                        return const Text(
                                          "Personne n’a indiqué apporter des bières.",
                                        );
                                      }

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text("🍻 Contributions :"),
                                          ...contributions.entries.map(
                                            (entry) => FutureBuilder<String>(
                                              future: _gameService.getUserName(
                                                entry.key,
                                              ),
                                              builder: (context, nameSnap) {
                                                if (!nameSnap.hasData ||
                                                    entry.value < 1) {
                                                  return const SizedBox.shrink();
                                                }
                                                return Text(
                                                  "${nameSnap.data} : + ${entry.value} 🍺",
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
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
                                  color: _statusColor(session.status),
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
                      },
                    ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(),
    );
  }
}
