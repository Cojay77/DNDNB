import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../services/firebase_service.dart';
import '../widgets/status_badge.dart';

class ArchivedSessionsScreen extends ConsumerWidget {
  const ArchivedSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archivedAsync = ref.watch(archivedSessionsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Historique des sessions")),
      body: archivedAsync.when(
        loading: () => ListView.builder(
          itemCount: 6,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Shimmer.fromColors(
                baseColor: Colors.grey.shade800,
                highlightColor: Colors.grey.shade700,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            );
          },
        ),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
              const SizedBox(height: 12),
              Text(
                "Erreur de chargement",
                style: TextStyle(color: Colors.red.shade300),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(archivedSessionsStreamProvider),
                child: const Text("Réessayer"),
              ),
            ],
          ),
        ),
        data: (archivedSessions) {
          if (archivedSessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text(
                    "Aucune archive",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Aucune session n'a encore été archivée.",
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: archivedSessions.length,
            itemBuilder: (context, index) {
              final session = archivedSessions[index];
              final availableCount =
                  session.availability.values.where((v) => v == true).length;

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
                          session.displayDate,
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
                              style:
                                  const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "$availableCount joueur(s) étaient dispo",
                              style:
                                  const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  StatusBadge(status: session.status),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
