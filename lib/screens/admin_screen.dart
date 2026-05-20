import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../models/game_session.dart';
import 'package:intl/intl.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController titleController = TextEditingController();

  DateTime? selectedDate;

  double _beerStock = 1;
  final double _maxStock = 50;

  final TextEditingController dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadBeerStock();
  }

  @override
  void dispose() {
    titleController.dispose();
    dateController.dispose();
    super.dispose();
  }

  Future<void> deleteSession(String sessionId) async {
    final gameService = ref.read(gameServiceProvider);
    await gameService.db.ref("sessions/$sessionId").remove();
  }

  Future<void> archiveSession(GameSession session) async {
    final gameService = ref.read(gameServiceProvider);
    await gameService.archiveSession(session);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Session archivée")));
    }
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

  Future<void> _updateSessionStatus(
      String sessionId, String newStatus) async {
    final gameService = ref.read(gameServiceProvider);
    await gameService.updateSessionStatus(sessionId, newStatus);
  }

  static const _statusOptions = ['prévue', 'confirmée', 'modifiée', 'annulée'];

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsStreamProvider);
    final gameService = ref.read(gameServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Administration")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Session creation form
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Titre',
              ),
            ),
            const SizedBox(height: 8),
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
              onPressed: selectedDate == null
                  ? null
                  : () async {
                      // Save using ISO 8601 format!
                      final isoDate = selectedDate!.toIso8601String();
                      final sessionTitle = titleController.text.trim();
                      await gameService.createSession(
                        isoDate,
                        _userId,
                        sessionTitle,
                      );
                      setState(() {
                        selectedDate = null;
                      });
                      titleController.clear();
                    },
              child: const Text("Créer une session"),
            ),
            const SizedBox(height: 20),

            // Sessions list — now realtime
            Expanded(
              child: sessionsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text("Erreur: $e",
                      style: TextStyle(color: Colors.red.shade300)),
                ),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return const Center(
                      child: Text("Aucune session active."),
                    );
                  }

                  return ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return Card(
                        child: ListTile(
                          title: Text("📅 ${session.displayDate}"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Titre : ${session.title}"),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text("Statut : ",
                                      style: TextStyle(fontSize: 12)),
                                  DropdownButton<String>(
                                    value: _statusOptions
                                            .contains(session.status.toLowerCase())
                                        ? session.status.toLowerCase()
                                        : 'prévue',
                                    items: _statusOptions.map((s) {
                                      return DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          s[0].toUpperCase() + s.substring(1),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        _updateSessionStatus(
                                            session.id, value);
                                      }
                                    },
                                    underline: const SizedBox.shrink(),
                                    isDense: true,
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                                onPressed: () =>
                                    deleteSession(session.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
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
