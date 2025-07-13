import 'dart:developer' as developer;
import 'lib/core/services/timestamp_service.dart';
import 'lib/core/models/message_model.dart';
import 'lib/core/models/file_metadata_model.dart';
import 'lib/core/models/user_model.dart';

/// Test script to verify timestamp handling across the application
void main() {
  developer.log('🧪 Starting timestamp system tests...');
  developer.log('=' * 50);

  // Test TimestampService
  testTimestampService();

  // Test MessageModel timestamp parsing
  testMessageModelTimestamps();

  // Test FileMetadataModel timestamp parsing
  testFileMetadataModelTimestamps();

  // Test UserModel timestamp parsing
  testUserModelTimestamps();

  developer.log('=' * 50);
  developer.log('✅ All timestamp tests completed!');
}

void testTimestampService() {
  developer.log('🔍 Testing TimestampService...');

  // Test various input formats
  final testCases = [
    null,
    '',
    'invalid-date',
    '2025-01-15T10:30:00.000Z', // Future date
    '2019-01-01T00:00:00.000Z', // Old date
    DateTime.now().toIso8601String(), // Valid current date
    DateTime.now().millisecondsSinceEpoch, // Unix timestamp (ms)
    DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unix timestamp (seconds)
    DateTime.now(), // DateTime object
  ];

  for (final testCase in testCases) {
    try {
      final result = TimestampService.parseAndValidateDateTime(testCase);
      developer.log(
        'Input: $testCase -> Output: ${result?.toIso8601String() ?? 'null'}',
      );
    } catch (e) {
      developer.log('Error with input $testCase: $e');
    }
  }

  // Test system time validation
  TimestampService.validateSystemTime();

  developer.log('✅ TimestampService tests completed');
}

void testMessageModelTimestamps() {
  developer.log('🔍 Testing MessageModel timestamp parsing...');

  // Test message with future timestamp
  final futureMessageJson = {
    '_id': 'test-message-1',
    'chatId': 'test-chat',
    'sender': {
      '_id': 'user1',
      'username': 'testuser',
      'email': 'test@example.com',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    },
    'content': 'Test message',
    'type': 'text',
    'status': 'sent',
    'createdAt': '2025-01-15T10:30:00.000Z', // Future timestamp
    'updatedAt': '2025-01-15T10:35:00.000Z', // Future timestamp
  };

  try {
    final message = MessageModel.fromJson(futureMessageJson);
    developer.log('Message created at: ${message.createdAt.toIso8601String()}');
    developer.log(
      'Message updated at: ${message.updatedAt?.toIso8601String() ?? 'null'}',
    );

    // Test toJson
    final jsonOutput = message.toJson();
    developer.log('JSON createdAt: ${jsonOutput['createdAt']}');
  } catch (e) {
    developer.log('Error creating message: $e');
  }

  developer.log('✅ MessageModel tests completed');
}

void testFileMetadataModelTimestamps() {
  developer.log('🔍 Testing FileMetadataModel timestamp parsing...');

  // Test file metadata with future timestamp
  final futureFileJson = {
    'id': 'test-file-1',
    'originalName': 'test.pdf',
    'fileName': 'test_123.pdf',
    'filePath': '/uploads/test_123.pdf',
    'fileUrl': 'http://localhost:3000/uploads/test_123.pdf',
    'mimeType': 'application/pdf',
    'fileSize': 1024,
    'fileExtension': 'pdf',
    'uploadedBy': 'user1',
    'uploadedAt': '2025-01-15T10:30:00.000Z', // Future timestamp
    'isDeleted': false,
  };

  try {
    final fileMetadata = FileMetadataModel.fromJson(futureFileJson);
    developer.log(
      'File uploaded at: ${fileMetadata.uploadedAt.toIso8601String()}',
    );

    // Test toJson
    final jsonOutput = fileMetadata.toJson();
    developer.log('JSON uploadedAt: ${jsonOutput['uploadedAt']}');
  } catch (e) {
    developer.log('Error creating file metadata: $e');
  }

  developer.log('✅ FileMetadataModel tests completed');
}

void testUserModelTimestamps() {
  developer.log('🔍 Testing UserModel timestamp parsing...');

  // Test user with future timestamp
  final futureUserJson = {
    '_id': 'test-user-1',
    'username': 'testuser',
    'email': 'test@example.com',
    'firstName': 'Test',
    'lastName': 'User',
    'status': 'online',
    'createdAt': '2025-01-15T10:30:00.000Z', // Future timestamp
    'updatedAt': '2025-01-15T10:35:00.000Z', // Future timestamp
    'lastSeen': '2025-01-15T10:40:00.000Z', // Future timestamp
  };

  try {
    final user = UserModel.fromJson(futureUserJson);
    developer.log('User created at: ${user.createdAt.toIso8601String()}');
    developer.log('User updated at: ${user.updatedAt.toIso8601String()}');
    developer.log(
      'User last seen: ${user.lastSeen?.toIso8601String() ?? 'null'}',
    );

    // Test toJson
    final jsonOutput = user.toJson();
    developer.log('JSON createdAt: ${jsonOutput['createdAt']}');
    developer.log('JSON lastSeen: ${jsonOutput['lastSeen']}');
  } catch (e) {
    developer.log('Error creating user: $e');
  }

  developer.log('✅ UserModel tests completed');
}
