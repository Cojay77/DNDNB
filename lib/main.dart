import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    debugPrint("🔁 Nouveau token Web : $newToken");

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseDatabase.instance
            .ref("users/${user.uid}/webToken")
            .set(newToken);
        debugPrint("✅ Nouveau token enregistré dans la base");
      } catch (e) {
        debugPrint("❌ Erreur enregistrement nouveau token : $e");
      }
    } else {
      debugPrint("ℹ️ Aucun utilisateur connecté, token ignoré.");
    }
  });

  runApp(DndApp(routeObserver: routeObserver));
}
