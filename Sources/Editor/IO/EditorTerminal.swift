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

    /// Reads and parses the next input event (key press or mouse interaction).
    func readInputEvent() -> InputEvent

    /// Enables or disables terminal mouse reporting (SGR 1006 mode).
    func setMouseTracking(enabled: Bool)

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

    /// Reads a single line from input stream in non-interactive/headless mode.
    func readNonInteractiveLine(prompt: String) -> String?

    /// Reads a single character from input stream in non-interactive/headless mode.
    func readNonInteractiveChar(prompt: String) -> String?

    /// Wakes up any blocked readKey call from another thread (e.g. IPC server thread).
    func wakeup()

    /// Checks if there is additional pending input immediately available in the input stream.
    func hasPendingInput() -> Bool
}

extension EditorTerminal {
    public func hasPendingInput() -> Bool {
        false
    }
}

extension EditorTerminal {
    public func readInputEvent() -> InputEvent {
        .key(readKey())
    }

    public func setMouseTracking(enabled: Bool) {
        if enabled {
            write("\u{1B}[?1000h\u{1B}[?1002h\u{1B}[?1006h")
        } else {
            write("\u{1B}[?1006l\u{1B}[?1002l\u{1B}[?1000l")
        }
    }
}

extension EditorTerminal {
    public func wakeup() {}
}

extension EditorTerminal {
    public func readNonInteractiveLine(prompt: String) -> String? {
        nil
    }

    public func readNonInteractiveChar(prompt: String) -> String? {
        nil
    }
}
