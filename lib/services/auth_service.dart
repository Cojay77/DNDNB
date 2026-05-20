import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the current Firebase Auth user as a stream
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Provides admin status for the current user
final isAdminProvider = FutureProvider<bool>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return false;
      return await AuthService().isUserAdmin(user.uid);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Inscription
  Future<User?> register(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      await user?.updateDisplayName(displayName);

      if (user != null) {
        await _db.ref("users/${user.uid}").set({
          "email": user.email,
          "isAdmin": false,
          "displayName": displayName,
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException("Erreur d'inscription : $e");
    }
  }

  Future setDisplayName(User user, String displayName) async {
    _db.ref("users/${user.uid}").update({"displayName": displayName});
  }

  // Connexion
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException("Erreur de connexion : $e");
    }
  }

  Future<bool> isUserAdmin(String uid) async {
    final db = FirebaseDatabase.instance;
    final snapshot = await db.ref("users/$uid/isAdmin").get();

    if (snapshot.exists) {
      return snapshot.value == true;
    }
    return false;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  /// Register FCM token for push notifications
  Future<void> registerToken(String userId) async {
    try {
      String? token;

      if (kIsWeb) {
        // VAPID_KEY must be injected at build time via:
        //   flutter build web --dart-define=VAPID_KEY=<your_key>
        // If missing, getToken() will throw and be caught below.
        const vapidKey = String.fromEnvironment('VAPID_KEY');
        assert(vapidKey.isNotEmpty, 'VAPID_KEY must be set at build time');
        token = await FirebaseMessaging.instance.getToken(vapidKey: vapidKey);
      } else {
        token = await FirebaseMessaging.instance.getToken();
      }

      if (token != null) {
        final ref = FirebaseDatabase.instance.ref('webTokens/$userId');
        await ref.set(token);
        debugPrint("✅ Token enregistré : $token");
      }
    } catch (e) {
      debugPrint("❌ Erreur lors de l'enregistrement du token : $e");
    }
  }

  /// Refresh token if it changed
  Future<void> refreshTokenIfNeeded(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      final ref = FirebaseDatabase.instance.ref('webTokens/$userId');
      final snapshot = await ref.get();

      if (snapshot.value != token) {
        await ref.set(token);
        debugPrint("Token mis à jour : $token");
      }
    } catch (e) {
      debugPrint("❌ Erreur refresh token : $e");
    }
  }
}

/// Custom exception for auth errors with user-friendly messages
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  factory AuthException.fromFirebase(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException("Aucun compte trouvé avec cet email.");
      case 'wrong-password':
        return AuthException("Mot de passe incorrect.");
      case 'invalid-email':
        return AuthException("Adresse email invalide.");
      case 'user-disabled':
        return AuthException("Ce compte a été désactivé.");
      case 'email-already-in-use':
        return AuthException("Cet email est déjà utilisé.");
      case 'weak-password':
        return AuthException("Le mot de passe est trop faible (6 caractères minimum).");
      case 'too-many-requests':
        return AuthException("Trop de tentatives. Réessayez plus tard.");
      case 'network-request-failed':
        return AuthException("Erreur réseau. Vérifiez votre connexion.");
      default:
        return AuthException("Erreur d'authentification : ${e.message}");
    }
  }

  @override
  String toString() => message;
}
