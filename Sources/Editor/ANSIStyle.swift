import Foundation

/// Centralized ANSI Escape Codes for text styling, themes, and screen control in the Editor renderer.
public enum ANSIStyle {
    /// Resets all styles, foreground, and background colors to terminal defaults (`\u{1B}[0m`).
    public static let reset = "\u{1B}[0m"

    /// Short ANSI reset sequence (`\u{1B}[m`).
    public static let resetShort = "\u{1B}[m"

    /// Bold text attribute (`\u{1B}[1m`).
    public static let bold = "\u{1B}[1m"

    /// Inverse / Reverse video attribute for selection and cursor (`\u{1B}[7m`).
    public static let inverse = "\u{1B}[7m"

    /// Dim / Gray text attribute for line numbers, EOF markers, and borders (`\u{1B}[90m`).
    public static let dimGray = "\u{1B}[90m"

    /// Bold cyan foreground for shortcut keys and titles (`\u{1B}[1;36m`).
    public static let boldCyan = "\u{1B}[1;36m"

    /// Bold yellow foreground for prompts and highlights (`\u{1B}[1;33m`).
    public static let boldYellow = "\u{1B}[1;33m"

    /// Default theme for top Menu Bar and dropdown borders: black text on white background (`\u{1B}[47;30m`).
    public static let menuDefault = "\u{1B}[47;30m"

    /// Highlight theme for selected menu category or item: bold white text on blue background (`\u{1B}[1;37;44m`).
    public static let menuSelected = "\u{1B}[1;37;44m"

    /// Reset sequence to return to menu default theme (`\u{1B}[0;47;30m`).
    public static let menuReset = "\u{1B}[0;47;30m"

    /// Highlight for Canvas mode inactive cursor: black text on yellow background (`\u{1B}[43;30m`).
    public static let canvasCursor = "\u{1B}[43;30m"

    /// Highlight for Canvas mode active edit cell: bold white text on green background (`\u{1B}[42;97;1m`).
    public static let canvasActiveCell = "\u{1B}[42;97;1m"

    /// Moves physical cursor to top-left home position (1,1) (`\u{1B}[H`).
    public static let cursorHome = "\u{1B}[H"

    /// Clears line from cursor position to the end of the line (`\u{1B}[K`).
    public static let clearLine = "\u{1B}[K"

    /// Disables terminal auto-wrap to prevent visual artifacts on exact edge drawing (`\u{1B}[?7l`).
    public static let disableLineWrap = "\u{1B}[?7l"
}

/// Strongly typed ANSI Color enumerations for TUI components and syntax highlighters.
public enum ANSIColor {
    /// Foreground text color codes (30...37, 90...97).
    public enum Foreground: String {
        case black = "\u{1B}[30m"
        case red = "\u{1B}[31m"
        case green = "\u{1B}[32m"
        case yellow = "\u{1B}[33m"
        case blue = "\u{1B}[34m"
        case magenta = "\u{1B}[35m"
        case cyan = "\u{1B}[36m"
        case white = "\u{1B}[37m"

        case brightBlack = "\u{1B}[90m"
        case brightRed = "\u{1B}[91m"
        case brightGreen = "\u{1B}[92m"
        case brightYellow = "\u{1B}[93m"
        case brightBlue = "\u{1B}[94m"
        case brightMagenta = "\u{1B}[95m"
        case brightCyan = "\u{1B}[96m"
        case brightWhite = "\u{1B}[97m"

        case reset = "\u{1B}[39m"
    }

    /// Background color codes (40...47, 100...107).
    public enum Background: String {
        case black = "\u{1B}[40m"
        case red = "\u{1B}[41m"
        case green = "\u{1B}[42m"
        case yellow = "\u{1B}[43m"
        case blue = "\u{1B}[44m"
        case magenta = "\u{1B}[45m"
        case cyan = "\u{1B}[46m"
        case white = "\u{1B}[47m"

        case brightBlack = "\u{1B}[100m"
        case brightRed = "\u{1B}[101m"
        case brightGreen = "\u{1B}[102m"
        case brightYellow = "\u{1B}[103m"
        case brightBlue = "\u{1B}[104m"
        case brightMagenta = "\u{1B}[105m"
        case brightCyan = "\u{1B}[106m"
        case brightWhite = "\u{1B}[107m"

        case reset = "\u{1B}[49m"
    }
}
