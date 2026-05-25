import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../utils/date_utils.dart' as date_utils;
import '../utils/theme.dart';
import 'session_card.dart';

/// Hero card displayed on the home screen showing the next upcoming session.
/// Shows the date, title, player count, and the current user's availability status.
class NextSessionCard extends ConsumerWidget {
  const NextSessionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsStreamProvider);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return sessionsAsync.when(
      loading: () => const _NextSessionSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (sessions) {
        if (sessions.isEmpty) return const _NoSessionCard();

        // First session is the earliest upcoming (already sorted in service)
        final next = sessions.first;
        final availability = next.availability[userId];
        final playerCount = countAvailablePlayers(next);
        final statusColor = sessionStatusColor(next.status);

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Gradient header
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DndColors.fire,
                      DndColors.blood,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DndSpacing.md,
                  DndSpacing.md + 6,
                  DndSpacing.md,
                  DndSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label + status
                    Row(
                      children: [
                        Text(
                          "⚔️  Prochaine session",
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: DndColors.amber),
                        ),
                        const Spacer(),
                        if (statusColor != Colors.transparent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.6)),
                            ),
                            child: Text(
                              next.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: DndSpacing.sm),

                    // Date
                    Text(
                      next.date,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                    // Countdown chip
                    Builder(builder: (_) {
                      final countdown =
                          date_utils.sessionCountdown(next.date);
                      if (countdown.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: DndSpacing.xs),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: DndColors.fire.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: DndColors.fire
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            countdown,
                            style: TextStyle(
                              fontSize: 12,
                              color: DndColors.fire,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),

                    // Title
                    if (next.title.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        next.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],

                    // MJ notes teaser (one line, truncated)
                    if (next.notes.isNotEmpty) ...[
                      const SizedBox(height: DndSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DndSpacing.sm, vertical: 6),
                        decoration: BoxDecoration(
                          color: DndColors.amber.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: DndColors.amber.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.sticky_note_2_outlined,
                                size: 13, color: DndColors.amber),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                next.notes.length > 72
                                    ? '${next.notes.substring(0, 72)}…'
                                    : next.notes,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: DndColors.amber
                                      .withValues(alpha: 0.85),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: DndSpacing.md),

                    // Stats row
                    Row(
                      children: [
                        _StatChip(
                          icon: Icons.people,
                          label: "$playerCount présent${playerCount > 1 ? 's' : ''}",
                          color: playerCount > 0
                              ? DndColors.beerGreen
                              : DndColors.onSurfaceMuted,
                        ),
                        const SizedBox(width: DndSpacing.sm),
                        _StatChip(
                          icon: _availabilityIcon(availability),
                          label: _availabilityLabel(availability),
                          color: _availabilityColor(availability),
                        ),
                      ],
                    ),
                    const SizedBox(height: DndSpacing.sm),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _availabilityIcon(bool? availability) {
    if (availability == true) return Icons.check_circle;
    if (availability == false) return Icons.cancel;
    return Icons.help_outline;
  }

  String _availabilityLabel(bool? availability) {
    if (availability == true) return "Je suis présent";
    if (availability == false) return "Je suis absent";
    return "Pas encore répondu";
  }

  Color _availabilityColor(bool? availability) {
    if (availability == true) return DndColors.beerGreen;
    if (availability == false) return DndColors.beerRed;
    return DndColors.onSurfaceMuted;
  }
}

// ─── Chip ─────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Skeleton + empty states ──────────────────────────────────────────────────

class _NextSessionSkeleton extends StatelessWidget {
  const _NextSessionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DndSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimmer(120, 12),
            const SizedBox(height: DndSpacing.sm),
            _shimmer(200, 20),
            const SizedBox(height: DndSpacing.sm),
            _shimmer(150, 14),
          ],
        ),
      ),
    );
  }

  Widget _shimmer(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: DndColors.parchmentDark,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _NoSessionCard extends StatelessWidget {
  const _NoSessionCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DndSpacing.lg),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 40, color: DndColors.textSecondary),
            const SizedBox(height: DndSpacing.sm),
            Text(
              "Aucune session à venir.",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: DndColors.textMuted,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
