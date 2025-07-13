import { JwtPayload } from "../../core/JWT";
import User from "../../database/model/User";
export declare const splitAccessToken: (token: string) => string;
export declare const createTokens: (user: User) => Promise<{
    accessToken: string;
    refreshToken: string;
}>;
export declare const validateTokenData: (payload: JwtPayload) => boolean;
