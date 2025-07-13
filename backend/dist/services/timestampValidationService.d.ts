/**
 * Service to validate and fix timestamps on application startup
 */
export declare class TimestampValidationService {
    /**
     * Validate system time and log warnings if issues are found
     */
    static validateSystemTime(): void;
    /**
     * Check and fix any future timestamps in the database
     */
    static fixDatabaseTimestamps(): Promise<void>;
    /**
     * Fix message timestamps that are in the future
     */
    private static fixMessageTimestamps;
    /**
     * Fix file metadata timestamps that are in the future
     */
    private static fixFileMetadataTimestamps;
    /**
     * Run complete timestamp validation on startup
     */
    static runStartupValidation(): Promise<void>;
}
