import 'dart:io' as io show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:dndnb/utils/platform_utils.dart';

Future<void> shareICSFile(
  BuildContext context,
  String fileName,
  String content,
) async {
  try {
    if (kIsWeb) {
      downloadFile(fileName, content, 'text/calendar');
    } else {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/$fileName';
      final file = io.File(path);
      await file.writeAsString(content);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: "Ajoute cette session à ton calendrier !",
        ),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Erreur lors du partage : $e")));
  }
}
