import 'package:dndnb/utils/theme.dart';
import 'package:dndnb/widgets/session_card.dart';
import 'package:dndnb/widgets/update_banner.dart';
import 'package:dndnb/widgets/bottom_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class GameSessionsScreen extends ConsumerWidget {
  const GameSessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlightedSessionId = ModalRoute.of(context)?.settings.arguments as String?;
    final sessionsAsync = ref.watch(sessionsStreamProvider);
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final isAdmin = ref.watch(isAdminProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text("Sessions de jeu")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/sessions/archived'),
        label: const Text("Historique"),
        icon: const Icon(Icons.history),
      ),
      body: Column(
        children: [
          const UpdateBanner(),
          Expanded(
            child: sessionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => _ErrorState(
                onRetry: () => ref.invalidate(sessionsStreamProvider),
              ),
              data: (sessions) {
                if (sessions.isEmpty) return const _EmptyState();
                return RefreshIndicator(
                  color: DndColors.fire,
                  backgroundColor: DndColors.card,
                  onRefresh: () async =>
                      ref.invalidate(sessionsStreamProvider),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: DndSpacing.sm,
                      bottom: 96,
                    ),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) => _AnimatedSessionTile(
                      index: index,
                      child: SessionCard(
                        session: sessions[index],
                        userId: userId,
                        isAdmin: isAdmin,
                        isHighlighted: sessions[index].id == highlightedSessionId,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(),
    );
  }
}

// ─── Animated tile wrapper ────────────────────────────────────────────────────

class _AnimatedSessionTile extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedSessionTile({required this.index, required this.child});

  @override
  State<_AnimatedSessionTile> createState() => _AnimatedSessionTileState();
}

class _AnimatedSessionTileState extends State<_AnimatedSessionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    // Stagger based on index (max 300ms delay)
    Future.delayed(
      Duration(milliseconds: (widget.index * 60).clamp(0, 300)),
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

// ─── Sub-states ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy, size: 56, color: Colors.grey.shade700),
          const SizedBox(height: DndSpacing.md),
          Text(
            "Aucune session prévue pour le moment.",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade500,
                ),
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
            "Erreur de chargement des sessions.",
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
