import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

Future<void> registerWebToken(String userId) async {
  if (!kIsWeb) return;

  try {
    final token = await FirebaseMessaging.instance.getToken(
      vapidKey:
          "BPnJahKmOlUPaI_adobh5Zp53Z25q02sHebm4MP5JhCnkY_eO8-1C5sQVRZuF9rTs6S7j4vgD9ydloKy4IFz_3M",
    );

    if (token != null) {
      final ref = FirebaseDatabase.instance.ref('webTokens/$userId');
      await ref.set(token);
      debugPrint("✅ Web token enregistré : $token");
    } else {
      debugPrint("❌ Aucun token reçu");
    }
  } catch (e) {
    debugPrint("❌ Erreur lors de l'enregistrement du token Web : $e");
  }
}

Future<void> registerWebTokenOnApp(String userId) async {
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      final ref = FirebaseDatabase.instance.ref('webTokens/$userId');
      await ref.set(token);
      debugPrint("✅ Mobile token enregistré : $token");
    }
  } catch (e) {
    debugPrint("❌ Erreur lors de l'enregistrement du token Web sur App : $e");
  }
}
