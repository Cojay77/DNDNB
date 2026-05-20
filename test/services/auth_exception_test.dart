import 'package:dndnb/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

// Helper to create a FirebaseAuthException for testing
FirebaseAuthException _fae(String code) =>
    FirebaseAuthException(code: code, message: 'raw message');

void main() {
  group('AuthException.fromFirebase()', () {
    test('user-not-found → correct French message', () {
      final e = AuthException.fromFirebase(_fae('user-not-found'));
      expect(e.message, 'Aucun compte trouvé avec cet email.');
    });

    test('wrong-password → correct French message', () {
      final e = AuthException.fromFirebase(_fae('wrong-password'));
      expect(e.message, 'Mot de passe incorrect.');
    });

    test('invalid-email → correct French message', () {
      final e = AuthException.fromFirebase(_fae('invalid-email'));
      expect(e.message, 'Adresse email invalide.');
    });

    test('user-disabled → correct French message', () {
      final e = AuthException.fromFirebase(_fae('user-disabled'));
      expect(e.message, 'Ce compte a été désactivé.');
    });

    test('email-already-in-use → correct French message', () {
      final e = AuthException.fromFirebase(_fae('email-already-in-use'));
      expect(e.message, 'Cet email est déjà utilisé.');
    });

    test('weak-password → correct French message', () {
      final e = AuthException.fromFirebase(_fae('weak-password'));
      expect(e.message,
          'Le mot de passe est trop faible (6 caractères minimum).');
    });

    test('too-many-requests → correct French message', () {
      final e = AuthException.fromFirebase(_fae('too-many-requests'));
      expect(e.message, 'Trop de tentatives. Réessayez plus tard.');
    });

    test('network-request-failed → correct French message', () {
      final e = AuthException.fromFirebase(_fae('network-request-failed'));
      expect(e.message, 'Erreur réseau. Vérifiez votre connexion.');
    });

    test('unknown code → fallback message includes raw Firebase message', () {
      final fae =
          FirebaseAuthException(code: 'unknown-code', message: 'détail');
      final e = AuthException.fromFirebase(fae);
      expect(e.message, contains('détail'));
    });

    test('toString() returns the message', () {
      final e = AuthException('message de test');
      expect(e.toString(), 'message de test');
    });
  });
}
