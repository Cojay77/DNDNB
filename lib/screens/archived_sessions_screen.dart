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

                  return Card(
                    color: Colors.grey.shade900,
                    margin: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: ListTile(
                      title: Text(
                        session.date,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                  );
                },
              ),
    );
  }
}
