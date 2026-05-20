// Web-specific implementations using dart:js_interop and package:web (modern replacements for dart:js and dart:html)
import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('isInStandaloneMode')
external bool isInStandaloneModeJs();

@JS('promptInstall')
external void promptInstallJs();

bool isIOSBrowser() {
  final userAgent = web.window.navigator.userAgent.toLowerCase();
  return userAgent.contains('iphone') || userAgent.contains('ipad');
}

bool isAppInstalled() {
  try {
    return isInStandaloneModeJs();
  } catch (_) {
    return false;
  }
}

void promptInstall() {
  try {
    promptInstallJs();
  } catch (_) {
    // Install prompt not available
  }
}

void reloadPage() {
  web.window.location.reload();
}

void downloadFile(String fileName, String content, String mimeType) {
  final blob = web.Blob([content.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..setAttribute("download", fileName);
  anchor.click();
  web.URL.revokeObjectURL(url);
}
