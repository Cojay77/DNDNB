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
  final TextEditingController beerController = TextEditingController();

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
                        final currentValue = session.availability[_userId];
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
                                  "📅 ${session.date.substring(0, session.date.length - 5)}",
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
                                  onChanged:
                                      (value) =>
                                          toggleAvailability(session, value!),
                                ),
                                children: [
                                  Row(
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
                                          final input =
                                              beerController.text.trim();
                                          final apport = int.tryParse(input);

                                          if (apport == null || apport < 0) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "❌ Nombre invalide",
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          await _gameService
                                              .setBeerContribution(
                                                session.id,
                                                _userId,
                                                apport,
                                              );

                                          await loadSessions();
                                          beerController.clear();
                                        },
                                        icon: const Icon(Icons.check),
                                        label: const Text("OK"),
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
                                  FutureBuilder<Map<String, bool?>>(
                                    future: _gameService.getAllAvailability(
                                      session,
                                    ),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Padding(
                                          padding: EdgeInsets.all(8),
                                          child: CircularProgressIndicator(),
                                        );
                                      }

                                      final availabilityMap =
                                          snapshot.data ?? {};

                                      // On crée une Future<List<MapEntry<String, String>>> où chaque entrée contient le pseudo et le statut
                                      return FutureBuilder<
                                        List<MapEntry<String, bool?>>
                                      >(
                                        future: Future.wait(
                                          availabilityMap.entries.map((
                                            entry,
                                          ) async {
                                            final username = await _gameService
                                                .getUsernameById(entry.key);
                                            return MapEntry(
                                              username,
                                              entry.value,
                                            );
                                          }),
                                        ),
                                        builder: (context, userSnapshot) {
                                          if (userSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Padding(
                                              padding: EdgeInsets.all(8),
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          }

                                          final entries =
                                              userSnapshot.data ?? [];
                                          final present =
                                              entries
                                                  .where((e) => e.value == true)
                                                  .map((e) => e.key)
                                                  .toList();
                                          final absent =
                                              entries
                                                  .where(
                                                    (e) => e.value == false,
                                                  )
                                                  .map((e) => e.key)
                                                  .toList();
                                          final unknown =
                                              entries
                                                  .where((e) => e.value == null)
                                                  .map((e) => e.key)
                                                  .toList();

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (present.isNotEmpty) ...[
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                                  child: Text(
                                                    "✅ Présents",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                ...present.map(
                                                  (name) => ListTile(
                                                    leading: const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                    ),
                                                    title: Text(name),
                                                  ),
                                                ),
                                              ],
                                              if (absent.isNotEmpty) ...[
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                                  child: Text(
                                                    "❌ Absents",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                ...absent.map(
                                                  (name) => ListTile(
                                                    leading: const Icon(
                                                      Icons.cancel,
                                                      color: Colors.red,
                                                    ),
                                                    title: Text(name),
                                                  ),
                                                ),
                                              ],
                                              if (unknown.isNotEmpty) ...[
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                                  child: Text(
                                                    "❓ Sans réponse",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                ...unknown.map(
                                                  (name) => ListTile(
                                                    leading: const Icon(
                                                      Icons.help_outline,
                                                      color: Colors.grey,
                                                    ),
                                                    title: Text(name),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          );
                                        },
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
