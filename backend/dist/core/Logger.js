"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
// Simple Logger utility for demonstration
class Logger {
    static info(...args) {
        console.log('[INFO]', ...args);
    }
    static error(...args) {
        console.error('[ERROR]', ...args);
    }
    static warn(...args) {
        console.warn('[WARN]', ...args);
    }
}
exports.default = Logger;
//# sourceMappingURL=Logger.js.map