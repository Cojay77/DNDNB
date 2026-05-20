import 'package:flutter/material.dart';
import 'package:dndnb/utils/platform_utils.dart';

/// PWA install prompt button.
/// Only visible on web when the browser supports install prompts (non-iOS).
class InstallPromptButton extends StatelessWidget {
  const InstallPromptButton({super.key});

  @override
  Widget build(BuildContext context) {
    // On non-web platforms, isAppInstalled() returns false and
    // promptInstall() is a no-op, so this widget will just show the button
    // which does nothing — but it should only be rendered when kIsWeb is true.
    return ElevatedButton.icon(
      icon: const Icon(Icons.download),
      label: const Text("Installer l'application"),
      onPressed: () => promptInstall(),
    );
  }
}
