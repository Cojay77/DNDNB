import 'package:dndnb/utils/date_utils.dart' as date_utils;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    // Initialize French locale data — required for DateFormat('...', 'fr_FR')
    await initializeDateFormatting('fr_FR');
  });

  group('parseSessionDate()', () {
    test('parses "Samedi 24 mai 2025" correctly', () {
      final dt = date_utils.parseSessionDate('Samedi 24 mai 2025');
      expect(dt, isNotNull);
      expect(dt!.year, 2025);
      expect(dt.month, 5);
      expect(dt.day, 24);
    });

    test('parses lowercase "samedi 24 mai 2025"', () {
      final dt = date_utils.parseSessionDate('samedi 24 mai 2025');
      expect(dt, isNotNull);
      expect(dt!.day, 24);
    });

    test('parses short format "24 mai 2025"', () {
      final dt = date_utils.parseSessionDate('24 mai 2025');
      expect(dt, isNotNull);
      expect(dt!.year, 2025);
      expect(dt.month, 5);
      expect(dt.day, 24);
    });

    test('returns null for empty string', () {
      expect(date_utils.parseSessionDate(''), isNull);
    });

    test('returns null for garbage input', () {
      expect(date_utils.parseSessionDate('not a date'), isNull);
      expect(date_utils.parseSessionDate('123-456'), isNull);
    });

    test('handles extra whitespace', () {
      final dt = date_utils.parseSessionDate('  Samedi  24  mai  2025  ');
      expect(dt, isNotNull);
      expect(dt!.day, 24);
    });

    test('defaults session time to 19:00', () {
      final dt = date_utils.parseSessionDate('Samedi 24 mai 2025');
      expect(dt!.hour, 19);
      expect(dt.minute, 0);
    });

    test('handles day with leading zero "Samedi 04 mai 2025"', () {
      final dt = date_utils.parseSessionDate('Samedi 04 mai 2025');
      expect(dt, isNotNull);
      expect(dt!.day, 4);
    });
  });

  group('sessionCountdown()', () {
    test('returns empty string for unparseable date', () {
      expect(date_utils.sessionCountdown('not a date'), '');
    });

    test('returns "Dans X jours" for future session', () {
      final future = DateTime.now().add(const Duration(days: 5));
      final dateStr =
          '${_dayName(future.weekday)} ${future.day} ${_monthName(future.month)} ${future.year}';
      final result = date_utils.sessionCountdown(dateStr);
      expect(result, 'Dans 5 jours');
    });

    test('returns "Demain !" for tomorrow', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dateStr =
          '${_dayName(tomorrow.weekday)} ${tomorrow.day} ${_monthName(tomorrow.month)} ${tomorrow.year}';
      final result = date_utils.sessionCountdown(dateStr);
      expect(result, 'Demain !');
    });

    test('returns "Il y a X jours" for past sessions', () {
      final past = DateTime.now().subtract(const Duration(days: 3));
      final dateStr =
          '${_dayName(past.weekday)} ${past.day} ${_monthName(past.month)} ${past.year}';
      final result = date_utils.sessionCountdown(dateStr);
      expect(result, 'Il y a 3 jours');
    });

    test('returns "Hier" for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateStr =
          '${_dayName(yesterday.weekday)} ${yesterday.day} ${_monthName(yesterday.month)} ${yesterday.year}';
      final result = date_utils.sessionCountdown(dateStr);
      expect(result, 'Hier');
    });
  });
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _dayName(int weekday) {
  const days = [
    'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
  ];
  return days[weekday - 1];
}

String _monthName(int month) {
  const months = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
  ];
  return months[month - 1];
}
