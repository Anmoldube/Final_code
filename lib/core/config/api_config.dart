import 'environment.dart';

class ApiConfig {
  // Use environment configuration
  static String get baseUrl => Environment.baseUrl;
  static String get socketUrl => Environment.socketUrl;

  // API Endpoints
  static const String authEndpoint = '/auth';
  static const String chatEndpoint = '/api/chat';
  static const String messageEndpoint = '/api/messages';

  // Full API URLs
  static String get authUrl => '$baseUrl$authEndpoint';
  static String get chatUrl => '$baseUrl$chatEndpoint';
  static String get messageUrl => '$baseUrl$messageEndpoint';

  // Timeout configurations
  static Duration get connectTimeout => Environment.connectTimeout;
  static Duration get receiveTimeout => Environment.receiveTimeout;
  static Duration get sendTimeout => Environment.sendTimeout;

  // File upload configurations
  static int get maxFileSize => Environment.maxFileSize;
  static List<String> get allowedImageTypes => Environment.allowedImageTypes;
  static List<String> get allowedVideoTypes => Environment.allowedVideoTypes;
  static List<String> get allowedDocumentTypes => Environment.allowedDocumentTypes;

  // Socket events
  static const String newMessageEvent = 'newMessage';
  static const String messageUpdatedEvent = 'messageUpdated';
  static const String messageDeletedEvent = 'messageDeleted';
  static const String typingEvent = 'typing';
  static const String stopTypingEvent = 'stopTyping';
  static const String userOnlineEvent = 'userOnline';
  static const String userOfflineEvent = 'userOffline';
  static const String joinChatEvent = 'joinChat';
  static const String leaveChatEvent = 'leaveChat';

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
}
