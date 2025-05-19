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
      final cleaned = date.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
      final format = DateFormat("EEEE d MMMM yyyy", "fr_FR");
      return format.parse(cleaned);
    } catch (e) {
      debugPrint("⚠️ Erreur de parsing pour la date \"$date\": $e");
      return DateTime(2100);
    }
  }

  factory GameSession.fromMap(String id, Map data) {
    return GameSession(
      id: id,
      title: data['title'] ?? '',
      date: data['date'] ?? '',
      createdBy: data['createdBy'] ?? '',
      availability: Map<String, bool>.from(data['availability'] ?? {}),
      status: data['status'] ?? '',
      beerContributions: Map<String, int>.from(data['beerContributions'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {'date': date, 'createdBy': createdBy, 'availability': availability};
  }
}
