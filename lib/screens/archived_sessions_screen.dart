import 'package:dndnb/utils/theme.dart';
import 'package:dndnb/widgets/status_badge.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_session.dart';
import '../services/firebase_service.dart';

class ArchivedSessionsScreen extends ConsumerWidget {
  const ArchivedSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(archivedSessionsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Historique")),
      body: archivedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ErrorState(
          onRetry: () => ref.invalidate(archivedSessionsStreamProvider),
        ),
        data: (sessions) {
          if (sessions.isEmpty) return const _EmptyState();
          return RefreshIndicator(
            color: DndColors.fire,
            backgroundColor: DndColors.card,
            onRefresh: () async =>
                ref.invalidate(archivedSessionsStreamProvider),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: DndSpacing.sm,
                bottom: DndSpacing.xl,
              ),
              itemCount: sessions.length,
              itemBuilder: (context, index) => _AnimatedArchiveTile(
                index: index,
                child: _ArchivedSessionTile(session: sessions[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Animated tile wrapper ────────────────────────────────────────────────────

class _AnimatedArchiveTile extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedArchiveTile({required this.index, required this.child});

  @override
  State<_AnimatedArchiveTile> createState() => _AnimatedArchiveTileState();
}

class _AnimatedArchiveTileState extends State<_AnimatedArchiveTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(
      Duration(milliseconds: (widget.index * 50).clamp(0, 300)),
      () { if (mounted) _ctrl.forward(); },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─── Archived session tile ────────────────────────────────────────────────────

class _ArchivedSessionTile extends StatelessWidget {
  final GameSession session;
  const _ArchivedSessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final present = session.availability.values.where((v) => v == true).length;
    final absent = session.availability.values.where((v) => v == false).length;
    final beerTotal = session.beerContributions.values
        .fold<int>(0, (a, b) => a + b);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          color: DndColors.surfaceVariant,
          margin: const EdgeInsets.symmetric(
            horizontal: DndSpacing.md,
            vertical: DndSpacing.xs,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: DndSpacing.md,
              vertical: DndSpacing.xs,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: DndColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.history,
                size: 20,
                color: DndColors.onSurfaceMuted,
              ),
            ),
            title: Text(
              _shortDate(session.date),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (session.title.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    session.title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 4),
                // Stats chips row
                Wrap(
                  spacing: DndSpacing.xs,
                  children: [
                    _MiniChip(
                      icon: Icons.check_circle_outline,
                      label: "$present présent${present > 1 ? 's' : ''}",
                      color: Colors.green.shade400,
                    ),
                    if (absent > 0)
                      _MiniChip(
                        icon: Icons.cancel_outlined,
                        label: "$absent absent${absent > 1 ? 's' : ''}",
                        color: Colors.red.shade300,
                      ),
                    if (beerTotal > 0)
                      _MiniChip(
                        icon: Icons.sports_bar_outlined,
                        label: "$beerTotal bière${beerTotal > 1 ? 's' : ''}",
                        color: DndColors.amber,
                      ),
                  ],
                ),
              ],
            ),
            children: [
              const Divider(height: 1, indent: 16, endIndent: 16),
              // Availability breakdown
              _AvailabilityBreakdown(session: session),
              // Notes if present
              if (session.notes.isNotEmpty) _NotesDisplay(notes: session.notes),
              const SizedBox(height: DndSpacing.sm),
            ],
          ),
        ),
        // Status badge
        Positioned(
          right: DndSpacing.sm,
          top: 0,
          child: StatusBadge(status: session.status),
        ),
      ],
    );
  }

  String _shortDate(String date) {
    if (date.length > 5) return date.substring(0, date.length - 5);
    return date;
  }
}

// ─── Mini chip ────────────────────────────────────────────────────────────────

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Availability breakdown ───────────────────────────────────────────────────

class _AvailabilityBreakdown extends StatefulWidget {
  final GameSession session;
  const _AvailabilityBreakdown({required this.session});

  @override
  State<_AvailabilityBreakdown> createState() =>
      _AvailabilityBreakdownState();
}

class _AvailabilityBreakdownState extends State<_AvailabilityBreakdown> {
  List<MapEntry<String, bool?>>? _resolved;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final db = FirebaseDatabase.instance;
    final entries = await Future.wait(
      widget.session.availability.entries.map((e) async {
        final snap =
            await db.ref("users/${e.key}/displayName").get();
        final name =
            snap.exists ? snap.value.toString() : "Utilisateur inconnu";
        return MapEntry(name, e.value as bool?);
      }),
    );
    if (mounted) setState(() => _resolved = entries);
  }

  @override
  Widget build(BuildContext context) {
    if (_resolved == null) {
      return const Padding(
        padding: EdgeInsets.all(DndSpacing.md),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final present =
        _resolved!.where((e) => e.value == true).map((e) => e.key).toList();
    final absent =
        _resolved!.where((e) => e.value == false).map((e) => e.key).toList();
    final unknown =
        _resolved!.where((e) => e.value == null).map((e) => e.key).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: DndSpacing.md, vertical: DndSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._section(
              "Présents", present, Icons.check_circle, Colors.green.shade400),
          ..._section("Absents", absent, Icons.cancel, Colors.red.shade400),
          ..._section("Sans réponse", unknown, Icons.help_outline, Colors.grey),
        ],
      ),
    );
  }

  List<Widget> _section(
      String label, List<String> names, IconData icon, Color color) {
    if (names.isEmpty) return [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: DndSpacing.sm, bottom: DndSpacing.xs),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
      Wrap(
        spacing: DndSpacing.sm,
        runSpacing: DndSpacing.xs,
        children: names
            .map((n) => _MiniChip(icon: icon, label: n, color: color))
            .toList(),
      ),
    ];
  }
}

// ─── Notes display ────────────────────────────────────────────────────────────

class _NotesDisplay extends StatelessWidget {
  final String notes;
  const _NotesDisplay({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DndSpacing.md, 0, DndSpacing.md, DndSpacing.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(DndSpacing.sm),
        decoration: BoxDecoration(
          color: DndColors.amber.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: DndColors.amber.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.sticky_note_2_outlined,
                size: 14, color: DndColors.amber),
            const SizedBox(width: DndSpacing.xs),
            Expanded(
              child: Text(
                notes,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: DndColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-states ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_toggle_off,
              size: 64, color: Colors.grey.shade700),
          const SizedBox(height: DndSpacing.md),
          Text(
            "Aucune session archivée.",
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Colors.grey.shade500),
          ),
          const SizedBox(height: DndSpacing.sm),
          Text(
            "Les sessions passées apparaîtront ici.",
            style: TextStyle(
                fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, color: Colors.red.shade300, size: 52),
          const SizedBox(height: DndSpacing.md),
          Text(
            "Erreur de chargement",
            style: TextStyle(color: Colors.red.shade300),
          ),
          const SizedBox(height: DndSpacing.md),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text("Réessayer"),
          ),
        ],
      ),
    );
  }
}
