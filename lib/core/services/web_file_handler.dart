// This file contains web-specific file handling functionality
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Download a file in web browser
Future<bool> downloadFileInBrowser(String url, String fileName) async {
  try {
    // Create a hidden anchor element
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    // Add to the DOM
    html.document.body?.children.add(anchor);

    // Trigger click and then remove from DOM
    anchor.click();

    // Use Future.delayed to ensure the click is processed
    await Future.delayed(const Duration(milliseconds: 100));
    anchor.remove();

    debugPrint('✅ Web download initiated for: $fileName');
    return true;
  } catch (e) {
    debugPrint('❌ Web download error: $e');
    return false;
  }
}

/// Open a file in web browser
Future<bool> openFileInBrowser(String url, {String? target = '_blank'}) async {
  try {
    html.window.open(url, target ?? '_blank');
    return true;
  } catch (e) {
    debugPrint('❌ Error opening file in web browser: $e');

    // Try alternative method as fallback
    try {
      final link = html.AnchorElement()
        ..href = url
        ..target = target ?? '_blank'
        ..rel = 'noopener noreferrer'
        ..click();

      return true;
    } catch (fallbackError) {
      debugPrint('❌ Fallback method also failed: $fallbackError');
      return false;
    }
  }
}

/// Check if a file type is viewable in browser
bool isViewableInBrowser(String fileName) {
  final extension = fileName.toLowerCase().split('.').last;

  // File types that most browsers can display natively
  const viewableExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg', // Images
    'pdf', // PDF (most browsers have built-in viewers)
    'txt', 'html', 'htm', 'css', 'js', 'json', 'csv', // Text files
    'mp4', 'webm', // Common video formats
    'mp3', 'wav', 'ogg', // Common audio formats
  ];

  return viewableExtensions.contains(extension);
}
