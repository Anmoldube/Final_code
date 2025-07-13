"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createValidatedTimestamp = exports.logTimeInfo = exports.isValidTimestamp = exports.toUTC = exports.getServerTimeInfo = exports.getCurrentUTCTimestamp = void 0;
const perf_hooks_1 = require("perf_hooks");
/**
 * Utility functions for handling time and timestamps
 */
/**
 * Get current UTC timestamp
 */
const getCurrentUTCTimestamp = () => {
    return new Date();
};
exports.getCurrentUTCTimestamp = getCurrentUTCTimestamp;
/**
 * Get current server time info for debugging
 */
const getServerTimeInfo = () => {
    const now = new Date();
    return {
        utc: now.toISOString(),
        local: now.toString(),
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        offset: now.getTimezoneOffset(),
        timestamp: now.getTime(),
        performanceNow: perf_hooks_1.performance.now(),
    };
};
exports.getServerTimeInfo = getServerTimeInfo;
/**
 * Convert any date to UTC
 */
const toUTC = (date) => {
    if (typeof date === 'string') {
        return new Date(date);
    }
    return date;
};
exports.toUTC = toUTC;
/**
 * Validate if a date is reasonable (not too far in future or past)
 */
const isValidTimestamp = (date) => {
    const now = new Date();
    const oneYearAgo = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate());
    const oneYearFromNow = new Date(now.getFullYear() + 1, now.getMonth(), now.getDate());
    return date >= oneYearAgo && date <= oneYearFromNow;
};
exports.isValidTimestamp = isValidTimestamp;
/**
 * Log time information for debugging
 */
const logTimeInfo = (context) => {
    const timeInfo = (0, exports.getServerTimeInfo)();
    console.log(`⏰ Time info [${context}]:`, {
        utc: timeInfo.utc,
        timezone: timeInfo.timezone,
        offset: timeInfo.offset,
    });
};
exports.logTimeInfo = logTimeInfo;
/**
 * Create a timestamp with validation
 */
const createValidatedTimestamp = () => {
    const timestamp = (0, exports.getCurrentUTCTimestamp)();
    if (!(0, exports.isValidTimestamp)(timestamp)) {
        console.warn('⚠️ Invalid timestamp detected, using fallback');
        // Log the time info for debugging
        (0, exports.logTimeInfo)('createValidatedTimestamp');
    }
    return timestamp;
};
exports.createValidatedTimestamp = createValidatedTimestamp;
//# sourceMappingURL=timeUtils.js.map