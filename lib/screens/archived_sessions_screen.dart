import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/game_session.dart';

class ArchivedSessionsScreen extends StatefulWidget {
  const ArchivedSessionsScreen({super.key});

  @override
  State<ArchivedSessionsScreen> createState() => _ArchivedSessionsScreenState();
}

class _ArchivedSessionsScreenState extends State<ArchivedSessionsScreen> {
  final FirebaseGameService _firebaseService = FirebaseGameService();
  List<GameSession> _archivedSessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadArchivedSessions();
  }

  Future<void> _loadArchivedSessions() async {
    final sessions = await _firebaseService.fetchArchivedSessions();
    sessions.sort(
      (a, b) => b.parsedDate.compareTo(a.parsedDate),
    ); // tri du plus récent au plus ancien
    setState(() {
      _archivedSessions = sessions;
      _loading = false;
    });
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
    return Scaffold(
      appBar: AppBar(title: const Text("Historique des sessions")),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _archivedSessions.isEmpty
              ? const Center(child: Text("Aucune session archivée."))
              : ListView.builder(
                itemCount: _archivedSessions.length,
                itemBuilder: (context, index) {
                  final session = _archivedSessions[index];
                  final availableCount =
                      session.availability.values
                          .where((v) => v == true)
                          .length;

                  return Stack(
                    children: [
                      Card(
                        color: Colors.grey.shade900,
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 8.0,
                          ),
                          child: ListTile(
                            title: Text(
                              session.date,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  session.title,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "$availableCount joueur(s) étaient dispo",
                                  style: const TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
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
    );
  }
}
