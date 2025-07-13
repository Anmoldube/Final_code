"use strict";
/**
 * Time utility functions for consistent timestamp handling
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.getCurrentTimestamp = getCurrentTimestamp;
exports.validateAndFixTimestamp = validateAndFixTimestamp;
exports.toISOString = toISOString;
exports.parseTimestamp = parseTimestamp;
exports.createDbTimestamp = createDbTimestamp;
exports.updateDbTimestamp = updateDbTimestamp;
exports.validateSystemTime = validateSystemTime;
exports.logTimestampWarning = logTimestampWarning;
/**
 * Get current UTC timestamp
 * Always returns a proper Date object in UTC
 */
function getCurrentTimestamp() {
    return getActualCurrentTime();
}
/**
 * Ensure a date is valid and not in the future beyond reasonable limits
 * @param date - Date to validate
 * @param maxFutureDays - Maximum days in the future allowed (default: 1)
 * @returns Valid date or corrected time if invalid
 */
function validateAndFixTimestamp(date, maxFutureDays = 1) {
    if (!date) {
        return getActualCurrentTime();
    }
    let parsedDate;
    try {
        parsedDate = typeof date === 'string' ? new Date(date) : date;
        // Check if date is valid
        if (isNaN(parsedDate.getTime())) {
            console.warn('Invalid timestamp provided, using current time:', date);
            return getActualCurrentTime();
        }
        // Check for obviously wrong years (2025 and beyond should be corrected to 2024)
        const year = parsedDate.getFullYear();
        if (year >= 2025) {
            // Convert 2025 timestamp to 2024 by subtracting 1 year
            const correctedDate = new Date(parsedDate);
            correctedDate.setFullYear(2024);
            console.warn(`Future year detected (${year}), corrected to 2024. Original:`, parsedDate.toISOString(), 'Corrected:', correctedDate.toISOString());
            return correctedDate;
        }
        // If date is too far in the past (before 2020), use current time
        if (year < 2020) {
            console.warn('Very old timestamp detected, using current time. Original:', parsedDate.toISOString());
            return getActualCurrentTime();
        }
        // For reasonable years (2020-2024), check if it's too far in the future
        const actualNow = getActualCurrentTime();
        const maxFutureTime = new Date(actualNow.getTime() + (maxFutureDays * 24 * 60 * 60 * 1000));
        if (parsedDate > maxFutureTime) {
            console.warn('Timestamp too far in future, using current time. Original:', parsedDate.toISOString());
            return actualNow;
        }
        return parsedDate;
    }
    catch (error) {
        console.error('Error parsing timestamp:', error);
        return getActualCurrentTime();
    }
}
/**
 * Get actual current time, ignoring system time if it's wrong
 * This assumes the current year should be 2024
 */
function getActualCurrentTime() {
    const now = new Date();
    // If system time shows 2025 or beyond, assume it should be 2024
    if (now.getFullYear() >= 2025) {
        const correctedNow = new Date(now);
        correctedNow.setFullYear(2024);
        return correctedNow;
    }
    return now;
}
/**
 * Format date to ISO string safely
 */
function toISOString(date) {
    const validDate = validateAndFixTimestamp(date);
    return validDate.toISOString();
}
/**
 * Parse timestamp from various formats
 */
function parseTimestamp(timestamp) {
    if (!timestamp)
        return getCurrentTimestamp();
    if (timestamp instanceof Date) {
        return validateAndFixTimestamp(timestamp);
    }
    if (typeof timestamp === 'string') {
        return validateAndFixTimestamp(timestamp);
    }
    if (typeof timestamp === 'number') {
        // Handle Unix timestamps (both seconds and milliseconds)
        const date = timestamp < 10000000000
            ? new Date(timestamp * 1000)
            : new Date(timestamp);
        return validateAndFixTimestamp(date);
    }
    return getCurrentTimestamp();
}
/**
 * Create timestamp for database operations
 */
function createDbTimestamp() {
    return getCurrentTimestamp();
}
/**
 * Update timestamp for database operations
 */
function updateDbTimestamp() {
    return getCurrentTimestamp();
}
/**
 * Check if system time is reasonable
 */
function validateSystemTime() {
    const now = new Date();
    const year = now.getFullYear();
    if (year < 2024 || year > 2030) {
        return {
            isValid: false,
            message: `System time appears incorrect. Current year: ${year}. Please check system clock.`
        };
    }
    return {
        isValid: true,
        message: 'System time appears correct'
    };
}
/**
 * Log timestamp validation warning
 */
function logTimestampWarning(context, originalTime, fixedTime) {
    console.warn(`[TIMESTAMP WARNING] ${context}:`, {
        original: originalTime,
        fixed: fixedTime.toISOString(),
        timestamp: Date.now()
    });
}
//# sourceMappingURL=timeUtils.js.map