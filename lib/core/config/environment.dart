class Environment {
  // Server Configuration - Change this IP to switch environments
  static const String serverIp = '192.168.1.6'; // Your server IP
  static const String serverPort = '5000';
  static const bool useHttps = false;

  // Computed URLs
  static String get baseUrl =>
      '${useHttps ? 'https' : 'http'}://$serverIp:$serverPort';
  static String get socketUrl => baseUrl;
  static String get apiUrl => '$baseUrl/api';

  // Development flags
  static const bool isDevelopment = true;
  static const bool enableLogging = true;

  // File upload configuration
  static const int maxFileSize = 50 * 1024 * 1024; // 50MB
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
  ];

  static const List<String> allowedVideoTypes = [
    'video/mp4',
    'video/avi',
    'video/mov',
    'video/wmv',
  ];

  static const List<String> allowedDocumentTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'text/plain',
  ];

  // Network timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
