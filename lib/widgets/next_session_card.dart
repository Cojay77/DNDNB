import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../services/firebase_service.dart';
import '../utils/theme.dart';

class NextSessionCard extends ConsumerWidget {
  const NextSessionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsStreamProvider);

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return _buildEmptyState(context);
        }

        // The stream provider already sorts by date, so the first is the next upcoming
        final nextSession = sessions.first;
        final availableCount =
            nextSession.availability.values.where((v) => v == true).length;

        return _buildHeroCard(context, nextSession.title,
            nextSession.displayDate, availableCount, nextSession.status);
      },
      loading: () => _buildShimmer(),
      error: (_, __) => _buildErrorState(context),
    );
  }

  Widget _buildHeroCard(BuildContext context, String title, String date,
      int participants, String status) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.8),
            AppTheme.secondary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background icon
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.casino,
              size: 120,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Prochaine Session",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        fontFamily: 'Inter', // Try modern font if available
                      ),
                    ),
                    if (AppTheme.getStatusColor(status) !=
                        AppTheme.statusDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.getStatusColor(status),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  date,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'UncialAntiqua',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.group, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "$participants joueur(s) confirmés",
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            "Aucune session prévue",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Demandez à l'admin d'en créer une !",
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade900),
      ),
      child: const Center(
        child: Text(
          "Erreur de chargement",
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade800,
      highlightColor: Colors.grey.shade700,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
