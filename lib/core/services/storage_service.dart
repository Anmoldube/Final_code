import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class StorageService {
  static late SharedPreferences _prefs;
  static late FlutterSecureStorage _secureStorage;
  static late Box _userBox;
  static late Box _chatBox;
  static late Box _messageBox;
  static late Box _settingsBox;
  static late Box _secureBox; // For web fallback
  static late encrypt.Encrypter _encrypter;
  static late encrypt.Key _encryptionKey;

  static const String _userBoxName = 'user_box';
  static const String _chatBoxName = 'chat_box';
  static const String _messageBoxName = 'message_box';
  static const String _settingsBoxName = 'settings_box';
  static const String _secureBoxName = 'secure_box';

  // Keys for secure storage
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _encryptionKeyName = 'encryption_key';

  // Keys for regular storage
  static const String _userIdKey = 'user_id';
  static const String _isFirstLaunchKey = 'is_first_launch';
  static const String _themeMode = 'theme_mode';
  static const String _notificationsEnabled = 'notifications_enabled';
  static const String _soundEnabled = 'sound_enabled';

  static Future<void> initialize() async {
    // Initialize shared preferences
    _prefs = await SharedPreferences.getInstance();

    // Initialize secure storage
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      wOptions: WindowsOptions(),
      lOptions: LinuxOptions(),
      mOptions: MacOsOptions(),
    );

    // Initialize Hive boxes
    _userBox = await Hive.openBox(_userBoxName);
    _chatBox = await Hive.openBox(_chatBoxName);
    _messageBox = await Hive.openBox(_messageBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);

    // Initialize secure box for web fallback
    if (kIsWeb) {
      _secureBox = await Hive.openBox(_secureBoxName);
      // Initialize encryption for web
      await _initializeWebEncryption();
    }
  }

  static Future<void> _initializeWebEncryption() async {
    // Generate or retrieve encryption key for web
    String? keyString = _prefs.getString('web_encryption_key');

    if (keyString == null) {
      // Generate a new encryption key
      _encryptionKey = encrypt.Key.fromSecureRandom(32);
      keyString = _encryptionKey.base64;

      // Save the key for future use
      await _prefs.setString('web_encryption_key', keyString);
      debugPrint('🔑 StorageService: Generated new encryption key for web');
    } else {
      _encryptionKey = encrypt.Key.fromBase64(keyString);
      debugPrint(
        '🔑 StorageService: Retrieved existing encryption key for web',
      );
    }

    _encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
  }

  // Token management
  static Future<void> saveAccessToken(String token) async {
    if (kIsWeb) {
      await _saveSecureWeb(_accessTokenKey, token);
    } else {
      await _secureStorage.write(key: _accessTokenKey, value: token);
    }
    debugPrint('🔑 StorageService: Saved access token');
  }

  static Future<String?> getAccessToken() async {
    String? token;
    if (kIsWeb) {
      token = await _getSecureWeb(_accessTokenKey);
    } else {
      token = await _secureStorage.read(key: _accessTokenKey);
    }
    debugPrint(
      '🔑 StorageService: Getting access token - found: ${token != null}',
    );
    return token;
  }

  static Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      await _saveSecureWeb(_refreshTokenKey, token);
    } else {
      await _secureStorage.write(key: _refreshTokenKey, value: token);
    }
  }

  static Future<String?> getRefreshToken() async {
    if (kIsWeb) {
      return await _getSecureWeb(_refreshTokenKey);
    } else {
      return await _secureStorage.read(key: _refreshTokenKey);
    }
  }

  static Future<void> saveEncryptionKey(String key) async {
    if (kIsWeb) {
      await _saveSecureWeb(_encryptionKeyName, key);
    } else {
      await _secureStorage.write(key: _encryptionKeyName, value: key);
    }
  }

  static Future<String?> getEncryptionKey() async {
    if (kIsWeb) {
      return await _getSecureWeb(_encryptionKeyName);
    } else {
      return await _secureStorage.read(key: _encryptionKeyName);
    }
  }

  static Future<void> clearTokens() async {
    if (kIsWeb) {
      await _secureBox.delete(_accessTokenKey);
      await _secureBox.delete(_refreshTokenKey);
    } else {
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
    }
  }

  // Web-safe secure storage methods
  static Future<void> _saveSecureWeb(String key, String value) async {
    try {
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypted = _encrypter.encrypt(value, iv: iv);
      final secureData = {'data': encrypted.base64, 'iv': iv.base64};
      await _secureBox.put(key, secureData);
    } catch (e) {
      debugPrint('🔒 Web secure storage save error: $e');
      // Fallback to plain storage (not recommended for production)
      await _secureBox.put(key, value);
    }
  }

  static Future<String?> _getSecureWeb(String key) async {
    try {
      final secureData = _secureBox.get(key);
      if (secureData == null) return null;

      if (secureData is Map) {
        final encrypted = encrypt.Encrypted.fromBase64(secureData['data']);
        final iv = encrypt.IV.fromBase64(secureData['iv']);
        return _encrypter.decrypt(encrypted, iv: iv);
      } else {
        // Fallback for plain storage
        return secureData.toString();
      }
    } catch (e) {
      debugPrint('🔒 Web secure storage read error: $e');
      return null;
    }
  }

  // User data management
  static Future<void> saveUserId(String userId) async {
    await _prefs.setString(_userIdKey, userId);
  }

  static String? getUserId() {
    return _prefs.getString(_userIdKey);
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    await _userBox.put('current_user', userData);
  }

  static Map<String, dynamic>? getUserData() {
    return _userBox.get('current_user')?.cast<String, dynamic>();
  }

  static Future<void> clearUserData() async {
    await _prefs.remove(_userIdKey);
    await _userBox.clear();
  }

  // Chat data management
  static Future<void> saveChatData(
    String chatId,
    Map<String, dynamic> chatData,
  ) async {
    await _chatBox.put(chatId, chatData);
  }

  static Map<String, dynamic>? getChatData(String chatId) {
    return _chatBox.get(chatId)?.cast<String, dynamic>();
  }

  static Future<void> saveChatsList(List<Map<String, dynamic>> chats) async {
    try {
      // Convert to a format that Hive can handle
      final chatsList = chats
          .map((chat) => Map<String, dynamic>.from(chat))
          .toList();
      await _chatBox.put('chats_list', chatsList);
    } catch (e) {
      print('Error saving chats list: $e');
    }
  }

  static List<Map<String, dynamic>>? getChatsList() {
    try {
      final chats = _chatBox.get('chats_list');
      if (chats != null && chats is List) {
        return chats.map((chat) => Map<String, dynamic>.from(chat)).toList();
      }
      return null;
    } catch (e) {
      print('Error getting chats list: $e');
      return null;
    }
  }

  static Future<void> clearChatData() async {
    await _chatBox.clear();
  }

  // Message data management
  static Future<void> saveMessages(
    String chatId,
    List<Map<String, dynamic>> messages,
  ) async {
    await _messageBox.put('messages_$chatId', messages);
  }

  static List<Map<String, dynamic>>? getMessages(String chatId) {
    final messages = _messageBox.get('messages_$chatId');
    if (messages != null) {
      return List<Map<String, dynamic>>.from(messages);
    }
    return null;
  }

  static Future<void> addMessage(
    String chatId,
    Map<String, dynamic> message,
  ) async {
    final existingMessages = getMessages(chatId) ?? [];
    existingMessages.add(message);
    await saveMessages(chatId, existingMessages);
  }

  static Future<void> updateMessage(
    String chatId,
    String messageId,
    Map<String, dynamic> updatedMessage,
  ) async {
    final messages = getMessages(chatId) ?? [];
    final index = messages.indexWhere((msg) => msg['_id'] == messageId);
    if (index != -1) {
      messages[index] = updatedMessage;
      await saveMessages(chatId, messages);
    }
  }

  static Future<void> deleteMessage(String chatId, String messageId) async {
    final messages = getMessages(chatId) ?? [];
    messages.removeWhere((msg) => msg['_id'] == messageId);
    await saveMessages(chatId, messages);
  }

  static Future<void> clearMessages(String chatId) async {
    await _messageBox.delete('messages_$chatId');
  }

  static Future<void> clearAllMessages() async {
    final keys = _messageBox.keys.where(
      (key) => key.toString().startsWith('messages_'),
    );
    for (final key in keys) {
      await _messageBox.delete(key);
    }
  }

  // Settings management
  static Future<void> setFirstLaunch(bool isFirstLaunch) async {
    await _prefs.setBool(_isFirstLaunchKey, isFirstLaunch);
  }

  static bool isFirstLaunch() {
    return _prefs.getBool(_isFirstLaunchKey) ?? true;
  }

  // Theme settings
  static Future<void> setThemeMode(String mode) async {
    await _settingsBox.put(_themeMode, mode);
  }

  static String getThemeMode() {
    return _settingsBox.get(_themeMode, defaultValue: 'system');
  }

  // Settings Helpers
  static bool getNotificationsEnabled() {
    return _settingsBox.get(_notificationsEnabled, defaultValue: true);
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    await _settingsBox.put(_notificationsEnabled, value);
  }

  static bool getSoundEnabled() {
    return _settingsBox.get(_soundEnabled, defaultValue: true);
  }

  static Future<void> setSoundEnabled(bool value) async {
    await _settingsBox.put(_soundEnabled, value);
  }

  // General settings
  static Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  static T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  // Cache management
  static Future<void> saveToCache(String key, dynamic value) async {
    await _settingsBox.put('cache_$key', value);
  }

  static T? getFromCache<T>(String key, {T? defaultValue}) {
    return _settingsBox.get('cache_$key', defaultValue: defaultValue);
  }

  static Future<void> clearCache() async {
    final keys = _settingsBox.keys.where(
      (key) => key.toString().startsWith('cache_'),
    );
    for (final key in keys) {
      await _settingsBox.delete(key);
    }
  }

  // Logout and clear all data
  static Future<void> clearAllData() async {
    await clearTokens();
    await clearUserData();
    await clearChatData();
    await clearAllMessages();
    await clearCache();
    if (kIsWeb) {
      await _secureBox.clear();
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    final userId = getUserId();
    return token != null && userId != null;
  }

  // Database information
  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    return {
      'user_box_length': _userBox.length,
      'chat_box_length': _chatBox.length,
      'message_box_length': _messageBox.length,
      'settings_box_length': _settingsBox.length,
      'has_access_token': await getAccessToken() != null,
      'has_refresh_token': await getRefreshToken() != null,
      'user_id': getUserId(),
      'is_first_launch': isFirstLaunch(),
    };
  }

  // Server URL management
  static Future<String?> getServerUrl() async {
    // You can implement logic to fetch from settings or remote config
    // For now, return a default value
    return 'http://192.168.1.6:5000';
  }

  // Save credentials for offline login
  static Future<void> saveCredentials(String email, String password) async {
    try {
      final credentials = {
        'email': email,
        'password': password,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Encrypt the credentials
      final encryptedCredentials = _encrypt(credentials.toString());

      // Save to secure storage
      await _secureStorage.write(
        key: 'offline_credentials',
        value: encryptedCredentials,
      );

      debugPrint('✅ StorageService: Saved credentials for offline login');
    } catch (e) {
      debugPrint('❌ StorageService: Error saving credentials: $e');
    }
  }

  // Get credentials for offline login
  static Future<Map<String, String>?> getCredentials() async {
    try {
      final encryptedCredentials = await _secureStorage.read(
        key: 'offline_credentials',
      );
      if (encryptedCredentials == null) {
        return null;
      }

      // Decrypt the credentials
      final decryptedCredentials = _decrypt(encryptedCredentials);

      // Parse the credentials
      final credentialsString = decryptedCredentials
          .replaceAll('{', '')
          .replaceAll('}', '');
      final credentialsParts = credentialsString.split(',');

      final credentials = <String, String>{};
      for (final part in credentialsParts) {
        final keyValue = part.trim().split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim().replaceAll("'", '');
          final value = keyValue[1].trim().replaceAll("'", '');
          credentials[key] = value;
        }
      }

      if (credentials.containsKey('email') &&
          credentials.containsKey('password')) {
        return {
          'email': credentials['email']!,
          'password': credentials['password']!,
        };
      }

      return null;
    } catch (e) {
      debugPrint('❌ StorageService: Error getting credentials: $e');
      return null;
    }
  }

  // Clear credentials
  static Future<void> clearCredentials() async {
    try {
      await _secureStorage.delete(key: 'offline_credentials');
      debugPrint('✅ StorageService: Cleared credentials');
    } catch (e) {
      debugPrint('❌ StorageService: Error clearing credentials: $e');
    }
  }

  // Methods for unsynced messages and chats

  // Save unsynced messages
  static Future<void> saveUnsyncedMessages(
    List<Map<String, dynamic>> messages,
  ) async {
    try {
      await _messageBox.put('unsynced_messages', messages);
      debugPrint(
        '✅ StorageService: Saved ${messages.length} unsynced messages',
      );
    } catch (e) {
      debugPrint('❌ StorageService: Error saving unsynced messages: $e');
    }
  }

  // Get unsynced messages
  static List<Map<String, dynamic>>? getUnsyncedMessages() {
    try {
      final data = _messageBox.get('unsynced_messages');
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('❌ StorageService: Error getting unsynced messages: $e');
      return [];
    }
  }

  // Save unsynced chats
  static Future<void> saveUnsyncedChats(
    List<Map<String, dynamic>> chats,
  ) async {
    try {
      await _chatBox.put('unsynced_chats', chats);
      debugPrint('✅ StorageService: Saved ${chats.length} unsynced chats');
    } catch (e) {
      debugPrint('❌ StorageService: Error saving unsynced chats: $e');
    }
  }

  // Get unsynced chats
  static List<Map<String, dynamic>>? getUnsyncedChats() {
    try {
      final data = _chatBox.get('unsynced_chats');
      if (data == null) return [];
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('❌ StorageService: Error getting unsynced chats: $e');
      return [];
    }
  }

  // Encrypt a string
  static String _encrypt(String plainText) {
    if (kIsWeb) {
      // Use web encrypter
      final encrypted = _encrypter.encrypt(
        plainText,
        iv: encrypt.IV.fromLength(16),
      );
      return encrypted.base64;
    } else {
      final key = _encryptionKey;
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final iv = encrypt.IV.fromLength(16);
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return encrypted.base64;
    }
  }

  // Decrypt a string
  static String _decrypt(String encryptedText) {
    if (kIsWeb) {
      final decrypted = _encrypter.decrypt64(
        encryptedText,
        iv: encrypt.IV.fromLength(16),
      );
      return decrypted;
    } else {
      final key = _encryptionKey;
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final iv = encrypt.IV.fromLength(16);
      final decrypted = encrypter.decrypt64(encryptedText, iv: iv);
      return decrypted;
    }
  }
}
