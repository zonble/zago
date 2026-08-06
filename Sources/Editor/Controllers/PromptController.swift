import Foundation

/// Encapsulates state management and key processing for command bar prompts and dialogs.
public final class PromptController: KeyInputHandler {
    /// Interactive prompt state mode for command bar inputs and confirmation dialogs.
    public enum Mode {
        case none
        case saveFilePath(completion: (String?) -> Void)
        case confirmExitSave(completion: (Bool?) -> Void)
        case confirmExternalReload(completion: (Bool) -> Void)
        case confirmEncodingFallback(originalEncoding: String.Encoding, completion: (Bool) -> Void)
        case search(completion: (String?) -> Void)
        case insertFilePath(completion: (String?) -> Void)
        case spellCheck(word: String, line: Int, col: Int, completion: (String?) -> Void)
        case logoMacro(completion: (String?) -> Void)
        case fillText(completion: (String?) -> Void)
        case tableDimensions(completion: (String?) -> Void)
        case gotoLine(completion: (String?) -> Void)
        case logoReadWord(prompt: String)
        case logoReadChar(prompt: String)
    }

    /// Active prompt mode state.
    public var mode: Mode = .none

    /// Current text buffer entered in prompt bar.
    public var inputText: String = ""

    /// Cursor position in prompt input text.
    public var cursorIndex: Int = 0

    /// Autocompletion ghost text.
    public var completionText: String? = nil

    /// Logo script prompt history.
    public var logoHistory: [String] = []

    /// Logo script history navigation index.
    public var logoHistoryIndex: Int = 0

    public init() {}

    /// Resets all transient prompt input states.
    public func reset() {
        mode = .none
        inputText = ""
        cursorIndex = 0
        completionText = nil
    }

    /// Returns whether a prompt is currently active.
    public var isActive: Bool {
        if case .none = mode { return false }
        return true
    }

    /// KeyInputHandler protocol implementation.
    public func handleKey(_ key: Key, editor: Editor) -> Bool {
        guard isActive else { return false }
        if key == .esc || key == .ctrl("C") || key == .ctrl("G") {
            editor.cancelPrompt()
            return true
        }
        editor.processPromptKey(key)
        return true
    }

    /// Provides shortcut hints for the active prompt mode.
    public func promptHelpShortcuts(editor: Editor) -> [(key: String, label: String)]? {
        guard isActive else { return nil }

        let lang = editor.language
        func tr(_ key: String) -> String {
            L10n.string(key, language: lang)
        }

        switch mode {
        case .none:
            return nil
        case .confirmExitSave:
            return [("Y", tr("help.yes")), ("N", tr("help.no")), ("^C", tr("help.cancel"))]
        case .confirmExternalReload:
            return [("Y/Enter", tr("help.yes")), ("N", tr("help.no")), ("^C", tr("help.cancel"))]
        case .confirmEncodingFallback:
            return [("Y", tr("help.yes")), ("N", tr("help.no")), ("^C", tr("help.cancel"))]
        case .search:
            return [("^C", tr("help.cancel")), ("^M", tr("help.set_search")), ("^R", tr("help.replace"))]
        case .saveFilePath, .insertFilePath:
            return [("^C", tr("help.cancel")), ("Tab", tr("help.complete")), ("^M", tr("help.confirm"))]
        case .gotoLine, .tableDimensions, .fillText, .spellCheck:
            return [("^C", tr("help.cancel")), ("^M", tr("help.confirm"))]
        case .logoMacro:
            return [("^C", tr("help.cancel")), ("Tab", tr("help.complete")), ("^M", tr("help.execute")), ("↑↓", tr("help.history"))]
        case .logoReadWord, .logoReadChar:
            return [("^C", tr("help.cancel")), ("^M", tr("help.submit"))]
        }
    }
}
