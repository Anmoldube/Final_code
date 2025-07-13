import 'dart:developer' as developer;
import 'lib/core/services/timestamp_service.dart';

/// Test the complete timestamp fix
void main() {
  developer.log('🧪 Testing Complete Timestamp Fix...');
  developer.log('=' * 50);

  // Test the current year validation
  testCurrentYear();

  // Test future timestamp correction
  testFutureTimestampCorrection();

  // Test system time validation
  testSystemTimeValidation();

  developer.log('=' * 50);
  developer.log('✅ All timestamp fix tests completed!');
}

void testCurrentYear() {
  developer.log('🔍 Test 1: Current Year Validation');

  final now = TimestampService.getCurrentTimestamp();
  final currentYear = now.year;

  developer.log('Current timestamp year: $currentYear');

  if (currentYear == 2024) {
    developer.log('✅ Current year is correctly set to 2024');
  } else {
    developer.log('❌ Current year is $currentYear, should be 2024');
  }
}

void testFutureTimestampCorrection() {
  developer.log('\n🔍 Test 2: Future Timestamp Correction');

  // Test correcting a 2025 timestamp to 2024
  final futureTimestamp = '2025-12-07T10:46:54.894Z';
  developer.log('Testing future timestamp: $futureTimestamp');

  final correctedTimestamp = TimestampService.parseAndValidateDateTime(
    futureTimestamp,
  );

  if (correctedTimestamp != null) {
    final correctedYear = correctedTimestamp.year;
    developer.log('Corrected timestamp year: $correctedYear');
    developer.log(
      'Corrected timestamp: ${correctedTimestamp.toIso8601String()}',
    );

    if (correctedYear == 2024) {
      developer.log('✅ Future timestamp correctly corrected to 2024');
    } else {
      developer.log('❌ Future timestamp not corrected properly');
    }
  } else {
    developer.log('❌ Failed to parse timestamp');
  }
}

void testSystemTimeValidation() {
  developer.log('\n🔍 Test 3: System Time Validation');

  final isSystemTimeReasonable = TimestampService.isSystemTimeReasonable();

  if (isSystemTimeReasonable) {
    developer.log('✅ System time validation passed');
  } else {
    developer.log(
      '⚠️  System time validation failed - system clock may be incorrect',
    );
  }

  // Run validation
  TimestampService.validateSystemTime();
}
