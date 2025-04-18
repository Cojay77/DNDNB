import 'dart:js' as js;
import 'package:flutter/material.dart';

class InstallPromptButton extends StatefulWidget {
  const InstallPromptButton({super.key});

  @override
  State<InstallPromptButton> createState() => _InstallPromptButtonState();
}

class _InstallPromptButtonState extends State<InstallPromptButton> {
  js.JsObject? _deferredPrompt;
  bool _isInstallable = false;

  @override
  void initState() {
    super.initState();

    // Écoute l’événement JS 'beforeinstallprompt'
    js.context.callMethod('addEventListener', [
      'beforeinstallprompt',
      (e) {
        e.callMethod('preventDefault');
        setState(() {
          _deferredPrompt = js.JsObject.fromBrowserObject(e);
          _isInstallable = true;
        });
      },
    ]);
  }

  void _triggerInstall() {
    if (_deferredPrompt != null) {
      _deferredPrompt!.callMethod('prompt');
      setState(() => _isInstallable = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("L'installation n'est pas disponible.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isInstallable
        ? ElevatedButton.icon(
          icon: const Icon(Icons.download),
          label: const Text("Installer l'application"),
          onPressed: _triggerInstall,
        )
        : const SizedBox.shrink(); // Rien si non dispo
  }
}
