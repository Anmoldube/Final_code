/**
 * Time utility functions for consistent timestamp handling
 */
/**
 * Get current UTC timestamp
 * Always returns a proper Date object in UTC
 */
export declare function getCurrentTimestamp(): Date;
/**
 * Ensure a date is valid and not in the future beyond reasonable limits
 * @param date - Date to validate
 * @param maxFutureDays - Maximum days in the future allowed (default: 1)
 * @returns Valid date or corrected time if invalid
 */
export declare function validateAndFixTimestamp(date: Date | string | null | undefined, maxFutureDays?: number): Date;
/**
 * Format date to ISO string safely
 */
export declare function toISOString(date: Date | string | null | undefined): string;
/**
 * Parse timestamp from various formats
 */
export declare function parseTimestamp(timestamp: any): Date;
/**
 * Create timestamp for database operations
 */
export declare function createDbTimestamp(): Date;
/**
 * Update timestamp for database operations
 */
export declare function updateDbTimestamp(): Date;
/**
 * Check if system time is reasonable
 */
export declare function validateSystemTime(): {
    isValid: boolean;
    message: string;
};
/**
 * Log timestamp validation warning
 */
export declare function logTimestampWarning(context: string, originalTime: any, fixedTime: Date): void;
