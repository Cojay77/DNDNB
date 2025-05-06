import 'dart:io' as io show File;
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

Future<void> shareICSFile(
  BuildContext context,
  String fileName,
  String content,
) async {
  try {
    if (kIsWeb) {
      final blob = html.Blob([content], 'text/calendar');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$fileName';
      final file = io.File(path);
      await file.writeAsString(content);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: "Ajoute cette session à ton calendrier !");
    }
  } catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Erreur lors du partage : $e")));
  }
}
