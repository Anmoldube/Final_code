// This is a stub implementation for non-web platforms
// It provides the same API as web_file_handler.dart but with no-op implementations

/// Stub for downloadFileInBrowser
Future<bool> downloadFileInBrowser(String url, String fileName) async {
  // This function is not used on non-web platforms
  return false;
}

/// Stub for openFileInBrowser
Future<bool> openFileInBrowser(String url, {String? target}) async {
  // This function is not used on non-web platforms
  return false;
}

/// Stub for isViewableInBrowser
bool isViewableInBrowser(String fileName) {
  // This function is not used on non-web platforms
  return false;
}
