import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser!;
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = user.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    try {
      var displayName = _nameController.text.trim();
      if (displayName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Le pseudo ne peut pas être vide.")),
        );
        return;
      }

      await user.updateDisplayName(displayName);
      await _authService.setDisplayName(user, displayName);
      await user.reload();
      setState(() {});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profil mis à jour !")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur : $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final updatedUser = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text("Mon profil")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (updatedUser.photoURL != null)
              CircleAvatar(
                backgroundImage: NetworkImage(updatedUser.photoURL!),
                radius: 40,
              ),
            const SizedBox(height: 16),
            Text("Adresse email : ${updatedUser.email ?? ''}"),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Pseudo"),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateProfile,
              child: const Text("Enregistrer les modifications"),
            ),
          ],
        ),
      ),
    );
  }
}
