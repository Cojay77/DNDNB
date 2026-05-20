import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../services/firebase_service.dart';
import 'status_badge.dart';

class SessionCard extends StatelessWidget {
  final GameSession session;
  final String userId;
  final TextEditingController beerController;
  final FirebaseGameService gameService;
  final UsernameCacheNotifier usernameCache;
  final ThemeData theme;

  const SessionCard({
    super.key,
    required this.session,
    required this.userId,
    required this.beerController,
    required this.gameService,
    required this.usernameCache,
    required this.theme,
  });

  int countAvailable(GameSession session) {
    return session.availability.values.where((v) => v == true).length;
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = session.availability[userId];

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
              side: currentValue == null
                  ? BorderSide(color: theme.colorScheme.primary, width: 2)
                  : BorderSide.none,
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: currentValue == null
                  ? BorderSide(color: theme.colorScheme.primary, width: 2)
                  : BorderSide.none,
            ),
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            title: Text(
              "📅 ${session.displayDate}",
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
                const SizedBox(height: 8),
                _AttendingAvatarRow(
                  session: session,
                  usernameCache: usernameCache,
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildResponseButton(
                  context,
                  icon: Icons.check_circle,
                  color: Colors.green,
                  isSelected: currentValue == true,
                  onTap: () => gameService.toggleAvailability(session.id, userId, true),
                ),
                _buildResponseButton(
                  context,
                  icon: Icons.cancel,
                  color: Colors.red,
                  isSelected: currentValue == false,
                  onTap: () => gameService.toggleAvailability(session.id, userId, false),
                ),
                _buildResponseButton(
                  context,
                  icon: Icons.help,
                  color: Colors.grey,
                  isSelected: currentValue == null,
                  onTap: () => gameService.toggleAvailability(session.id, userId, null),
                ),
              ],
            ),
            children: [
              // Beer contribution input
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
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
                        final input = beerController.text.trim();
                        final apport = int.tryParse(input);

                        if (apport == null || apport < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("❌ Nombre invalide"),
                            ),
                          );
                          return;
                        }

                        await gameService.setBeerContribution(
                          session.id,
                          userId,
                          apport,
                        );
                        beerController.clear();
                      },
                      icon: const Icon(Icons.check),
                      label: const Text("OK"),
                    ),
                  ],
                ),
              ),

              // Availability list
              AvailabilityList(
                session: session,
                usernameCache: usernameCache,
              ),

              // Beer contributions list
              BeerContributionsList(
                session: session,
                gameService: gameService,
              ),
            ],
          ),
        ),

        // Status badge
        StatusBadge(status: session.status),
      ],
    );
  }

  Widget _buildResponseButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? color : Colors.grey.shade600,
          size: 24,
        ),
      ),
    );
  }
}

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
  List<MapEntry<String, bool?>> _resolvedEntries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolveUsernames();
  }

  @override
  void didUpdateWidget(covariant AvailabilityList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-resolve if session data changed
    if (oldWidget.session.availability != widget.session.availability) {
      _resolveUsernames();
    }
  }

  Future<void> _resolveUsernames() async {
    final entries = await Future.wait(
      widget.session.availability.entries.map((entry) async {
        final username =
            await widget.usernameCache.getUsername(entry.key);
        return MapEntry(username, entry.value as bool?);
      }),
    );

    if (mounted) {
      setState(() {
        _resolvedEntries = entries;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: CircularProgressIndicator(),
      );
    }

    final present =
        _resolvedEntries.where((e) => e.value == true).map((e) => e.key).toList();
    final absent =
        _resolvedEntries.where((e) => e.value == false).map((e) => e.key).toList();
    final unknown =
        _resolvedEntries.where((e) => e.value == null).map((e) => e.key).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (present.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "✅ Présents",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...present.map(
            (name) => ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(name),
            ),
          ),
        ],
        if (absent.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "❌ Absents",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...absent.map(
            (name) => ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: Text(name),
            ),
          ),
        ],
        if (unknown.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "❓ Sans réponse",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...unknown.map(
            (name) => ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.grey),
              title: Text(name),
            ),
          ),
        ],
      ],
    );
  }
}

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
    return FutureBuilder<Map<String, int>>(
      future: gameService.getBeerContributions(session),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final contributions = snapshot.data!;
        if (contributions.isEmpty ||
            contributions.values.fold(0, (p, c) => p + c) < 1) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Personne n'a indiqué apporter des bières."),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("🍻 Contributions :"),
              ...contributions.entries.map(
                (entry) => FutureBuilder<String>(
                  future: gameService.getUserName(entry.key),
                  builder: (context, nameSnap) {
                    if (!nameSnap.hasData || entry.value < 1) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      "${nameSnap.data} : + ${entry.value} 🍺",
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttendingAvatarRow extends StatefulWidget {
  final GameSession session;
  final UsernameCacheNotifier usernameCache;

  const _AttendingAvatarRow({
    required this.session,
    required this.usernameCache,
  });

  @override
  State<_AttendingAvatarRow> createState() => _AttendingAvatarRowState();
}

class _AttendingAvatarRowState extends State<_AttendingAvatarRow> {
  List<String> _presentNames = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolvePresentUsernames();
  }

  @override
  void didUpdateWidget(covariant _AttendingAvatarRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.availability != widget.session.availability) {
      _resolvePresentUsernames();
    }
  }

  Future<void> _resolvePresentUsernames() async {
    final presentUserIds = widget.session.availability.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();

    final names = await Future.wait(
        presentUserIds.map((id) => widget.usernameCache.getUsername(id)),
    );

    if (mounted) {
      setState(() {
        _presentNames = names;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 24,
        child: Text("Chargement des joueurs...", style: TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }

    if (_presentNames.isEmpty) {
      return const Text("Aucun joueur confirmé pour l'instant", style: TextStyle(fontSize: 12, color: Colors.grey));
    }

    final displayNames = _presentNames.take(5).toList();
    final overflow = _presentNames.length - 5;

    return Row(
      children: [
        ...displayNames.map((name) {
          final initial = name.isNotEmpty ? name[0].toUpperCase() : "?";
          return Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.green.shade800,
              child: Text(
                initial,
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
        if (overflow > 0)
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey.shade800,
              child: Text(
                "+$overflow",
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}