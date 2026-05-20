import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firebase_service.dart';
import '../models/game_session.dart';
import '../utils/theme.dart';
import '../widgets/status_badge.dart';
import 'package:intl/intl.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _titleController = TextEditingController();

  DateTime? _selectedDate;
  double _beerStock = 0;
  static const double _maxStock = 50;

  static const _statusOptions = ['prévue', 'confirmée', 'modifiée', 'annulée'];

  @override
  void initState() {
    super.initState();
    _loadBeerStock();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final raw = DateFormat("EEEE d MMMM yyyy", "fr_FR").format(date);
    return raw[0].toUpperCase() + raw.substring(1);
  }

  Future<void> _loadBeerStock() async {
    final snapshot =
        await FirebaseDatabase.instance.ref('beerStock').get();
    if (snapshot.exists && mounted) {
      setState(() {
        _beerStock =
            ((snapshot.child('value').value ?? 0) as num).toDouble();
      });
    }
  }

  Future<void> _updateBeerStock(double value) async {
    await FirebaseDatabase.instance.ref('beerStock').set({
      'value': value,
      'max': _maxStock,
      'lastUpdateBy': _userId,
    });
    setState(() => _beerStock = value);
  }

  Future<void> _createSession() async {
    if (_selectedDate == null) return;
    final gameService = ref.read(gameServiceProvider);
    await gameService.createSession(
      _formatDate(_selectedDate!),
      _userId,
      _titleController.text.trim(),
    );
    setState(() => _selectedDate = null);
    _titleController.clear();
  }

  Future<void> _archiveSession(GameSession session) async {
    final gameService = ref.read(gameServiceProvider);
    await gameService.archiveSession(session);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.archive_outlined,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text("\"${session.title.isNotEmpty ? session.title : session.date}\" archivée"),
            ],
          ),
          action: SnackBarAction(
            label: "OK",
            textColor: DndColors.amber,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    // Confirm before delete
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer la session ?"),
        content: const Text("Cette action est irréversible."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(gameServiceProvider).db.ref("sessions/$sessionId").remove();
    }
  }

  Future<void> _updateStatus(String sessionId, String status) async {
    await ref.read(gameServiceProvider).updateSessionStatus(sessionId, status);
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Administration")),
      body: Padding(
        padding: const EdgeInsets.all(DndSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Session creation ──
            Text("Créer une session",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: DndSpacing.sm),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre (optionnel)'),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: DndSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                        locale: const Locale('fr', 'FR'),
                      );
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      _selectedDate != null
                          ? _formatDate(_selectedDate!)
                          : "Choisir une date",
                    ),
                  ),
                ),
                const SizedBox(width: DndSpacing.sm),
                ElevatedButton(
                  onPressed: _selectedDate == null ? null : _createSession,
                  child: const Text("Créer"),
                ),
              ],
            ),
            const SizedBox(height: DndSpacing.lg),
            const Divider(),
            const SizedBox(height: DndSpacing.sm),

            // ── Sessions list ──
            Text("Sessions actives",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: DndSpacing.sm),
            Expanded(
              child: sessionsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text("Erreur : $e",
                      style: TextStyle(color: Colors.red.shade300)),
                ),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return Center(
                      child: Text("Aucune session active.",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium),
                    );
                  }
                  return ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, i) => _SessionAdminTile(
                      session: sessions[i],
                      statusOptions: _statusOptions,
                      onArchive: () => _archiveSession(sessions[i]),
                      onDelete: () => _deleteSession(sessions[i].id),
                      onStatusChanged: (s) =>
                          _updateStatus(sessions[i].id, s),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            const SizedBox(height: DndSpacing.sm),

            // ── Notification button ──
            ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/admin/notif'),
              icon: const Icon(Icons.tune),
              label: const Text("Gérer le contenu & notifications"),
            ),
            const SizedBox(height: DndSpacing.md),

            // ── Beer stock slider ──
            Row(
              children: [
                const Text("🍺"),
                const SizedBox(width: DndSpacing.sm),
                Text(
                  "Stock : ${_beerStock.toInt()} / ${_maxStock.toInt()} bières",
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            Slider(
              value: _beerStock,
              min: 0,
              max: _maxStock,
              divisions: 50,
              label: "${_beerStock.toInt()}",
              activeColor: DndColors.fire,
              onChanged: (v) => setState(() => _beerStock = v),
              onChangeEnd: _updateBeerStock,
            ),
            const SizedBox(height: DndSpacing.sm),
          ],
        ),
      ),
    );
  }
}

// ─── Session admin tile ───────────────────────────────────────────────────────

class _SessionAdminTile extends StatelessWidget {
  final GameSession session;
  final List<String> statusOptions;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final ValueChanged<String> onStatusChanged;

  const _SessionAdminTile({
    required this.session,
    required this.statusOptions,
    required this.onArchive,
    required this.onDelete,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = statusOptions.contains(session.status.toLowerCase())
        ? session.status.toLowerCase()
        : 'prévue';

    return Card(
      margin: const EdgeInsets.only(bottom: DndSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DndSpacing.md,
          vertical: DndSpacing.sm,
        ),
        child: Row(
          children: [
            // Date + title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.date,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (session.title.isNotEmpty)
                    Text(
                      session.title,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: DndSpacing.xs),
                  // Status buttons row
                  Wrap(
                    spacing: DndSpacing.xs,
                    children: statusOptions.map((s) {
                      final isSelected =
                          normalizedStatus == s;
                      final rawColor = StatusBadge.colorFor(s);
                      final color = rawColor == Colors.transparent
                          ? DndColors.onSurfaceMuted
                          : rawColor;
                      return GestureDetector(
                        onTap: () => onStatusChanged(s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.85)
                                : color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(
                                  alpha: isSelected ? 0.9 : 0.35),
                            ),
                          ),
                          child: Text(
                            s[0].toUpperCase() + s.substring(1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Colors.white
                                  : color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            // Actions
            IconButton(
              icon: const Icon(Icons.archive_outlined,
                  color: Colors.orange, size: 22),
              tooltip: "Archiver",
              onPressed: onArchive,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.red, size: 22),
              tooltip: "Supprimer",
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return StatusBadge.colorFor(status);
  }
}
