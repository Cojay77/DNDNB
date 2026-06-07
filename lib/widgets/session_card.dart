import 'package:dndnb/utils/date_utils.dart' as date_utils;
import 'package:dndnb/utils/ics_generator.dart';
import 'package:dndnb/utils/share_ics.dart';
import 'package:dndnb/utils/theme.dart';
import 'package:dndnb/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_session.dart';
import '../services/firebase_service.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Color sessionStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'confirmée':
      return Colors.green;
    case 'annulée':
      return Colors.red;
    case 'modifiée':
      return Colors.orange;
    default:
      return Colors.transparent;
  }
}

int countAvailablePlayers(GameSession session) =>
    session.availability.values.where((v) => v == true).length;

// ─── SessionCard ──────────────────────────────────────────────────────────────

/// A card showing a single session with availability toggle, beer input,
/// ICS export, availability list, and beer contributions list.
class SessionCard extends ConsumerStatefulWidget {
  final GameSession session;
  final String userId;
  /// When true, an edit button for MJ notes is shown
  final bool isAdmin;

  const SessionCard({
    super.key,
    required this.session,
    required this.userId,
    this.isAdmin = false,
  });

  @override
  ConsumerState<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends ConsumerState<SessionCard> {
  final TextEditingController _beerController = TextEditingController();

  @override
  void dispose() {
    _beerController.dispose();
    super.dispose();
  }

  Future<void> _exportIcs() async {
    final session = widget.session;
    final dt = date_utils.parseSessionDate(session.date);
    if (dt == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Impossible de lire la date de la session.")),
        );
      }
      return;
    }
    final title = session.title.isNotEmpty
        ? "D&D&B — ${session.title}"
        : "D&D&B — Session";

    final ics = generateICSContent(
      title: title,
      description: "Session D&D — ${session.date}",
      start: dt,
      end: dt.add(const Duration(hours: 4)),
    );

    final fileName =
        "session_${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}.ics";

    if (mounted) await shareICSFile(context, fileName, ics);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final userId = widget.userId;
    final gameService = ref.read(gameServiceProvider);
    final usernameCache = ref.read(usernameCacheProvider.notifier);
    final currentAvailability = session.availability[userId];
    final playerCount = countAvailablePlayers(session);
    final countdown = date_utils.sessionCountdown(session.date);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          margin: const EdgeInsets.symmetric(
              horizontal: DndSpacing.md, vertical: 10),
          child: ExpansionTile(
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.calendar_month_outlined),
                if (session.notes.isNotEmpty)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: DndColors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: DndColors.card, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tilePadding: const EdgeInsets.symmetric(
                horizontal: DndSpacing.md, vertical: 10),
            title: Text(
              _shortDate(session.date),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (session.title.isNotEmpty)
                  Text(
                    session.title,
                    style: const TextStyle(
                        fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                if (countdown.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: DndColors.fire.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: DndColors.fire.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      countdown,
                      style: TextStyle(
                        fontSize: 10,
                        color: DndColors.fire,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  "$playerCount joueur${playerCount > 1 ? 's' : ''} dispo",
                  style: TextStyle(
                    fontSize: 12,
                    color: playerCount > 0
                        ? Colors.green.shade300
                        : Colors.grey,
                  ),
                ),
              ],
            ),
            trailing: _AvailabilityDropdown(
              value: currentAvailability,
              onChanged: (value) async {
                if (value == null) return;
                await gameService.toggleAvailability(
                    session.id, userId, value);
              },
            ),
            children: [
              const Divider(height: 1, indent: 16, endIndent: 16),

              // ICS export action row
              _IcsExportRow(onExport: _exportIcs),

              _BeerInputRow(
                controller: _beerController,
                onConfirm: () async {
                  final amount =
                      int.tryParse(_beerController.text.trim());
                  if (amount == null || amount < 0) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Nombre invalide")),
                      );
                    }
                    return;
                  }
                  await gameService.setBeerContribution(
                      session.id, userId, amount);
                  _beerController.clear();
                },
              ),
              AvailabilityList(
                session: session,
                usernameCache: usernameCache,
              ),
              BeerContributionsList(
                session: session,
                gameService: gameService,
              ),
              // MJ Notes
              if (session.notes.isNotEmpty || widget.isAdmin)
                _NotesSection(
                  session: session,
                  gameService: gameService,
                  isAdmin: widget.isAdmin,
                ),
              const SizedBox(height: DndSpacing.sm),
            ],
          ),
        ),

        // Status ribbon badge — now uses StatusBadge widget
        Positioned(
          right: DndSpacing.sm,
          top: 0,
          child: StatusBadge(status: session.status),
        ),
      ],
    );
  }

  String _shortDate(String date) {
    if (date.length > 5) {
      return date.substring(0, date.length - 5);
    }
    return date;
  }
}

// ─── ICS Export Row ───────────────────────────────────────────────────────────

class _IcsExportRow extends StatelessWidget {
  final VoidCallback onExport;
  const _IcsExportRow({required this.onExport});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DndSpacing.md, DndSpacing.sm, DndSpacing.md, 0),
      child: Row(
        children: [
          Icon(Icons.calendar_today,
              size: 14, color: DndColors.onSurfaceMuted),
          const SizedBox(width: DndSpacing.sm),
          Text(
            "Ajouter au calendrier",
            style: TextStyle(
                fontSize: 12, color: DndColors.onSurfaceMuted),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onExport,
            icon: const Icon(Icons.download, size: 16),
            label: const Text("Exporter .ics"),
            style: TextButton.styleFrom(
              foregroundColor: DndColors.ember,
              padding: const EdgeInsets.symmetric(
                  horizontal: DndSpacing.sm, vertical: DndSpacing.xs),
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AvailabilityDropdown ─────────────────────────────────────────────────────

class _AvailabilityDropdown extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool?> onChanged;

  const _AvailabilityDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<bool?>(
      value: value,
      icon: const Icon(Icons.arrow_drop_down),
      underline: const SizedBox.shrink(),
      isDense: true,
      items: const [
        DropdownMenuItem(value: true, child: Text("✅ Présent")),
        DropdownMenuItem(value: false, child: Text("❌ Absent")),
        DropdownMenuItem(value: null, child: Text("❓ Non répondu")),
      ],
      onChanged: onChanged,
    );
  }
}

// ─── BeerInputRow ─────────────────────────────────────────────────────────────

class _BeerInputRow extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onConfirm;

  const _BeerInputRow({required this.controller, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DndSpacing.md, DndSpacing.md, DndSpacing.md, DndSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onConfirm(),
              decoration: const InputDecoration(
                labelText: "Mon apport en bières",
                prefixIcon: Icon(Icons.sports_bar_outlined, size: 18),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: DndSpacing.sm),
          ElevatedButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.check, size: 18),
            label: const Text("OK"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: DndSpacing.sm, vertical: DndSpacing.md),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── AvailabilityList ─────────────────────────────────────────────────────────

class AvailabilityList extends StatefulWidget {
  final GameSession session;
  final UsernameCacheNotifier usernameCache;

  const AvailabilityList({
    super.key,
    required this.session,
    required this.usernameCache,
  });

  @override
  State<AvailabilityList> createState() => _AvailabilityListState();
}

class _AvailabilityListState extends State<AvailabilityList> {
  List<MapEntry<String, bool?>> _resolved = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant AvailabilityList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.session.availability, widget.session.availability)) {
      _resolve();
    }
  }

  Future<void> _resolve() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final entries = await Future.wait(
      widget.session.availability.entries.map((e) async {
        final name = await widget.usernameCache.getUsername(e.key);
        return MapEntry(name, e.value as bool?);
      }),
    );
    if (mounted) {
      setState(() {
        _resolved = entries;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(DndSpacing.md),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final present =
        _resolved.where((e) => e.value == true).map((e) => e.key).toList();
    final absent =
        _resolved.where((e) => e.value == false).map((e) => e.key).toList();
    final unknown =
        _resolved.where((e) => e.value == null).map((e) => e.key).toList();

    if (present.isEmpty && absent.isEmpty && unknown.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(DndSpacing.md),
        child: Text("Aucune réponse encore."),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DndSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._section("Présents", present, Icons.check_circle,
              Colors.green.shade400),
          ..._section("Absents", absent, Icons.cancel, Colors.red.shade400),
          ..._section("Sans réponse", unknown, Icons.help_outline,
              Colors.grey),
        ],
      ),
    );
  }

  List<Widget> _section(
      String label, List<String> names, IconData icon, Color color) {
    if (names.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
            DndSpacing.sm, DndSpacing.md, DndSpacing.sm, DndSpacing.xs),
        child: Text(
          label,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: color, fontSize: 12),
        ),
      ),
      ...names.map(
        (name) => ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(icon, color: color, size: 18),
          title: Text(name, style: const TextStyle(fontSize: 14)),
        ),
      ),
    ];
  }
}

// ─── BeerContributionsList ────────────────────────────────────────────────────

class BeerContributionsList extends StatelessWidget {
  final GameSession session;
  final FirebaseGameService gameService;

  const BeerContributionsList({
    super.key,
    required this.session,
    required this.gameService,
  });

  @override
  Widget build(BuildContext context) {
    final contributions = session.beerContributions;
    final total = contributions.values.fold(0, (a, b) => a + b);

    if (total < 1) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(
            DndSpacing.md, DndSpacing.sm, DndSpacing.md, DndSpacing.xs),
        child: Text(
          "Personne n'a indiqué apporter des bières.",
          style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DndSpacing.md, DndSpacing.sm, DndSpacing.md, DndSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Apports prévus — $total bière${total > 1 ? 's' : ''} :",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: DndSpacing.xs),
          ...contributions.entries
              .where((e) => e.value > 0)
              .map((entry) => FutureBuilder<String>(
                    future: gameService.getUserName(entry.key),
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.sports_bar,
                                size: 14, color: DndColors.amber),
                            const SizedBox(width: DndSpacing.xs),
                            Text(
                              "${snap.data}  +${entry.value}",
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    },
                  )),
        ],
      ),
    );
  }
}

// ─── NotesSection ─────────────────────────────────────────────────────────────

/// Displays MJ notes for a session.
/// Players see a read-only callout box.
/// Admins additionally see an edit button that opens an inline editor.
class _NotesSection extends StatefulWidget {
  final GameSession session;
  final FirebaseGameService gameService;
  final bool isAdmin;

  const _NotesSection({
    required this.session,
    required this.gameService,
    required this.isAdmin,
  });

  @override
  State<_NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<_NotesSection> {
  bool _editing = false;
  bool _saving = false;
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.session.notes);
  }

  @override
  void didUpdateWidget(covariant _NotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync if notes changed externally (stream update) and not editing
    if (!_editing && oldWidget.session.notes != widget.session.notes) {
      _ctrl.text = widget.session.notes;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.gameService.saveSessionNotes(
      widget.session.id,
      _ctrl.text.trim(),
    );
    if (mounted) {
      setState(() {
        _saving = false;
        _editing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasNotes = widget.session.notes.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DndSpacing.md, DndSpacing.sm, DndSpacing.md, DndSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(Icons.sticky_note_2_outlined,
                  size: 15, color: DndColors.amber),
              const SizedBox(width: DndSpacing.xs),
              Text(
                "Note du MJ",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: DndColors.amber,
                ),
              ),
              if (widget.isAdmin) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (_editing) {
                      _save();
                    } else {
                      setState(() => _editing = true);
                    }
                  },
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _editing
                              ? Icons.check_circle_outline
                              : Icons.edit_outlined,
                          size: 18,
                          color: _editing
                              ? DndColors.beerGreen
                              : DndColors.onSurfaceMuted,
                        ),
                ),
                if (_editing) ...[
                  const SizedBox(width: DndSpacing.xs),
                  GestureDetector(
                    onTap: () => setState(() {
                      _ctrl.text = widget.session.notes;
                      _editing = false;
                    }),
                    child: Icon(Icons.close, size: 18,
                        color: DndColors.onSurfaceMuted),
                  ),
                ],
              ],
            ],
          ),
          const SizedBox(height: DndSpacing.xs),

          // Body: editing or read-only
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _editing
                ? TextField(
                    key: const ValueKey('editor'),
                    controller: _ctrl,
                    maxLines: null,
                    autofocus: true,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: "Ajouter une note pour cette session…",
                      isDense: true,
                    ),
                  )
                : hasNotes
                    ? Container(
                        key: const ValueKey('display'),
                        width: double.infinity,
                        padding: const EdgeInsets.all(DndSpacing.sm),
                        decoration: BoxDecoration(
                          color: DndColors.amber.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: DndColors.amber.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          widget.session.notes,
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : widget.isAdmin
                        ? Text(
                            "Aucune note — appuie sur ✏️ pour en ajouter.",
                            key: const ValueKey('empty'),
                            style: TextStyle(
                              fontSize: 12,
                              color: DndColors.onSurfaceMuted,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('nothing')),
          ),
        ],
      ),
    );
  }
}
