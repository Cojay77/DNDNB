// Stub implementations for non-web platforms.
// These are replaced by platform_utils_web.dart on web.

bool isIOSBrowser() => false;

bool isAppInstalled() => false;

void promptInstall() {
  // No-op on non-web platforms
}

void reloadPage() {
  // No-op on non-web platforms
}

void downloadFile(String fileName, String content, String mimeType) {
  // No-op on non-web platforms
}
