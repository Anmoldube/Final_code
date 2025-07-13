/**
 * Utility functions for handling time and timestamps
 */
/**
 * Get current UTC timestamp
 */
export declare const getCurrentUTCTimestamp: () => Date;
/**
 * Get current server time info for debugging
 */
export declare const getServerTimeInfo: () => {
    utc: string;
    local: string;
    timezone: string;
    offset: number;
    timestamp: number;
    performanceNow: number;
};
/**
 * Convert any date to UTC
 */
export declare const toUTC: (date: Date | string) => Date;
/**
 * Validate if a date is reasonable (not too far in future or past)
 */
export declare const isValidTimestamp: (date: Date) => boolean;
/**
 * Log time information for debugging
 */
export declare const logTimeInfo: (context: string) => void;
/**
 * Create a timestamp with validation
 */
export declare const createValidatedTimestamp: () => Date;
