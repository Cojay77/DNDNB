import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'package:intl/date_symbol_data_local.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('fr_FR', null);

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    debugPrint("🔁 Nouveau token : $newToken");

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseDatabase.instance
            .ref("webTokens/${user.uid}")
            .set(newToken);
        debugPrint("✅ Nouveau token enregistré dans la base");
      } catch (e) {
        debugPrint("❌ Erreur enregistrement nouveau token : $e");
      }
    } else {
      debugPrint("ℹ️ Aucun utilisateur connecté, token ignoré.");
    }
  });

  runApp(
    ProviderScope(
      child: DndApp(routeObserver: routeObserver),
    ),
  );
}
