import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/game_session.dart';
import 'package:intl/intl.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseGameService _gameService = FirebaseGameService();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController titleController = TextEditingController();

  List<GameSession> sessions = [];
  bool loading = true;
  DateTime? selectedDate;

  double _beerStock = 1;
  final double _maxStock = 50;

  final TextEditingController dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadSessions();
    loadBeerStock();
  }

  Future<void> loadSessions() async {
    final data = await _gameService.fetchSessions();
    setState(() {
      sessions = data;
      loading = false;
    });
  }

  Future<void> createSession() async {
    final date = dateController.text.trim();
    final String sessionTitle = titleController.text.trim();
    if (date.isEmpty) return;

    await _gameService.createSession(date, _userId, sessionTitle);
    dateController.clear();
    await loadSessions();
  }

  Future<void> deleteSession(String sessionId) async {
    await _gameService.db.ref("sessions/$sessionId").remove();
    await loadSessions();
  }

  Future<void> archiveSession(GameSession session) async {
    await _gameService.archiveSession(session);
    await loadSessions();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Session archivée")));
  }

  String formatDate(DateTime date) {
    final formatter = DateFormat("EEEE d MMMM yyyy", "fr_FR");
    final raw = formatter.format(date);
    return raw[0].toUpperCase() + raw.substring(1);
  }

  Future<void> loadBeerStock() async {
    final snapshot = await FirebaseDatabase.instance.ref('beerStock').get();
    if (snapshot.exists) {
      setState(() {
        _beerStock = (snapshot.child('value').value ?? 60) as double;
      });
    }
  }

  Future<void> _updateBeerStock(double value) async {
    await FirebaseDatabase.instance.ref('beerStock').set({
      'value': value,
      'max': _maxStock,
      'lastUpdateBy': FirebaseAuth.instance.currentUser?.uid ?? 'unknown',
    });
    setState(() => _beerStock = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Administration")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Titre',
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  locale: const Locale('fr', 'FR'),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: Text(
                selectedDate != null
                    ? "📅 ${formatDate(selectedDate!)}"
                    : "Choisir une date",
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed:
                  selectedDate == null
                      ? null
                      : () async {
                        final formatted = formatDate(selectedDate!);
                        final sessionTitle = titleController.text.trim();
                        await _gameService.createSession(
                          formatted,
                          _userId,
                          sessionTitle,
                        );
                        setState(() {
                          selectedDate = null;
                        });
                        await loadSessions();
                      },
              child: const Text("Créer une session"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child:
                  loading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: sessions.length,
                        itemBuilder: (context, index) {
                          final session = sessions[index];
                          return Card(
                            child: ListTile(
                              title: Text("📅 ${session.date}"),
                              subtitle: Text("Titre : ${session.title}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.archive,
                                      color: Colors.orange,
                                    ),
                                    tooltip: "Archiver",
                                    onPressed: () => archiveSession(session),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: "Supprimer",
                                    onPressed: () => deleteSession(session.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin/notif');
              },
              child: const Text("Envoyer une notification"),
            ),
            const SizedBox(height: 20),
            Text("🧃 Réserve de bières (${_beerStock.toInt()} / $_maxStock)"),
            Slider(
              value: _beerStock,
              min: 0,
              max: _maxStock,
              divisions: 50,
              label: "${_beerStock.toInt()}",
              onChanged: (value) => setState(() => _beerStock = value),
              onChangeEnd: _updateBeerStock,
            ),
          ],
        ),
      ),
    );
  }
}
