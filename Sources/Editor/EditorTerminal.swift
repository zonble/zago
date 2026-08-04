import Config
import Foundation

/// Abstract terminal driver interface decoupling `Editor` from platform-specific I/O.
///
/// Implement this protocol to integrate `Editor` with different display targets, such as:
/// - Real interactive ANSI/VT100 TTY terminals (`LocalTerminal`)
/// - In-memory mock terminals for headless unit tests (`TestEditorTerminal`)
/// - Web / GUI terminal emulators (e.g. xterm.js, SwiftUI canvas)
public protocol EditorTerminal: AnyObject {
    /// Puts terminal into raw mode (disables canonical line buffering and character echo).
    ///
    /// - Throws: An error if raw mode initialization fails on the host OS.
    func enableRawMode() throws

    /// Restores terminal to original cooked/canonical mode before exiting or spawning subprocesses.
    func disableRawMode()

    /// Queries current terminal dimensions for screen rendering calculations.
    ///
    /// - Returns: A tuple containing row count (`rows`) and column count (`cols`).
    func getWindowSize() -> (rows: Int, cols: Int)

    /// Reads and parses the next key event or VT100 escape sequence into a normalized `Key`.
    ///
    /// - Returns: The parsed `Key` enum value representing key presses, control sequences, or function keys.
    func readKey() -> Key

    /// Reads remaining buffered characters when paste detection or rapid text input occurs.
    ///
    /// - Parameter firstChar: The initial character that triggered rapid reading.
    /// - Returns: Concatenated string of buffered characters read.
    func readPendingText(firstChar: Character) -> String

    /// Writes ANSI/VT100 escape sequences or text content directly to terminal output stream.
    ///
    /// - Parameter text: The string payload or escape sequence string to write.
    func write(_ text: String)

    /// Emits escape code (e.g. `\u{1B}[?25l`) to hide hardware cursor during render passes to prevent flickering.
    func hideCursor()

    /// Emits escape code (e.g. `\u{1B}[?25h`) to reveal hardware cursor after render passes.
    func showCursor()

    /// Clears terminal screen buffer and resets cursor position to top-left `(1,1)`.
    func clearScreen()
}
