export declare const environment: string | undefined;
export declare const port: string;
export declare const serverUrl: string;
export declare const db: {
    name: string;
    url: string;
    minPoolSize: number;
    maxPoolSize: number;
};
export declare const corsUrl: string[];
export declare const cookieValidity: string;
export declare const tokenInfo: {
    jwtSecretKey: string;
    accessTokenValidity: number;
    refreshTokenValidity: number;
    issuer: string;
    audience: string;
};
