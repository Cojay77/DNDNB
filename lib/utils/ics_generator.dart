import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

Future<File> generateICSFile({
  required String title,
  required String description,
  required DateTime start,
  required DateTime end,
}) async {
  final buffer = StringBuffer();

  String formatDate(DateTime date) {
    return DateFormat("yyyyMMdd'T'HHmmss'Z'").format(date.toUtc());
  }

  buffer.writeln('BEGIN:VCALENDAR');
  buffer.writeln('VERSION:2.0');
  buffer.writeln('PRODID:-//dndapp//FR');
  buffer.writeln('BEGIN:VEVENT');
  buffer.writeln('UID:${DateTime.now().millisecondsSinceEpoch}@dndapp.com');
  buffer.writeln('DTSTAMP:${formatDate(DateTime.now())}');
  buffer.writeln('DTSTART:${formatDate(start)}');
  buffer.writeln('DTEND:${formatDate(end)}');
  buffer.writeln('SUMMARY:$title');
  buffer.writeln('DESCRIPTION:$description');
  buffer.writeln('END:VEVENT');
  buffer.writeln('END:VCALENDAR');

  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/session_dnd.ics');
  return file.writeAsString(buffer.toString());
}
