import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        loading: () => const Center(child: CircularProgressIndicator()),
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
            return const Center(child: Text("Aucune session archivée."));
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
                          session.date,
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
