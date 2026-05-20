import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_session.dart';

/// Provider for the FirebaseGameService singleton
final gameServiceProvider = Provider<FirebaseGameService>((ref) {
  return FirebaseGameService();
});

/// Stream provider for active sessions — realtime updates
final sessionsStreamProvider = StreamProvider<List<GameSession>>((ref) {
  final service = ref.watch(gameServiceProvider);
  return service.sessionsStream();
});

/// Stream provider for archived sessions
final archivedSessionsStreamProvider = StreamProvider<List<GameSession>>((ref) {
  final service = ref.watch(gameServiceProvider);
  return service.archivedSessionsStream();
});

/// Stream provider for beer stock
final beerStockStreamProvider = StreamProvider<double>((ref) {
  final ref2 = FirebaseDatabase.instance.ref('beerStock/value');
  return ref2.onValue.map((event) {
    return (event.snapshot.value as num?)?.toDouble() ?? 0.0;
  });
});

/// Stream provider for home message
final homeMessageStreamProvider = StreamProvider<String>((ref) {
  final dbRef = FirebaseDatabase.instance.ref("homeMessage/text");
  return dbRef.onValue.map((event) {
    if (event.snapshot.exists) {
      return event.snapshot.value.toString().replaceAll("\\n", "\n");
    }
    return "Pas de message";
  });
});

/// Stream provider for release notes
final releaseNoteStreamProvider = StreamProvider<String>((ref) {
  final dbRef = FirebaseDatabase.instance.ref("homeMessage/releasenote");
  return dbRef.onValue.map((event) {
    if (event.snapshot.exists) {
      return event.snapshot.value.toString().replaceAll("\\n", "\n");
    }
    return "";
  });
});

/// Cache for user display names to avoid repeated lookups
final usernameCacheProvider =
    StateNotifierProvider<UsernameCacheNotifier, Map<String, String>>((ref) {
  return UsernameCacheNotifier();
});

class UsernameCacheNotifier extends StateNotifier<Map<String, String>> {
  UsernameCacheNotifier() : super({});

  Future<String> getUsername(String userId) async {
    if (state.containsKey(userId)) {
      return state[userId]!;
    }

    final snapshot = await FirebaseDatabase.instance
        .ref("users/$userId/displayName")
        .get();

    final name =
        snapshot.exists ? snapshot.value.toString() : "Utilisateur inconnu";

    state = {...state, userId: name};
    return name;
  }
}

/// Provider for upcoming beer contributions total
final upcomingBeerContributionsProvider = FutureProvider<int>((ref) async {
  final sessionsAsync = ref.watch(sessionsStreamProvider);
  return sessionsAsync.when(
    data: (sessions) {
      if (sessions.isEmpty) return 0;
      // Sessions are sorted by date, first is the earliest upcoming
      final nextSession = sessions.first;
      return nextSession.beerContributions.values.fold<int>(0, (a, b) => a + b);
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

class FirebaseGameService {
  final db = FirebaseDatabase.instance;

  /// Realtime stream of active sessions
  Stream<List<GameSession>> sessionsStream() {
    final ref = db.ref("sessions");
    return ref.onValue.map((event) {
      if (!event.snapshot.exists) return <GameSession>[];

      final Map data = event.snapshot.value as Map;
      List<GameSession> sessions = data.entries.map<GameSession>((e) {
        return GameSession.fromMap(
          e.key,
          Map<String, dynamic>.from(e.value),
        );
      }).toList();
      sessions.sort((a, b) => a.parsedDate.compareTo(b.parsedDate));
      return sessions;
    });
  }

  /// Realtime stream of archived sessions
  Stream<List<GameSession>> archivedSessionsStream() {
    final ref = db.ref("archivedSessions");
    return ref.onValue.map((event) {
      if (!event.snapshot.exists) return <GameSession>[];

      final Map data = event.snapshot.value as Map;
      var sessions = data.entries
          .map((e) => GameSession.fromMap(
                e.key,
                Map<String, dynamic>.from(e.value),
              ))
          .toList();
      sessions.sort((a, b) => b.parsedDate.compareTo(a.parsedDate));
      return sessions;
    });
  }

  /// One-shot fetch (kept for backwards compat in admin)
  Future<List<GameSession>> fetchSessions() async {
    final ref = db.ref("sessions");
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final Map data = snapshot.value as Map;
      List<GameSession> sessions = data.entries.map<GameSession>((e) {
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
      "status": "prévue",
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

  Future<Map<String, bool?>> getAllAvailability(GameSession session) async {
    return session.availability; // Already part of the session data
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
      final sessions = (snapshot.value as Map).entries.map((e) {
        return GameSession.fromMap(
          e.key,
          Map<String, dynamic>.from(e.value),
        );
      }).toList();

      if (sessions.isEmpty) return 0;

      sessions.sort((a, b) => a.parsedDate.compareTo(b.parsedDate));
      final nextSession = sessions.first;

      return nextSession.beerContributions.values
          .fold<int>(0, (a, b) => a + b);
    }
    return 0;
  }

  Future<void> updateSessionStatus(String sessionId, String status) async {
    await db.ref("sessions/$sessionId/status").set(status);
  }

  /// Saves MJ notes for a session (visible to all, written by admin only)
  Future<void> saveSessionNotes(String sessionId, String notes) async {
    await db.ref("sessions/$sessionId/notes").set(notes);
  }
}
