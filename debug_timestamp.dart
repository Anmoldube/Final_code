import 'lib/core/services/timestamp_service.dart';
import 'lib/core/models/message_model.dart';
import 'lib/core/models/user_model.dart';

void main() {
  print('🧪 Debugging Timestamp Issue...');
  print('=' * 50);

  // Test 1: Check current timestamp
  final now = TimestampService.getCurrentTimestamp();
  print('Current timestamp: ${now.toIso8601String()}');
  print('Current year: ${now.year}');
  print('Current month: ${now.month}');
  print('Current day: ${now.day}');

  // Test 2: Check problematic timestamp
  final problematicTimestamp = '2025-12-07T10:46:54.894Z';
  final parsed = TimestampService.parseAndValidateDateTime(
    problematicTimestamp,
  );
  print('\nProblematic timestamp: $problematicTimestamp');
  print('Parsed timestamp: ${parsed?.toIso8601String()}');
  print('Parsed year: ${parsed?.year}');
  print('Parsed month: ${parsed?.month}');
  print('Parsed day: ${parsed?.day}');

  // Test 3: Check format timestamp
  final formattedTime = TimestampService.formatTimestamp(parsed);
  print('\nFormatted time: $formattedTime');

  // Test 4: Check relative time
  final relativeTime = TimestampService.getRelativeTimeString(parsed);
  print('Relative time: $relativeTime');

  // Test 5: Create a message and see how it's displayed
  final testUser = UserModel(
    id: 'test-user',
    username: 'testuser',
    email: 'test@example.com',
    firstName: 'Test',
    lastName: 'User',
    createdAt: now,
    updatedAt: now,
  );

  final testMessage = MessageModel(
    id: 'test-message',
    chatId: 'test-chat',
    sender: testUser,
    content: 'Test message',
    createdAt: parsed ?? now,
  );

  print('\nMessage created at: ${testMessage.createdAt.toIso8601String()}');
  print('Message created at year: ${testMessage.createdAt.year}');

  print('=' * 50);
  print('✅ Debug completed!');
}
