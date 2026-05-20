import 'package:intl/intl.dart';

/// Parses the French-formatted session date strings used throughout the app
/// (e.g. "Samedi 24 mai 2025") into a [DateTime] at 19:00 local time.
///
/// Returns `null` if parsing fails — callers must handle null gracefully.
DateTime? parseSessionDate(String dateStr) {
  // Normalise: trim, collapse spaces, lowercase for parsing
  final normalised = dateStr
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase();

  // Try common French patterns — order: most specific first
  final formats = [
    'EEEE d MMMM yyyy',   // "samedi 24 mai 2025"
    'EEEE dd MMMM yyyy',  // "samedi 04 mai 2025"
    'd MMMM yyyy',        // "24 mai 2025"
    'dd MMMM yyyy',       // "04 mai 2025"
  ];

  for (final fmt in formats) {
    try {
      final parsed = DateFormat(fmt, 'fr_FR').parseLoose(normalised);
      // Default session time: 19:00 local
      return DateTime(parsed.year, parsed.month, parsed.day, 19, 0);
    } catch (_) {
      // Try next format
    }
  }

  return null;
}

/// Returns a human-readable countdown string for a session date.
/// - "Aujourd'hui !" if same day
/// - "Demain !" if tomorrow
/// - "Dans X jours" for future
/// - "Il y a X jours" for past
/// - "" if the date cannot be parsed
String sessionCountdown(String dateStr) {
  final dt = parseSessionDate(dateStr);
  if (dt == null) return '';

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sessionDay = DateTime(dt.year, dt.month, dt.day);
  final diff = sessionDay.difference(today).inDays;

  if (diff == 0) return "Aujourd'hui !";
  if (diff == 1) return "Demain !";
  if (diff > 1) return "Dans $diff jours";
  if (diff == -1) return "Hier";
  return "Il y a ${diff.abs()} jours";
}
