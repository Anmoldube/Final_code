export declare const SERVER_CONFIG: {
    ip: string;
    port: string;
    useHttps: boolean;
};
export declare const getServerUrl: () => string;
export declare const getCorsUrls: () => string[];
export declare const DATABASE_CONFIG: {
    host: string;
    port: string;
    name: string;
    url: string;
    minPoolSize: number;
    maxPoolSize: number;
};
export declare const FILE_CONFIG: {
    maxSize: number;
    uploadPath: string;
    allowedImageTypes: string[];
    allowedVideoTypes: string[];
    allowedDocumentTypes: string[];
};
export declare const DEV_CONFIG: {
    isDevelopment: boolean;
    enableLogging: boolean;
    enableDebug: boolean;
};
