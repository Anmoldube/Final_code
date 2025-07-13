import 'dart:developer' as developer;

/// Service for handling timestamps consistently across the app
class TimestampService {
  static const String _logTag = 'TimestampService';

  /// The offset for Indian Standard Time (IST) from UTC in hours
  static const double istOffsetHours = 5.5; // UTC+5:30

  /// Get current timestamp in IST - corrected if system time is wrong
  static DateTime getCurrentTimestamp() {
    return getActualCurrentTime();
  }

  /// Get actual current time in IST - using system time as the source of truth
  static DateTime getActualCurrentTime() {
    // Use system time as-is - let the system determine the correct year
    return DateTime.now().toLocal();
  }

  /// Convert UTC timestamp to IST
  static DateTime utcToIST(DateTime utcTime) {
    return utcTime.toLocal();
  }

  /// Parse and validate timestamp from various formats
  /// Returns null if the input is null, otherwise ensures we get a valid DateTime
  static DateTime? parseAndValidateDateTime(
    dynamic dateTime, {
    bool allowNull = true,
  }) {
    if (dateTime == null) return allowNull ? null : getCurrentTimestamp();

    try {
      DateTime parsedDate;

      if (dateTime is DateTime) {
        parsedDate = dateTime.toLocal();
      } else if (dateTime is String) {
        if (dateTime.isEmpty) return allowNull ? null : getCurrentTimestamp();
        parsedDate = DateTime.parse(dateTime).toLocal();
      } else if (dateTime is int) {
        // Handle Unix timestamps (both seconds and milliseconds)
        final date = dateTime < 10000000000
            ? DateTime.fromMillisecondsSinceEpoch(dateTime * 1000)
            : DateTime.fromMillisecondsSinceEpoch(dateTime);
        parsedDate = date.toLocal();
      } else {
        developer.log(
          'Unknown timestamp format: ${dateTime.runtimeType}',
          name: _logTag,
        );
        return allowNull ? null : getCurrentTimestamp();
      }

      return validateTimestamp(parsedDate);
    } catch (e) {
      developer.log(
        'Error parsing timestamp: $e, input: $dateTime',
        name: _logTag,
      );
      return allowNull ? null : getCurrentTimestamp();
    }
  }

  /// Validate a DateTime and return a corrected version if needed
  static DateTime validateTimestamp(DateTime dateTime) {
    final localDateTime = dateTime.toLocal();

    // Check for obviously wrong years only (way in the future like 2026+ should be corrected to current year)
    final currentYear = getActualCurrentTime().year;
    if (localDateTime.year > currentYear + 1) {
      // Convert obviously future timestamp to current year
      final correctedDate = DateTime(
        currentYear,
        localDateTime.month,
        localDateTime.day,
        localDateTime.hour,
        localDateTime.minute,
        localDateTime.second,
        localDateTime.millisecond,
      );
      developer.log(
        'Warning: Obviously future year detected (${localDateTime.year}), corrected to $currentYear. Original: ${localDateTime.toIso8601String()}, Corrected: ${correctedDate.toIso8601String()}',
        name: _logTag,
      );
      return correctedDate;
    }

    // If date is too far in the past (before 2020), use current time
    if (localDateTime.year < 2020) {
      developer.log(
        'Warning: Very old timestamp detected (${localDateTime.toIso8601String()}), using current time',
        name: _logTag,
      );
      return getActualCurrentTime();
    }

    // For reasonable years (2020-2025), check if it's too far in the future
    final actualNow = getActualCurrentTime();
    final maxFuture = actualNow.add(const Duration(days: 1));

    if (localDateTime.isAfter(maxFuture)) {
      developer.log(
        'Warning: Timestamp too far in future, using current time. Original: ${localDateTime.toIso8601String()}',
        name: _logTag,
      );
      return actualNow;
    }

    return localDateTime;
  }

  /// Format timestamp for display in IST
  static String formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown time';

    final validatedDateTime = validateTimestamp(dateTime);
    final hour = validatedDateTime.hour.toString().padLeft(2, '0');
    final minute = validatedDateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute IST';
  }

  /// Check if the app's time seems reasonable
  static bool isSystemTimeReasonable() {
    final systemNow = DateTime.now()
        .toLocal(); // Raw system time in local timezone
    final year = systemNow.year;

    // Check if year is reasonable (should be around current time, allowing some flexibility)
    if (year < 2020 || year > 2030) {
      developer.log(
        'System time appears unusual. Current year: $year',
        name: _logTag,
      );
      return false;
    }

    return true;
  }

  /// Validate system time and show warning if needed
  static void validateSystemTime() {
    if (!isSystemTimeReasonable()) {
      developer.log(
        'WARNING: System time may be incorrect. This could cause timestamp issues.',
        name: _logTag,
      );
    } else {
      developer.log('System time validation passed', name: _logTag);
    }
  }

  /// Create timestamp for new entities
  static DateTime createTimestamp() {
    return getCurrentTimestamp();
  }

  /// Update timestamp for existing entities
  static DateTime updateTimestamp() {
    return getCurrentTimestamp();
  }

  /// Safe ISO string conversion
  static String toIsoString(DateTime? dateTime) {
    if (dateTime == null) return '';
    return validateTimestamp(dateTime).toIso8601String();
  }

  /// Parse timestamp for messages specifically
  static DateTime? parseMessageTimestamp(dynamic dateTime) {
    return parseAndValidateDateTime(dateTime, allowNull: true);
  }

  /// Parse timestamp for files specifically (never null, always fallback to now)
  static DateTime parseFileTimestamp(dynamic dateTime) {
    return parseAndValidateDateTime(dateTime, allowNull: false) ??
        getCurrentTimestamp();
  }

  /// Get relative time string (e.g., "2 minutes ago")
  static String getRelativeTimeString(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown time';

    final validatedDateTime = validateTimestamp(dateTime);
    final now = getCurrentTimestamp();
    final difference = now.difference(validatedDateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else {
      // For older dates, show the actual date and time in IST using DD/MM/YYYY format
      final day = validatedDateTime.day.toString().padLeft(2, '0');
      final month = validatedDateTime.month.toString().padLeft(2, '0');
      final hour = validatedDateTime.hour.toString().padLeft(2, '0');
      final minute = validatedDateTime.minute.toString().padLeft(2, '0');
      return '$day/$month/${validatedDateTime.year} $hour:$minute IST';
    }
  }
}
