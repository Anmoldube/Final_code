void main() {
  print('🧪 Simple Timestamp Test...');
  print('=' * 50);

  // Test 1: Check current system time
  final systemNow = DateTime.now();
  print('System time: ${systemNow.toIso8601String()}');
  print('System year: ${systemNow.year}');

  // Test 2: Parse problematic timestamp
  final problematicTimestamp = '2025-12-07T10:46:54.894Z';
  final parsedDate = DateTime.parse(problematicTimestamp);
  print('\nOriginal problematic timestamp: $problematicTimestamp');
  print('Parsed original: ${parsedDate.toIso8601String()}');
  print('Parsed year: ${parsedDate.year}');

  // Test 3: Apply our NEW correction logic (only for obviously wrong years)
  final currentYear = DateTime.now().year;
  DateTime correctedDate;
  if (parsedDate.year > currentYear + 1) {
    correctedDate = DateTime(
      currentYear,
      parsedDate.month,
      parsedDate.day,
      parsedDate.hour,
      parsedDate.minute,
      parsedDate.second,
      parsedDate.millisecond,
    );
    print('\n🔧 Applied correction (year > current + 1):');
    print('Corrected: ${correctedDate.toIso8601String()}');
    print('Corrected year: ${correctedDate.year}');
  } else {
    correctedDate = parsedDate;
    print('\n✅ No correction needed - year $parsedDate.year is acceptable');
  }

  // Test 4: Check date formatting
  print('\nDate formatting tests:');
  print(
    'dd/MM/yyyy format: ${correctedDate.day.toString().padLeft(2, '0')}/${correctedDate.month.toString().padLeft(2, '0')}/${correctedDate.year}',
  );
  print(
    'MM/dd/yyyy format: ${correctedDate.month.toString().padLeft(2, '0')}/${correctedDate.day.toString().padLeft(2, '0')}/${correctedDate.year}',
  );

  // Test 5: Test the difference calculation
  final now = DateTime.now();
  final difference = now.difference(correctedDate);
  print('\nTime difference:');
  print('Days difference: ${difference.inDays}');
  print('Hours difference: ${difference.inHours}');
  print('Minutes difference: ${difference.inMinutes}');

  // Test 6: Test the relative time format (the one causing the issue)
  print('\nRelative time format test:');
  // Simulate an old message (more than 30 days ago)
  final oldDate = DateTime(2024, 11, 7, 10, 46, 54); // November 7, 2024
  final dayFormatted = oldDate.day.toString().padLeft(2, '0');
  final monthFormatted = oldDate.month.toString().padLeft(2, '0');
  final hour = oldDate.hour.toString().padLeft(2, '0');
  final minute = oldDate.minute.toString().padLeft(2, '0');
  final relativeFormat =
      '$dayFormatted/$monthFormatted/${oldDate.year} $hour:$minute IST';
  print('Old message format: $relativeFormat');

  print('=' * 50);
  print('✅ Simple test completed!');
}
