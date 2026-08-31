import Foundation
import LogoEngine
import TextMetrics
import TextTransform

/// Encapsulates state management and key processing for command bar prompts and dialogs.
final class PromptController: KeyInputHandler {
    /// Interactive choice made during interactive search and replace confirmation.
    public enum ReplaceChoice: Sendable {
        case yes
        case no
        case all
        case cancel
    }

    /// Interactive prompt state mode for command bar inputs and confirmation dialogs.
    enum Mode {
        case none
        case saveFilePath(completion: (String?) -> Void)
        case confirmExitSave(completion: (Bool?) -> Void)
        case confirmExternalReload(completion: (Bool) -> Void)
        case confirmEncodingFallback(originalEncoding: String.Encoding, completion: (Bool) -> Void)
        case confirmBackupFailure(error: String, completion: (Bool) -> Void)
        case search(completion: (String?) -> Void)
        case replaceSearch(completion: (String?) -> Void)
        case replaceWith(searchQuery: String, completion: (String?) -> Void)
        case confirmReplace(query: String, replacement: String, completion: (ReplaceChoice) -> Void)
        case insertFilePath(completion: (String?) -> Void)
        case openFilePath(completion: (String?) -> Void)
        case spellCheck(word: String, line: Int, col: Int, completion: (String?) -> Void)
        case logoMacro(completion: (String?) -> Void)
        case fillText(completion: (String?) -> Void)
        case tableDimensions(completion: (String?) -> Void)
        case gotoLine(completion: (String?) -> Void)
        case describeKey(completion: (Key) -> Void)
        case logoReadWord(prompt: String)
        case logoReadChar(prompt: String)

        func cancel(in editor: Editor?) {
            switch self {
            case .saveFilePath(let completion):
                completion(nil)
                editor?.reportOperationResult(.cancelled(message: editor?.l10n["status.cancelled"] ?? ""))
            case .confirmExitSave(let completion):
                completion(nil)
            case .confirmExternalReload(let completion),
                .confirmEncodingFallback(_, let completion),
                .confirmBackupFailure(_, let completion):
                completion(false)
            case .search(let completion),
                .replaceSearch(let completion),
                .replaceWith(_, let completion),
                .insertFilePath(let completion),
                .openFilePath(let completion),
                .spellCheck(_, _, _, let completion),
                .logoMacro(let completion),
                .fillText(let completion),
                .tableDimensions(let completion),
                .gotoLine(let completion):
                completion(nil)
            case .confirmReplace(_, _, let completion):
                completion(.cancel)
            case .describeKey, .logoReadWord, .logoReadChar, .none:
                break
            }
        }
    }

    /// Active prompt mode state.
    var mode: Mode = .none

    /// Internal reusable single line text editor buffer.
    var singleLineEditor = SingleLineTextEditor()

    /// Current text buffer entered in prompt bar.
    var inputText: String {
        get { singleLineEditor.text }
        set { singleLineEditor.text = newValue }
    }

    /// Cursor position in prompt input text.
    var cursorIndex: Int {
        get { singleLineEditor.cursorIndex }
        set { singleLineEditor.cursorIndex = newValue }
    }

    /// Selection anchor in prompt input text, or nil when no prompt text is selected.
    var selectionAnchorIndex: Int? {
        get { singleLineEditor.selectionAnchorIndex }
        set { singleLineEditor.selectionAnchorIndex = newValue }
    }

    /// Autocompletion ghost text.
    var completionText: String? = nil

    /// Logo script prompt history.
    var logoHistory: [String] = []

    /// Logo script history navigation index.
    var logoHistoryIndex: Int = 0

    weak var editor: Editor?

    init(editor: Editor? = nil) {
        self.editor = editor
    }

    /// Returns whether a prompt is currently active.
    var isActive: Bool {
        if case .none = mode { return false }
        return true
    }

    /// Exits the active prompt mode without notifying completion handler and resets input state.
    func dismissPrompt() {
        mode = .none
        singleLineEditor.reset()
        completionText = nil
    }

    /// Exits the prompt mode, resets input state, and executes the completion action.
    private func completePrompt(with action: () -> Void) {
        mode = .none
        singleLineEditor.selectionAnchorIndex = nil
        completionText = nil
        action()
    }

    /// Cancels active prompt mode, triggers appropriate cancellation callbacks, and resets state.
    func cancel() {
        mode.cancel(in: editor)
        dismissPrompt()
    }
}

// MARK: - Key Dispatch & Handlers

extension PromptController {
    /// KeyInputHandler protocol implementation.
    func handleKey(_ key: Key) -> Bool {
        guard isActive else { return false }

        if case .describeKey(let completion) = mode {
            if key == .unknown || key == .resize {
                return false
            }
            dismissPrompt()
            completion(key)
            return true
        }

        let cmd = editor?.keymapManager.resolve(key: key, in: .prompt)

        switch cmd {
        case .promptCancel:
            cancel()
            return true

        case .fileExit:
            if isTextEditingPromptMode {
                dismissPrompt()
                if let editor {
                    _ = editor.commandRegistry.dispatch(id: .fileExit, editor: editor)
                }
                return true
            }

        case .editCut:
            if isTextEditingPromptMode {
                completionText = nil
                var clip = editor?.clipboardText
                singleLineEditor.cut(to: &clip)
                editor?.clipboardText = clip
                return true
            }

        case .editCopy:
            if isTextEditingPromptMode {
                var clip = editor?.clipboardText
                singleLineEditor.copy(to: &clip)
                editor?.clipboardText = clip
                completionText = nil
                return true
            }

        case .editUncut:
            if isTextEditingPromptMode {
                completionText = nil
                singleLineEditor.paste(from: editor?.clipboardText)
                return true
            }

        case .selectAll:
            if isTextEditingPromptMode {
                singleLineEditor.selectAll()
                return true
            }

        case .moveHome:
            singleLineEditor.moveHome()
            return true

        case .moveEnd:
            singleLineEditor.moveEnd()
            return true

        case .moveLeft:
            singleLineEditor.moveLeft()
            return true

        case .moveRight:
            singleLineEditor.moveRight()
            return true

        case .moveWordBackward:
            singleLineEditor.moveWordBackward()
            return true

        case .moveWordForward:
            singleLineEditor.moveWordForward()
            return true

        case .selectLeft:
            completionText = nil
            singleLineEditor.selectLeft()
            return true

        case .selectRight:
            completionText = nil
            singleLineEditor.selectRight()
            return true

        case .selectHome:
            completionText = nil
            singleLineEditor.selectHome()
            return true

        case .selectEnd:
            completionText = nil
            singleLineEditor.selectEnd()
            return true

        case .selectWordBackward:
            completionText = nil
            singleLineEditor.selectLeft()
            return true

        case .selectWordForward:
            completionText = nil
            singleLineEditor.selectRight()
            return true

        case .promptClearLine:
            completionText = nil
            singleLineEditor.clearLine()
            return true

        case .editDelete:
            completionText = nil
            singleLineEditor.deleteForward()
            return true

        default:
            break
        }

        processPromptKey(key)
        return true
    }

    /// Processes keyboard input when in prompt mode.
    private func processPromptKey(_ key: Key) {
        switch mode {
        case .logoReadChar, .describeKey:
            break
        case .saveFilePath(let completion):
            processTextInputPromptKey(key, trimWhitespace: true, completion: completion)

        case .confirmExitSave(let completion):
            processConfirmationPromptKey(key, completion: completion)

        case .confirmExternalReload(let completion):
            processConfirmationPromptKey(key, completion: completion)

        case .confirmEncodingFallback(_, let completion):
            processConfirmationPromptKey(key, completion: completion)

        case .confirmBackupFailure(_, let completion):
            processConfirmationPromptKey(key, completion: completion)

        case .search(let completion):
            processTextInputPromptKey(key, trimWhitespace: false, completion: completion)

        case .replaceSearch(let completion):
            processTextInputPromptKey(key, trimWhitespace: false, completion: completion)

        case .replaceWith(_, let completion):
            processTextInputPromptKey(key, trimWhitespace: false, completion: completion)

        case .confirmReplace(_, _, let completion):
            switch key {
            case .char("y"), .char("Y"), .enter:
                completePrompt { completion(.yes) }
            case .char("n"), .char("N"):
                completePrompt { completion(.no) }
            case .char("a"), .char("A"):
                completePrompt { completion(.all) }
            default:
                break
            }

        case .insertFilePath(let completion), .openFilePath(let completion):
            processTextInputPromptKey(key, trimWhitespace: false, completion: completion)

        case .spellCheck(_, _, _, let completion):
            processTextInputPromptKey(key, trimWhitespace: true, completion: completion)

        case .logoMacro(let completion):
            let cmd = editor?.keymapManager.resolve(key: key, in: .prompt)
            switch cmd {
            case .promptComplete:
                _ = completeCommandBarPrompt()
            case .promptConfirm:
                let script = inputText
                completionText = nil
                if !script.isEmpty && logoHistory.last != script {
                    logoHistory.append(script)
                }
                mode = .none
                completion(script)
            case .promptHistoryPrev:
                completionText = nil
                selectionAnchorIndex = nil
                if logoHistoryIndex > 0 {
                    logoHistoryIndex -= 1
                    inputText = logoHistory[logoHistoryIndex]
                    cursorIndex = inputText.count
                }
            case .promptHistoryNext:
                completionText = nil
                selectionAnchorIndex = nil
                if logoHistoryIndex < logoHistory.count - 1 {
                    logoHistoryIndex += 1
                    inputText = logoHistory[logoHistoryIndex]
                    cursorIndex = inputText.count
                } else {
                    logoHistoryIndex = logoHistory.count
                    inputText = ""
                    cursorIndex = 0
                }
            default:
                switch key {
                case .backspace:
                    completionText = nil
                    singleLineEditor.deleteBackspace()
                case .char(let ch):
                    completionText = nil
                    singleLineEditor.insertChar(ch)
                default:
                    break
                }
            }

        case .fillText(let completion), .tableDimensions(let completion), .gotoLine(let completion):
            processTextInputPromptKey(key, trimWhitespace: false, completion: completion)

        case .logoReadWord:
            switch key {
            case .backspace:
                completionText = nil
                singleLineEditor.deleteBackspace()
            case .char(let ch):
                completionText = nil
                singleLineEditor.insertChar(ch)
            default:
                break
            }

        case .none:
            break
        }
    }

    /// Common handler for text input prompts.
    private func processTextInputPromptKey(
        _ key: Key,
        trimWhitespace: Bool = false,
        completion: (String?) -> Void
    ) {
        let cmd = editor?.keymapManager.resolve(key: key, in: .prompt)
        if cmd == .promptConfirm {
            let raw = inputText
            let result = trimWhitespace ? raw.trimmingCharacters(in: .whitespacesAndNewlines) : raw
            completePrompt {
                completion(trimWhitespace && result.isEmpty ? nil : result)
            }
            return
        }

        switch key {
        case .backspace:
            completionText = nil
            singleLineEditor.deleteBackspace()
        case .char(let ch):
            completionText = nil
            singleLineEditor.insertChar(ch)
        default:
            break
        }
    }

    private func processConfirmationPromptKey(_ key: Key, completion: (Bool) -> Void) {
        switch key {
        case .char("y"), .char("Y"), .enter:
            completePrompt { completion(true) }
        case .char("n"), .char("N"):
            completePrompt { completion(false) }
        default:
            break
        }
    }

    private var isTextEditingPromptMode: Bool {
        switch mode {
        case .saveFilePath, .search, .replaceSearch, .replaceWith, .insertFilePath, .openFilePath, .spellCheck, .logoMacro, .fillText,
            .tableDimensions,
            .gotoLine,
            .logoReadWord:
            return true
        case .none, .confirmExitSave, .confirmExternalReload, .confirmEncodingFallback, .confirmBackupFailure,
            .confirmReplace, .describeKey,
            .logoReadChar:
            return false
        }
    }

    func selectionRange() -> Range<Int>? {
        singleLineEditor.selectionRange
    }
}

// MARK: - Autocompletion & Command Help

extension PromptController {
    private func showCommandBarCompletions(_ items: [String], label: String) {
        guard let editor else { return }
        if items.isEmpty {
            completionText = editor.l10n["status.no_completions"]
        } else {
            let text = String(format: editor.l10n["status.command_completions"], label, items.joined(separator: ", "))
            completionText = text
        }
    }

    private func completeSettingCommandPrompt() -> Bool {
        guard editor != nil else { return false }
        let clamped = max(0, min(cursorIndex, inputText.count))
        let splitIdx = inputText.index(inputText.startIndex, offsetBy: clamped)
        let prefix = String(inputText[..<splitIdx])

        let commandParts = prefix.split(maxSplits: 1, whereSeparator: \.isWhitespace).map(String.init)
        guard let command = commandParts.first?.lowercased(), command == "set" || command == "unset" else {
            return false
        }

        guard prefix.contains(where: \.isWhitespace) else {
            replacePromptPrefix(command + " ")
            showCommandBarCompletions(SettingCommand.settingNames, label: command.uppercased())
            return true
        }

        let commandEnd = prefix.firstIndex(where: \.isWhitespace) ?? prefix.endIndex
        let restStart = prefix[commandEnd...].firstIndex(where: { !$0.isWhitespace }) ?? prefix.endIndex
        let rest = String(prefix[restStart...])

        guard !rest.isEmpty else {
            showCommandBarCompletions(SettingCommand.settingNames, label: command.uppercased())
            return true
        }

        if let settingEnd = rest.firstIndex(where: \.isWhitespace) {
            let setting = String(rest[..<settingEnd])
            let valuePrefixStart = rest[settingEnd...].firstIndex(where: { !$0.isWhitespace }) ?? rest.endIndex
            let valuePrefix = String(rest[valuePrefixStart...]).lowercased()
            let matches = SettingCommand.valueSuggestions(for: setting)
                .filter { valuePrefix.isEmpty || $0.lowercased().hasPrefix(valuePrefix) }

            if matches.count == 1 && !valuePrefix.isEmpty {
                replacePromptPrefix("\(command) \(setting) \(matches[0])")
            } else if !matches.isEmpty && !valuePrefix.isEmpty {
                let lcp = TextAnalyzer.longestCommonPrefix(of: matches)
                if lcp.count > valuePrefix.count {
                    replacePromptPrefix("\(command) \(setting) \(lcp)")
                }
                showCommandBarCompletions(matches, label: setting)
            } else {
                showCommandBarCompletions(matches, label: setting)
            }
            return true
        }

        let settingPrefix = rest.lowercased()
        let matches = SettingCommand.settingNames.filter { $0.hasPrefix(settingPrefix) }
        if matches.count == 1 && !settingPrefix.isEmpty {
            replacePromptPrefix("\(command) \(matches[0]) ")
        } else if !matches.isEmpty && !settingPrefix.isEmpty {
            let lcp = TextAnalyzer.longestCommonPrefix(of: matches)
            if lcp.count > settingPrefix.count {
                replacePromptPrefix("\(command) \(lcp)")
            }
            showCommandBarCompletions(matches, label: command.uppercased())
        } else {
            showCommandBarCompletions(matches, label: command.uppercased())
        }

        return true
    }

    private func completeCommandBarPrompt() -> Bool {
        guard let editor else { return false }
        let clamped = max(0, min(cursorIndex, inputText.count))
        let splitIdx = inputText.index(inputText.startIndex, offsetBy: clamped)
        let prefix = String(inputText[..<splitIdx])

        if completeSettingCommandPrompt() {
            return true
        }

        let tokenStartIndex =
            prefix.lastIndex(where: { !isCompletionTokenChar($0) })
            .map { prefix.index(after: $0) } ?? prefix.startIndex
        let leadingContext = String(prefix[..<tokenStartIndex])
        let token = String(prefix[tokenStartIndex...])

        guard !token.isEmpty, token.allSatisfy(isCompletionTokenChar) else {
            return false
        }

        let commandNames = editor.commandBarRegistry.completionNames(for: editor)
        let logoNames = editor.buffer.allowsLogoExecution ? LogoPrimitive.keywordAliases : []
        let lowerToken = token.lowercased()
        let matches = Array(Set(commandNames + logoNames))
            .filter { $0.lowercased().hasPrefix(lowerToken) }
            .sorted { lhs, rhs in
                if lhs.lowercased() == rhs.lowercased() { return lhs < rhs }
                return lhs.lowercased() < rhs.lowercased()
            }
            .map { completionCandidate($0, matching: token) }

        if matches.count == 1 {
            replacePromptPrefix(leadingContext + matches[0] + " ")
        } else if !matches.isEmpty {
            let lcp = TextAnalyzer.longestCommonPrefix(of: matches)
            if lcp.count > token.count {
                replacePromptPrefix(leadingContext + lcp)
            }
            showCommandBarCompletions(matches, label: "Tab")
        } else {
            showCommandBarCompletions([], label: "Tab")
        }
        return true
    }

    private func replacePromptPrefix(_ replacement: String) {
        completionText = nil
        singleLineEditor.selectionAnchorIndex = nil
        let clamped = max(0, min(cursorIndex, inputText.count))
        let splitIndex = inputText.index(inputText.startIndex, offsetBy: clamped)
        inputText = replacement + inputText[splitIndex...]
        cursorIndex = replacement.count
    }

    private func completionCandidate(_ candidate: String, matching typed: String) -> String {
        if typed == typed.uppercased() && typed != typed.lowercased() {
            return candidate.uppercased()
        }
        if typed == typed.lowercased() {
            return candidate.lowercased()
        }
        return candidate
    }

    private func isCompletionTokenChar(_ ch: Character) -> Bool {
        ch.isLetter || ch == "-" || ch == "_" || ch == "." || ch == "?"
    }

    /// Provides shortcut hints for the active prompt mode.
    func promptHelpShortcuts() -> [(key: String, label: String)]? {
        guard let editor, isActive else { return nil }

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
        case .confirmEncodingFallback, .confirmBackupFailure:
            return [("Y", tr("help.yes")), ("N", tr("help.no")), ("^C", tr("help.cancel"))]
        case .confirmReplace:
            return [("Y", tr("help.yes")), ("N", tr("help.no")), ("A", tr("help.all")), ("^C", tr("help.cancel"))]
        case .search, .replaceSearch, .replaceWith:
            return [("^C", tr("help.cancel")), ("^M", tr("help.set_search")), ("^R", tr("help.replace"))]
        case .saveFilePath, .insertFilePath, .openFilePath:
            return [("^C", tr("help.cancel")), ("Tab", tr("help.complete")), ("^M", tr("help.confirm"))]
        case .gotoLine, .tableDimensions, .fillText, .spellCheck:
            return [("^C", tr("help.cancel")), ("^M", tr("help.confirm"))]
        case .logoMacro:
            return [
                ("^C", tr("help.cancel")), ("Tab", tr("help.complete")), ("^M", tr("help.execute")),
                ("↑↓", tr("help.history")),
            ]
        case .logoReadWord, .logoReadChar:
            return [("^C", tr("help.cancel")), ("^M", tr("help.submit"))]
        case .describeKey:
            return nil
        }
    }
}
