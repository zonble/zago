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
        case spellCheck(word: String, line: Int, col: Int, completion: (String?) -> Void)
        case logoMacro(completion: (String?) -> Void)
        case fillText(completion: (String?) -> Void)
        case tableDimensions(completion: (String?) -> Void)
        case gotoLine(completion: (String?) -> Void)
        case describeKey(completion: (Key) -> Void)
        case logoReadWord(prompt: String)
        case logoReadChar(prompt: String)
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

    /// Resets all transient prompt input states.
    func reset() {
        mode = .none
        singleLineEditor.reset()
        completionText = nil
    }

    /// Returns whether a prompt is currently active.
    var isActive: Bool {
        if case .none = mode { return false }
        return true
    }

    /// KeyInputHandler protocol implementation.
    func handleKey(_ key: Key) -> Bool {
        guard isActive else { return false }

        if case .describeKey(let completion) = mode {
            if key == .unknown || key == .resize {
                return false
            }
            mode = .none
            inputText = ""
            cursorIndex = 0
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
                exitEditorFromPrompt()
                return true
            }

        case .editCut:
            if isTextEditingPromptMode {
                cutPromptSelectionOrSuffix()
                return true
            }

        case .editCopy:
            if isTextEditingPromptMode {
                copyPromptSelection()
                return true
            }

        case .editUncut:
            if isTextEditingPromptMode {
                pastePromptClipboard()
                return true
            }

        case .selectAll:
            if isTextEditingPromptMode {
                selectAllPromptText()
                return true
            }

        case .moveHome:
            cursorIndex = 0
            selectionAnchorIndex = nil
            return true

        case .moveEnd:
            cursorIndex = inputText.count
            selectionAnchorIndex = nil
            return true

        case .moveLeft:
            cursorIndex = max(0, cursorIndex - 1)
            selectionAnchorIndex = nil
            return true

        case .moveRight:
            cursorIndex = min(inputText.count, cursorIndex + 1)
            selectionAnchorIndex = nil
            return true

        case .moveWordBackward:
            movePromptWordBackward()
            selectionAnchorIndex = nil
            return true

        case .moveWordForward:
            movePromptWordForward()
            selectionAnchorIndex = nil
            return true

        case .selectLeft:
            extendPromptSelection(to: max(0, cursorIndex - 1))
            return true

        case .selectRight:
            extendPromptSelection(to: min(inputText.count, cursorIndex + 1))
            return true

        case .selectWordBackward:
            extendPromptSelection(to: max(0, cursorIndex - 1))
            return true

        case .selectWordForward:
            extendPromptSelection(to: min(inputText.count, cursorIndex + 1))
            return true

        case .promptClearLine:
            clearPromptLine()
            return true

        case .editDelete:
            deletePromptDelete()
            return true

        default:
            break
        }

        processPromptKey(key)
        return true
    }

    /// Cancels active prompt mode.
    func cancel() {
        switch mode {
        case .saveFilePath(let completion):
            completion(nil)
            editor?.reportOperationResult(.cancelled(message: editor?.l10n["status.cancelled"] ?? ""))
        case .confirmExitSave(let completion):
            completion(nil)
        case .confirmExternalReload(let completion):
            completion(false)
        case .confirmEncodingFallback(_, let completion):
            completion(false)
        case .confirmBackupFailure(_, let completion):
            completion(false)
        case .search(let completion):
            completion(nil)
        case .replaceSearch(let completion), .replaceWith(_, let completion):
            completion(nil)
        case .confirmReplace(_, _, let completion):
            completion(.cancel)
        case .insertFilePath(let completion):
            completion(nil)
        case .spellCheck(_, _, _, let completion):
            completion(nil)
        case .logoMacro(let completion):
            completion(nil)
        case .fillText(let completion):
            completion(nil)
        case .tableDimensions(let completion):
            completion(nil)
        case .gotoLine(let completion):
            completion(nil)
        case .describeKey, .logoReadWord, .logoReadChar, .none:
            break
        }
        mode = .none
        inputText = ""
        completionText = nil
        cursorIndex = 0
        selectionAnchorIndex = nil
    }

    /// Processes keyboard input when in prompt mode.
    func processPromptKey(_ key: Key) {
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
                finishPrompt { completion(.yes) }
            case .char("n"), .char("N"):
                finishPrompt { completion(.no) }
            case .char("a"), .char("A"):
                finishPrompt { completion(.all) }
            default:
                break
            }

        case .insertFilePath(let completion):
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
                    deletePromptBackspace()
                case .char(let ch):
                    insertPromptChar(ch)
                default:
                    break
                }
            }

        case .fillText(let completion), .tableDimensions(let completion), .gotoLine(let completion):
            processTextInputPromptKey(key, trimWhitespace: false, completion: completion)

        case .logoReadWord:
            switch key {
            case .backspace:
                deletePromptBackspace()
            case .char(let ch):
                insertPromptChar(ch)
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
            mode = .none
            selectionAnchorIndex = nil
            completion(trimWhitespace && result.isEmpty ? nil : result)
            return
        }

        switch key {
        case .backspace:
            deletePromptBackspace()
        case .char(let ch):
            insertPromptChar(ch)
        default:
            break
        }
    }

    private func finishPrompt(_ action: () -> Void) {
        mode = .none
        selectionAnchorIndex = nil
        completionText = nil
        action()
    }

    private func processConfirmationPromptKey(_ key: Key, completion: (Bool) -> Void) {
        switch key {
        case .char("y"), .char("Y"), .enter:
            finishPrompt { completion(true) }
        case .char("n"), .char("N"):
            finishPrompt { completion(false) }
        default:
            break
        }
    }

    /// Helper for prompt inline character insertion at cursorIndex.
    func insertPromptChar(_ ch: Character) {
        completionText = nil
        singleLineEditor.insertChar(ch)
    }

    /// Helper to clear the entire prompt input line.
    func clearPromptLine() {
        completionText = nil
        singleLineEditor.clearLine()
    }

    /// Helper for prompt inline backspace deletion.
    func deletePromptBackspace() {
        completionText = nil
        singleLineEditor.deleteBackspace()
    }

    /// Helper for prompt inline delete key deletion.
    func deletePromptDelete() {
        completionText = nil
        singleLineEditor.deleteForward()
    }

    private var isTextEditingPromptMode: Bool {
        switch mode {
        case .saveFilePath, .search, .replaceSearch, .replaceWith, .insertFilePath, .spellCheck, .logoMacro, .fillText,
            .tableDimensions,
            .gotoLine,
            .logoReadWord:
            return true
        case .none, .confirmExitSave, .confirmExternalReload, .confirmEncodingFallback, .confirmBackupFailure, .confirmReplace, .describeKey,
            .logoReadChar:
            return false
        }
    }

    private func movePromptWordForward() {
        singleLineEditor.moveWordForward()
    }

    private func selectAllPromptText() {
        singleLineEditor.selectAll()
    }

    private func exitEditorFromPrompt() {
        mode = .none
        singleLineEditor.reset()
        completionText = nil
        guard let editor else { return }
        _ = editor.commandRegistry.dispatch(id: .fileExit, editor: editor)
    }

    private func extendPromptSelection(to newCursorIndex: Int) {
        completionText = nil
        singleLineEditor.extendSelection(to: newCursorIndex)
    }

    func selectionRange() -> Range<Int>? {
        singleLineEditor.selectionRange
    }

    private func selectedPromptText() -> String? {
        singleLineEditor.selectedText
    }

    @discardableResult
    private func deletePromptSelectionIfNeeded() -> Bool {
        completionText = nil
        return singleLineEditor.deleteSelectionIfNeeded()
    }

    private func copyPromptSelection() {
        var clip = editor?.clipboardText
        singleLineEditor.copy(to: &clip)
        editor?.clipboardText = clip
        completionText = nil
    }

    private func cutPromptSelectionOrSuffix() {
        completionText = nil
        var clip = editor?.clipboardText
        singleLineEditor.cut(to: &clip)
        editor?.clipboardText = clip
    }

    private func pastePromptClipboard() {
        completionText = nil
        singleLineEditor.paste(from: editor?.clipboardText)
    }

    private func movePromptWordBackward() {
        singleLineEditor.moveWordBackward()
    }

    private func replacePromptPrefix(_ replacement: String) {
        completionText = nil
        selectionAnchorIndex = nil
        let clamped = max(0, min(cursorIndex, inputText.count))
        let splitIndex = inputText.index(inputText.startIndex, offsetBy: clamped)
        inputText = replacement + inputText[splitIndex...]
        cursorIndex = replacement.count
    }

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
                let lcp = longestCommonPrefix(of: matches)
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
            let lcp = longestCommonPrefix(of: matches)
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

        guard !token.isEmpty, isCommandBarCompletionToken(token) else {
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
            let lcp = longestCommonPrefix(of: matches)
            if lcp.count > token.count {
                replacePromptPrefix(leadingContext + lcp)
            }
            showCommandBarCompletions(matches, label: "Tab")
        } else {
            showCommandBarCompletions([], label: "Tab")
        }
        return true
    }

    private func longestCommonPrefix(of strings: [String]) -> String {
        guard let first = strings.first, !first.isEmpty else { return "" }
        var prefix = first
        for s in strings.dropFirst() {
            while !s.lowercased().hasPrefix(prefix.lowercased()) {
                prefix.removeLast()
                if prefix.isEmpty { return "" }
            }
        }
        return prefix
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

    private func isCommandBarCompletionToken(_ token: String) -> Bool {
        !token.isEmpty && token.allSatisfy(isCompletionTokenChar)
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
        case .saveFilePath, .insertFilePath:
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
