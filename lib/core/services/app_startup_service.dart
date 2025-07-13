import 'dart:developer' as developer;
import 'timestamp_service.dart';

/// Service to handle app startup validations including timestamp checks
class AppStartupService {
  static const String _logTag = 'AppStartupService';
  static bool _hasRunStartupChecks = false;

  /// Run all startup validations
  static Future<void> runStartupValidations() async {
    if (_hasRunStartupChecks) {
      developer.log('Startup validations already completed', name: _logTag);
      return;
    }

    developer.log('🚀 Running app startup validations...', name: _logTag);
    developer.log('=' * 50, name: _logTag);

    try {
      // Validate system time
      await _validateSystemTime();

      // Validate app configuration
      await _validateAppConfiguration();

      // Mark as completed
      _hasRunStartupChecks = true;

      developer.log(
        '✅ All startup validations completed successfully',
        name: _logTag,
      );
    } catch (error) {
      developer.log('❌ Startup validation error: $error', name: _logTag);
      // Don't throw - let the app continue with warnings
    }

    developer.log('=' * 50, name: _logTag);
  }

  /// Validate system time and timestamp handling
  static Future<void> _validateSystemTime() async {
    developer.log('🕐 Validating system time...', name: _logTag);

    // Check if system time is reasonable
    TimestampService.validateSystemTime();

    // Test timestamp parsing
    await _testTimestampParsing();

    developer.log('✅ System time validation completed', name: _logTag);
  }

  /// Test timestamp parsing with various scenarios
  static Future<void> _testTimestampParsing() async {
    developer.log('🧪 Testing timestamp parsing...', name: _logTag);

    final testCases = [
      null,
      '',
      DateTime.now().toIso8601String(),
      DateTime.now().millisecondsSinceEpoch,
      DateTime.now(),
      '2025-01-01T00:00:00.000Z', // Future date
      '2019-01-01T00:00:00.000Z', // Old date
      'invalid-date',
      123456789, // Unix timestamp
    ];

    for (final testCase in testCases) {
      try {
        final result = TimestampService.parseAndValidateDateTime(testCase);
        developer.log(
          'Test case: $testCase -> ${result?.toIso8601String() ?? 'null'}',
          name: _logTag,
        );
      } catch (e) {
        developer.log('Test case failed: $testCase -> $e', name: _logTag);
      }
    }

    developer.log('✅ Timestamp parsing tests completed', name: _logTag);
  }

  /// Validate app configuration
  static Future<void> _validateAppConfiguration() async {
    developer.log('⚙️ Validating app configuration...', name: _logTag);

    // Check if we're in debug mode
    bool inDebugMode = false;
    assert(inDebugMode = true);

    if (inDebugMode) {
      developer.log('🐛 Running in DEBUG mode', name: _logTag);
    } else {
      developer.log('🚀 Running in PRODUCTION mode', name: _logTag);
    }

    // Validate current time
    final now = TimestampService.getCurrentTimestamp();
    developer.log('Current timestamp: ${now.toIso8601String()}', name: _logTag);

    developer.log('✅ App configuration validation completed', name: _logTag);
  }

  /// Force re-run startup validations (useful for debugging)
  static Future<void> forceRerunValidations() async {
    _hasRunStartupChecks = false;
    await runStartupValidations();
  }

  /// Check if startup validations have been completed
  static bool get hasCompletedStartupValidations => _hasRunStartupChecks;

  /// Get app startup info for debugging
  static Map<String, dynamic> getStartupInfo() {
    return {
      'hasCompletedStartupValidations': _hasRunStartupChecks,
      'currentTimestamp': TimestampService.getCurrentTimestamp()
          .toIso8601String(),
      'systemTimeReasonable': TimestampService.isSystemTimeReasonable(),
      'startupTime': DateTime.now().toIso8601String(),
    };
  }
}
