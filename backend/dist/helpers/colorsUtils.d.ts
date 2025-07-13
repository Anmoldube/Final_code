import colors from "colors";
declare const colorsStyles: {
    error: colors.Color;
    warning: colors.Color;
    success: colors.Color;
    info: colors.Color;
    debug: colors.Color;
};
declare const colorsUtils: {
    log: (type: keyof typeof colorsStyles, message: string) => void;
};
export default colorsUtils;
