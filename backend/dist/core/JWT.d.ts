export declare class JwtPayload {
    aud: string;
    sub: string;
    iss: string;
    iat: number;
    exp: number;
    constructor(issuer: string, audience: string, subject: string, validity: number);
}
declare const _default: {
    generateToken: (payload: JwtPayload) => Promise<string>;
    validateToken: (token: string) => Promise<JwtPayload>;
    decodeToken: (token: string) => Promise<JwtPayload>;
};
export default _default;
