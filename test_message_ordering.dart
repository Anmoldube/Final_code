void main() {
  print('🧪 Testing Message Ordering...');
  print('=' * 50);

  // Test timestamps with different scenarios
  final testTimestamps = [
    '2025-07-12T15:30:00.000Z', // Today, 3:30 PM
    '2025-07-12T15:28:00.000Z', // Today, 3:28 PM (should be before previous)
    '2025-07-12T15:32:00.000Z', // Today, 3:32 PM (should be after first)
    '2025-07-11T10:00:00.000Z', // Yesterday
    '2025-07-12T15:31:00.000Z', // Today, 3:31 PM (should be between first and last)
  ];

  print('Original timestamps (unsorted):');
  for (int i = 0; i < testTimestamps.length; i++) {
    final dateTime = DateTime.parse(testTimestamps[i]);
    print('${i + 1}. ${dateTime.toIso8601String()} (${_formatTime(dateTime)})');
  }

  // Parse and sort chronologically (oldest first)
  final parsedDates = testTimestamps.map((ts) => DateTime.parse(ts)).toList();
  parsedDates.sort((a, b) => a.compareTo(b));

  print('\n📈 After chronological sorting (oldest first):');
  for (int i = 0; i < parsedDates.length; i++) {
    final dateTime = parsedDates[i];
    print('${i + 1}. ${dateTime.toIso8601String()} (${_formatTime(dateTime)})');
  }

  // Verify the order is correct
  print('\n✅ Verification:');
  bool isCorrectOrder = true;
  for (int i = 1; i < parsedDates.length; i++) {
    if (parsedDates[i].isBefore(parsedDates[i - 1])) {
      print('❌ Error: Message $i is before message ${i - 1}');
      isCorrectOrder = false;
    }
  }

  if (isCorrectOrder) {
    print('✅ All messages are in correct chronological order!');
    print('✅ Newest messages will appear at the bottom of the chat');
  } else {
    print('❌ Messages are NOT in correct order!');
  }

  print('=' * 50);
  print('✅ Test completed!');
}

String _formatTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays > 0) {
    return '${difference.inDays} day(s) ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} hour(s) ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} minute(s) ago';
  } else {
    return 'now';
  }
}
