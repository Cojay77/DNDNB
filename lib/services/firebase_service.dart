import 'package:firebase_database/firebase_database.dart';
import '../models/game_session.dart';

class FirebaseGameService {
  final db = FirebaseDatabase.instance;

  Future<List<GameSession>> fetchSessions() async {
    final ref = db.ref("sessions");
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final Map data = snapshot.value as Map;
      List<GameSession> sessions =
          data.entries.map<GameSession>((e) {
            return GameSession.fromMap(
              e.key,
              Map<String, dynamic>.from(e.value),
            );
          }).toList();
      sessions.sort((a, b) => a.parsedDate.compareTo(b.parsedDate));
      return sessions;
    } else {
      return [];
    }
  }

  Future<void> createSession(String date, String userId, String title) async {
    final ref = db.ref("sessions").push();
    await ref.set({
      "title": title,
      "date": date,
      "createdBy": userId,
      "availability": {},
    });
  }

  Future<void> archiveSession(GameSession session) async {
    final sessionRef = db.ref("sessions/${session.id}");
    final archivedRef = db.ref("archivedSessions/${session.id}");

    final snapshot = await sessionRef.get();
    if (snapshot.exists) {
      await archivedRef.set(snapshot.value);
      await sessionRef.remove();
    }
  }

  Future<List<GameSession>> fetchArchivedSessions() async {
    final ref = db.ref("archivedSessions");
    final snap = await ref.get();
    if (snap.exists) {
      final Map data = snap.value as Map;
      var sessions =
          data.entries
              .map(
                (e) => GameSession.fromMap(
                  e.key,
                  Map<String, dynamic>.from(e.value),
                ),
              )
              .toList();
      sessions.sort((a, b) => b.parsedDate.compareTo(a.parsedDate));
      return sessions;
    } else {
      return [];
    }
  }

  Future<void> toggleAvailability(
    String sessionId,
    String userId,
    bool available,
  ) async {
    final ref = db.ref("sessions/$sessionId/availability/$userId");
    await ref.set(available);
  }

  Future<String> getUserName(String userId) async {
    final ref = db.ref("users/$userId/displayName");
    final snap = await ref.get();

    if (snap.exists) {
      return snap.value as String;
    } else {
      return "utilisateur inconnu";
    }
  }

  Future<List<String>> getAvailablePlayerNames(GameSession session) async {
    final userRef = db.ref("users");

    List<String> displayNames = [];

    for (final entry in session.availability.entries) {
      final uid = entry.key;
      final isAvailable = entry.value;

      if (isAvailable == true) {
        final snap = await userRef.child(uid).get();
        if (snap.exists) {
          final data = snap.value as Map;
          displayNames.add(data['displayName'] ?? uid);
        } else {
          displayNames.add(uid); // fallback si l'utilisateur n'est pas en DB
        }
      }
    }

    return displayNames;
  }

  Future<void> setBeerContribution(
    String sessionId,
    String userId,
    int amount,
  ) async {
    await db.ref("sessions/$sessionId/beerContributions/$userId").set(amount);
  }

  Future<Map<String, int>> getBeerContributions(GameSession session) async {
    final ref = db.ref("sessions/${session.id}/beerContributions");
    final snap = await ref.get();
    if (snap.exists) {
      return Map<String, int>.from(snap.value as Map<dynamic, dynamic>);
    } else {
      return {};
    }
  }

  Future<int> fetchUpcomingBeerContributions() async {
    final ref = db.ref("sessions");
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final sessions =
          (snapshot.value as Map).entries.map((e) {
            return GameSession.fromMap(
              e.key,
              Map<String, dynamic>.from(e.value),
            );
          }).toList();

      if (sessions.isEmpty) return 0;

      sessions.sort((a, b) => a.parsedDate.compareTo(b.parsedDate));
      final nextSession = sessions.first;

      return nextSession.beerContributions.values.fold<int>(0, (a, b) => a + b);
    }
    return 0;
  }
}
