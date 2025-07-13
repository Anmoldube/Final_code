import multer from 'multer';
export declare const upload: multer.Multer;
export declare const getFileUrl: (filename: string, type?: "avatar" | "attachment") => string;
export declare const getLocalFilePath: (filename: string, type?: "avatar" | "attachment") => string;
