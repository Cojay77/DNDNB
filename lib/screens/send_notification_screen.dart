import 'package:dndnb/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() =>
      _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  // ── Notification fields ───────────────────────────────────────────────
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  // ── Home message / release note fields ───────────────────────────────
  final _homeMessageCtrl = TextEditingController();
  final _releaseNoteCtrl = TextEditingController();

  bool _sendingNotif = false;
  bool _savingContent = false;
  _Status? _notifStatus;
  _Status? _contentStatus;

  final _db = FirebaseDatabase.instance.ref();

  static const int _maxMessage = 300;

  @override
  void initState() {
    super.initState();
    _loadCurrentContent();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    _homeMessageCtrl.dispose();
    _releaseNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentContent() async {
    // Reads from the same paths the stream providers watch
    final snap = await _db.child('homeMessage').get();
    if (!snap.exists || !mounted) return;
    final data = snap.value as Map<dynamic, dynamic>;
    setState(() {
      _homeMessageCtrl.text = data['text']?.toString() ?? '';
      _releaseNoteCtrl.text = data['releasenote']?.toString() ?? '';
    });
  }

  Future<void> _sendNotification() async {
    final title = _titleCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (title.isEmpty || message.isEmpty) {
      setState(() => _notifStatus =
          _Status(ok: false, text: "Titre et message requis."));
      return;
    }
    setState(() {
      _sendingNotif = true;
      _notifStatus = null;
    });
    try {
      await _db.child('customNotification').set({
        'title': title,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        setState(() {
          _notifStatus = _Status(ok: true, text: "Notification envoyée !");
          _sendingNotif = false;
        });
        _titleCtrl.clear();
        _messageCtrl.clear();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _notifStatus = _Status(ok: false, text: "Erreur : $e");
          _sendingNotif = false;
        });
      }
    }
  }

  Future<void> _saveContent() async {
    setState(() {
      _savingContent = true;
      _contentStatus = null;
    });
    try {
      await _db.child('homeMessage').update({
        'text': _homeMessageCtrl.text.trim(),
        'releasenote': _releaseNoteCtrl.text.trim(),
      });
      if (mounted) {
        setState(() {
          _contentStatus =
              _Status(ok: true, text: "Contenu mis à jour !");
          _savingContent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _contentStatus = _Status(ok: false, text: "Erreur : $e");
          _savingContent = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestion du contenu")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DndSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Section: Home content ─────────────────────────────────
            _SectionHeader(
                icon: Icons.home_outlined, label: "Message d'accueil"),
            const SizedBox(height: DndSpacing.sm),
            TextField(
              controller: _homeMessageCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Message affiché sur l'accueil",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: DndSpacing.sm),
            TextField(
              controller: _releaseNoteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Note de version (release note)",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: DndSpacing.sm),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _savingContent
                  ? const Center(
                      key: ValueKey('saving'),
                      child: Padding(
                        padding: EdgeInsets.all(DndSpacing.sm),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : ElevatedButton.icon(
                      key: const ValueKey('save'),
                      onPressed: _saveContent,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text("Enregistrer le contenu"),
                    ),
            ),
            if (_contentStatus != null) ...[
              const SizedBox(height: DndSpacing.sm),
              _StatusChip(status: _contentStatus!),
            ],

            const SizedBox(height: DndSpacing.xl),
            const Divider(),
            const SizedBox(height: DndSpacing.md),

            // ── Section: Push notification ────────────────────────────
            _SectionHeader(
                icon: Icons.notifications_outlined,
                label: "Envoyer une notification"),
            const SizedBox(height: DndSpacing.sm),
            TextField(
              controller: _titleCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: "Titre"),
            ),
            const SizedBox(height: DndSpacing.sm),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageCtrl,
              builder: (_, val, __) => TextField(
                controller: _messageCtrl,
                maxLines: 4,
                maxLength: _maxMessage,
                decoration: InputDecoration(
                  labelText: "Message",
                  alignLabelWithHint: true,
                  counterText:
                      "${val.text.length}/$_maxMessage",
                ),
              ),
            ),
            const SizedBox(height: DndSpacing.sm),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _sendingNotif
                  ? const Center(
                      key: ValueKey('sending'),
                      child: Padding(
                        padding: EdgeInsets.all(DndSpacing.sm),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : ElevatedButton.icon(
                      key: const ValueKey('send'),
                      onPressed: _sendNotification,
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text("Envoyer à tous"),
                    ),
            ),
            if (_notifStatus != null) ...[
              const SizedBox(height: DndSpacing.sm),
              _StatusChip(status: _notifStatus!),
            ],
            const SizedBox(height: DndSpacing.xl),
          ],
        ),
      ),
    );
  }
}

// ─── Supporting types & widgets ───────────────────────────────────────────────

class _Status {
  final bool ok;
  final String text;
  const _Status({required this.ok, required this.text});
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: DndColors.fire),
        const SizedBox(width: DndSpacing.sm),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: DndColors.fire),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final _Status status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.ok ? DndColors.beerGreen : DndColors.beerRed;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: DndSpacing.md, vertical: DndSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.ok ? Icons.check_circle_outline : Icons.error_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: DndSpacing.sm),
          Text(
            status.text,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
