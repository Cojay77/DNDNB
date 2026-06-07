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

  // ── FCM background messages ────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

// ── Global key so foreground FCM messages can show a SnackBar from anywhere.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('fr_FR', null);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ── FCM token refresh ──────────────────────────────────────────────────────
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

  // ── Handle notification click when app is in background ────────────────────
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint("Application ouverte via notification : ${message.notification?.title}");
    // We could navigate here if needed
  });

  // ── Handle notification click when app is terminated ───────────────────────
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    debugPrint("Application lancée via notification : ${initialMessage.notification?.title}");
    // We could navigate here if needed
  }

  // ── FCM foreground messages ────────────────────────────────────────────────
  // When the app is open, FCM suppresses the OS notification.
  // We show an in-app SnackBar instead so the user doesn't miss it.
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final title = message.notification?.title ?? 'D&D&B';
    final body  = message.notification?.body;
    if (body == null || body.isEmpty) return;

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.notifications_active_outlined,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(body,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });

  runApp(
    ProviderScope(
      child: DndApp(
        routeObserver: routeObserver,
        scaffoldMessengerKey: scaffoldMessengerKey,
      ),
    ),
  );
}
