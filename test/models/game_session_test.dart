import 'package:dndnb/models/game_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  group('GameSession.fromMap()', () {
    test('parses a complete map correctly', () {
      final session = GameSession.fromMap('session_1', {
        'title': 'La Caverne du Dragon',
        'date': 'Samedi 24 mai 2025',
        'createdBy': 'uid_admin',
        'availability': {'uid_1': true, 'uid_2': false},
        'status': 'confirmée',
        'beerContributions': {'uid_1': 3, 'uid_2': 2},
        'notes': 'Penser à apporter les figurines',
      });

      expect(session.id, 'session_1');
      expect(session.title, 'La Caverne du Dragon');
      expect(session.date, 'Samedi 24 mai 2025');
      expect(session.createdBy, 'uid_admin');
      expect(session.availability['uid_1'], true);
      expect(session.availability['uid_2'], false);
      expect(session.status, 'confirmée');
      expect(session.beerContributions['uid_1'], 3);
      expect(session.beerContributions['uid_2'], 2);
      expect(session.notes, 'Penser à apporter les figurines');
    });

    test('applies defaults for missing optional fields', () {
      final session = GameSession.fromMap('session_2', {
        'title': '',
        'date': 'Samedi 24 mai 2025',
        'createdBy': 'uid_admin',
        'availability': {},
        'beerContributions': {},
      });

      expect(session.status, 'prévue');
      expect(session.notes, '');
    });

    test('handles missing availability and beerContributions gracefully', () {
      final session = GameSession.fromMap('session_3', {
        'title': 'Session sans dispo',
        'date': 'Samedi 24 mai 2025',
        'createdBy': 'uid_admin',
      });

      expect(session.availability, isEmpty);
      expect(session.beerContributions, isEmpty);
    });
  });

  group('GameSession.toMap()', () {
    test('serializes all fields', () {
      final session = GameSession(
        id: 'session_1',
        title: 'La Caverne du Dragon',
        date: 'Samedi 24 mai 2025',
        createdBy: 'uid_admin',
        availability: {'uid_1': true},
        status: 'confirmée',
        beerContributions: {'uid_1': 3},
        notes: 'Note du MJ',
      );

      final map = session.toMap();

      expect(map['title'], 'La Caverne du Dragon');
      expect(map['date'], 'Samedi 24 mai 2025');
      expect(map['createdBy'], 'uid_admin');
      expect(map['availability'], {'uid_1': true});
      expect(map['status'], 'confirmée');
      expect(map['beerContributions'], {'uid_1': 3});
      expect(map['notes'], 'Note du MJ');
    });

    test('round-trip: fromMap → toMap produces equivalent data', () {
      final original = {
        'title': 'Session Test',
        'date': 'Dimanche 1 juin 2025',
        'createdBy': 'uid_mj',
        'availability': {'uid_a': true, 'uid_b': false},
        'status': 'modifiée',
        'beerContributions': {'uid_a': 5},
        'notes': 'Début à 20h',
      };

      final session = GameSession.fromMap('round_trip', original);
      final serialized = session.toMap();

      expect(serialized['title'], original['title']);
      expect(serialized['date'], original['date']);
      expect(serialized['createdBy'], original['createdBy']);
      expect(serialized['status'], original['status']);
      expect(serialized['notes'], original['notes']);
    });
  });

  group('GameSession.parsedDate', () {
    test('parses a valid French date', () {
      final session = GameSession(
        id: 'x',
        title: '',
        date: 'Samedi 24 mai 2025',
        createdBy: '',
        availability: {},
        beerContributions: {},
      );

      final parsed = session.parsedDate;
      expect(parsed.year, 2025);
      expect(parsed.month, 5);
      expect(parsed.day, 24);
    });

    test('returns sentinel date DateTime(2100) for unparseable input', () {
      final session = GameSession(
        id: 'x',
        title: '',
        date: 'not a date',
        createdBy: '',
        availability: {},
        beerContributions: {},
      );

      expect(session.parsedDate.year, 2100);
    });

    test('handles capitalized day name (as stored)', () {
      final session = GameSession(
        id: 'x',
        title: '',
        date: 'Dimanche 1 juin 2025',
        createdBy: '',
        availability: {},
        beerContributions: {},
      );

      final parsed = session.parsedDate;
      expect(parsed.year, 2025);
      expect(parsed.month, 6);
      expect(parsed.day, 1);
    });
  });
}
