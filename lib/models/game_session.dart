import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GameSession {
  String id;
  String title;
  String date;
  String createdBy;
  Map<String, bool> availability;
  String status;
  Map<String, int> beerContributions;

  GameSession({
    required this.id,
    required this.title,
    required this.date,
    required this.createdBy,
    required this.availability,
    this.status = "prévue",
    required this.beerContributions,
  });

  DateTime get parsedDate {
    try {
      // First try standard ISO 8601 parsing (the new format)
      return DateTime.parse(date);
    } catch (_) {
      // Fallback for old French string format if any data is left over
      try {
        final cleaned = date.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
        final format = DateFormat("EEEE d MMMM yyyy", "fr_FR");
        return format.parse(cleaned);
      } catch (e) {
        debugPrint("⚠️ Erreur de parsing absolue pour la date \"$date\": $e");
        return DateTime(2100);
      }
    }
  }

  String get displayDate {
    try {
      final dt = parsedDate;
      if (dt.year == 2100) return date; // fallback to raw string if parsing failed
      
      final formatter = DateFormat("EEEE d MMMM yyyy", "fr_FR");
      final raw = formatter.format(dt);
      return raw[0].toUpperCase() + raw.substring(1);
    } catch (_) {
      return date;
    }
  }

  String get shortDisplayDate {
    try {
      final dt = parsedDate;
      if (dt.year == 2100) return date;
      
      final formatter = DateFormat("d MMM yyyy", "fr_FR");
      return formatter.format(dt);
    } catch (_) {
      return date;
    }
  }

  factory GameSession.fromMap(String id, Map data) {
    return GameSession(
      id: id,
      title: data['title'] ?? '',
      date: data['date'] ?? '',
      createdBy: data['createdBy'] ?? '',
      availability: Map<String, bool>.from(data['availability'] ?? {}),
      status: data['status'] ?? 'prévue',
      beerContributions: Map<String, int>.from(data['beerContributions'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': date,
      'createdBy': createdBy,
      'availability': availability,
      'status': status,
      'beerContributions': beerContributions,
    };
  }
}
