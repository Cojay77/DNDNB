import 'package:dndnb/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final User _user;
  final AuthService _authService = AuthService();
  final TextEditingController _nameCtrl = TextEditingController();

  bool _isLoading = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser!;
    _nameCtrl.text = _user.displayName ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final displayName = _nameCtrl.text.trim();
    if (displayName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Le pseudo ne peut pas être vide.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _saved = false;
    });

    try {
      await _user.updateDisplayName(displayName);
      await _authService.setDisplayName(_user, displayName);
      await _user.reload();
      if (!mounted) return;
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profil mis à jour !")),
      );
      // Reset saved indicator after a moment
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _saved = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur : $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final updatedUser = FirebaseAuth.instance.currentUser!;
    final initials = _initials(updatedUser.displayName);

    return Scaffold(
      appBar: AppBar(title: const Text("Mon profil")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DndSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: DndSpacing.lg),

            // Avatar
            _Avatar(
              photoUrl: updatedUser.photoURL,
              initials: initials,
            ),
            const SizedBox(height: DndSpacing.lg),

            // Email chip
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: DndSpacing.md, vertical: DndSpacing.sm),
              decoration: BoxDecoration(
                color: DndColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: DndColors.fire.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mail_outline,
                      size: 15, color: DndColors.onSurfaceMuted),
                  const SizedBox(width: DndSpacing.xs),
                  Text(
                    updatedUser.email ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      color: DndColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DndSpacing.md),

            // Participation stats
            _StatsRow(userId: updatedUser.uid),
            const SizedBox(height: DndSpacing.xl),

            // Pseudo field
            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _updateProfile(),
              decoration: const InputDecoration(
                labelText: "Pseudo",
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: DndSpacing.lg),

            // Animated save button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      height: 48,
                      width: 48,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    )
                  : SizedBox(
                      key: ValueKey(_saved ? 'saved' : 'idle'),
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _updateProfile,
                        icon: Icon(
                          _saved ? Icons.check_circle : Icons.save_outlined,
                          size: 18,
                        ),
                        label: Text(
                            _saved ? "Enregistré !" : "Enregistrer"),
                        style: _saved
                            ? ElevatedButton.styleFrom(
                                backgroundColor: DndColors.beerGreen)
                            : null,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? photoUrl;
  final String initials;

  const _Avatar({required this.photoUrl, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: DndColors.fire.withValues(alpha: 0.6), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: DndColors.fire.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(photoUrl!, fit: BoxFit.cover)
            : Container(
                color: DndColors.surfaceVariant,
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: DndColors.fire,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Participation stats ──────────────────────────────────────────────────────

class _StatsRow extends ConsumerWidget {
  final String userId;
  const _StatsRow({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSessions = ref.watch(sessionsStreamProvider);
    final archivedSessions = ref.watch(archivedSessionsStreamProvider);

    final activeList = activeSessions.valueOrNull ?? [];
    final archivedList = archivedSessions.valueOrNull ?? [];

    final allSessions = [...activeList, ...archivedList];
    final total = allSessions.length;
    final attended = allSessions
        .where((s) => s.availability[userId] == true)
        .length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _StatChip(
          icon: Icons.sports_esports_outlined,
          label: "$attended session${attended > 1 ? 's' : ''} jouée${attended > 1 ? 's' : ''}",
          color: DndColors.beerGreen,
        ),
        const SizedBox(width: DndSpacing.sm),
        _StatChip(
          icon: Icons.calendar_month_outlined,
          label: "$total au total",
          color: DndColors.onSurfaceMuted,
        ),
      ],
    );
  }
}

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
      padding: const EdgeInsets.symmetric(
          horizontal: DndSpacing.md, vertical: DndSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: DndSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
