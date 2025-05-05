import 'package:dndnb/models/update_banner.dart';
import 'package:dndnb/widgets/bottom_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/game_session.dart';
import '../services/firebase_service.dart';
import 'package:share_plus/share_plus.dart';
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
                                    onTap: () async {
                                      final file = await generateICSFile(
                                        title: "Session D&D : ${session.title}",
                                        description:
                                            "Confirmée avec ${session.availability.length} joueurs.",
                                        start: session.parsedDate,
                                        end: session.parsedDate.add(
                                          const Duration(hours: 3),
                                        ),
                                      );

                                      await Share.shareXFiles(
                                        [XFile(file.path)],
                                        text:
                                            "Ajoute cette session à ton calendrier !",
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
