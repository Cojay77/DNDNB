import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SendNotificationScreen extends StatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  State<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends State<SendNotificationScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _db = FirebaseDatabase.instance.ref();

  bool _sending = false;
  String? _status;

  Future<void> sendNotificationToAllUsers() async {
    setState(() {
      _sending = true;
      _status = null;
    });

    try {
      final notif = {
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _db.child('customNotification').set(notif);

      setState(() {
        _status = '✅ Notification créée avec succès';
        _sending = false;
      });
    } catch (e) {
      setState(() {
        _status = '❌ Erreur : $e';
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Envoyer une notification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _sending ? null : sendNotificationToAllUsers,
              icon: const Icon(Icons.send),
              label: Text(_sending ? 'Envoi...' : 'Envoyer à tous'),
            ),
            if (_status != null) ...[
              const SizedBox(height: 20),
              Text(
                _status!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
