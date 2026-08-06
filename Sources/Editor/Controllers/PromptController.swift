import Foundation
import LogoEngine
import TextMetrics
import TextTransform

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
            cancel(editor: editor)
            return true
        }
        processPromptKey(key, editor: editor)
        return true
    }

    /// Cancels active prompt mode.
    public func cancel(editor: Editor) {
        switch mode {
        case .saveFilePath(let completion):
            mode = .none
            completion(nil)
            editor.setStatusMessage(editor.l10n["status.cancelled"])
        case .confirmExitSave(let completion):
            mode = .none
            completion(nil)
        case .confirmExternalReload(let completion):
            mode = .none
            completion(false)
        case .confirmEncodingFallback(_, let completion):
            mode = .none
            completion(false)
        case .search(let completion):
            mode = .none
            completion(nil)
        case .insertFilePath(let completion):
            mode = .none
            completion(nil)
        case .spellCheck(_, _, _, let completion):
            mode = .none
            completion(nil)
        case .logoMacro(let completion):
            mode = .none
            completion(nil)
        case .fillText(let completion):
            mode = .none
            completion(nil)
        case .tableDimensions(let completion):
            mode = .none
            completion(nil)
        case .gotoLine(let completion):
            mode = .none
            completion(nil)
        case .logoReadWord, .logoReadChar:
            mode = .none
        case .none:
            break
        }
        mode = .none
        inputText = ""
        completionText = nil
        cursorIndex = 0
    }

    /// Processes keyboard input when in prompt mode.
    public func processPromptKey(_ key: Key, editor: Editor) {
        if handlePromptNavigationKeys(key) {
            return
        }

        if key == .esc || key == .ctrl("C") || key == .ctrl("G") {
            cancel(editor: editor)
            return
        }

        switch mode {
        case .logoReadWord, .logoReadChar:
            break
        case .saveFilePath(let completion):
            processTextInputPromptKey(key, trimWhitespace: true, completion: completion)

        case .confirmExitSave(let completion):
            switch key {
            case .char("y"), .char("Y"):
                mode = .none
                completion(true)
            case .char("n"), .char("N"):
                mode = .none
                completion(false)
            default:
                break
            }

        case .confirmExternalReload(let completion):
            switch key {
            case .char("y"), .char("Y"), .enter:
                mode = .none
                completion(true)
            case .char("n"), .char("N"):
                mode = .none
                completion(false)
            default:
                break
            }

        case .confirmEncodingFallback(_, let completion):
            switch key {
            case .char("y"), .char("Y"):
                mode = .none
                completion(true)
            case .char("n"), .char("N"):
                mode = .none
                completion(false)
            default:
                break
            }

        case .search(let completion):
            processTextInputPromptKey(key, trimWhitespace: false, completion: completion)

        case .insertFilePath(let completion):
            processTextInputPromptKey(key, trimWhitespace: false, completion: completion)

        case .spellCheck(_, _, _, let completion):
            processTextInputPromptKey(key, trimWhitespace: true, completion: completion)

        case .logoMacro(let completion):
            switch key {
            case .tab:
                _ = completeCommandBarPrompt(editor: editor)
            case .enter:
                let script = inputText
                completionText = nil
                if !script.isEmpty && logoHistory.last != script {
                    logoHistory.append(script)
                }
                mode = .none
                completion(script)
            case .arrowUp:
                completionText = nil
                if logoHistoryIndex > 0 {
                    logoHistoryIndex -= 1
                    inputText = logoHistory[logoHistoryIndex]
                    cursorIndex = inputText.count
                }
            case .arrowDown:
                completionText = nil
                if logoHistoryIndex < logoHistory.count - 1 {
                    logoHistoryIndex += 1
                    inputText = logoHistory[logoHistoryIndex]
                    cursorIndex = inputText.count
                } else {
                    logoHistoryIndex = logoHistory.count
                    inputText = ""
                    cursorIndex = 0
                }
            case .backspace:
                deletePromptBackspace()
            case .char(let ch):
                insertPromptChar(ch)
            default:
                break
            }

        case .fillText(let completion), .tableDimensions(let completion), .gotoLine(let completion):
            processTextInputPromptKey(key, trimWhitespace: false, completion: completion)

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
        switch key {
        case .enter:
            let raw = inputText
            let result = trimWhitespace ? raw.trimmingCharacters(in: .whitespacesAndNewlines) : raw
            mode = .none
            completion(trimWhitespace && result.isEmpty ? nil : result)

        case .backspace:
            deletePromptBackspace()

        case .char(let ch):
            insertPromptChar(ch)

        default:
            break
        }
    }

    /// Helper for prompt inline character insertion at cursorIndex.
    public func insertPromptChar(_ ch: Character) {
        completionText = nil
        let clamped = max(0, min(cursorIndex, inputText.count))
        let idx = inputText.index(inputText.startIndex, offsetBy: clamped)
        inputText.insert(ch, at: idx)
        cursorIndex = clamped + 1
    }

    /// Helper to clear the entire prompt input line.
    public func clearPromptLine() {
        completionText = nil
        inputText = ""
        cursorIndex = 0
    }

    /// Helper for prompt inline backspace deletion.
    public func deletePromptBackspace() {
        completionText = nil
        if cursorIndex > 0 && !inputText.isEmpty {
            let clamped = max(1, min(cursorIndex, inputText.count))
            let idx = inputText.index(inputText.startIndex, offsetBy: clamped - 1)
            inputText.remove(at: idx)
            cursorIndex = clamped - 1
        }
    }

    /// Helper for prompt inline delete key deletion.
    public func deletePromptDelete() {
        completionText = nil
        if cursorIndex < inputText.count && !inputText.isEmpty {
            let clamped = max(0, min(cursorIndex, inputText.count - 1))
            let idx = inputText.index(inputText.startIndex, offsetBy: clamped)
            inputText.remove(at: idx)
        }
    }

    /// Handles common prompt navigation keys (Left, Right, Home, End, Delete, Ctrl+A/E/B/F/D).
    private func handlePromptNavigationKeys(_ key: Key) -> Bool {
        switch key {
        case .arrowLeft, .ctrl("B"):
            cursorIndex = max(0, cursorIndex - 1)
            return true
        case .arrowRight, .ctrl("F"):
            cursorIndex = min(inputText.count, cursorIndex + 1)
            return true
        case .ctrlShift("b"), .ctrlShift("B"):
            movePromptWordBackward()
            return true
        case .ctrlShift("f"), .ctrlShift("F"):
            movePromptWordForward()
            return true
        case .ctrl("A"), .home:
            cursorIndex = 0
            return true

        case .ctrl("E"), .end:
            cursorIndex = inputText.count
            return true

        case .ctrlBackspace, .ctrl("U"):
            clearPromptLine()
            return true
        case .delete, .ctrl("D"):
            deletePromptDelete()
            return true
        default:
            return false
        }
    }

    private func movePromptWordForward() {
        let textChars = Array(inputText)
        if cursorIndex >= textChars.count { return }

        var idx = cursorIndex

        enum CharCategory {
            case asciiWord
            case cjkScript
            case nonWord
        }

        func category(at i: Int) -> CharCategory {
            let ch = textChars[i]
            if TextUnicodeClassifier.isCJKScriptCharacter(ch) {
                return .cjkScript
            } else if TextUnicodeClassifier.isASCIIWordCharacter(ch) {
                return .asciiWord
            } else {
                return .nonWord
            }
        }

        while idx < textChars.count && category(at: idx) == .nonWord {
            idx += 1
        }

        if idx >= textChars.count {
            cursorIndex = textChars.count
            return
        }

        let cat = category(at: idx)
        if cat == .cjkScript {
            cursorIndex = idx + 1
        } else if cat == .asciiWord {
            while idx < textChars.count && category(at: idx) == .asciiWord {
                idx += 1
            }
            cursorIndex = idx
        }
    }

    private func movePromptWordBackward() {
        let textChars = Array(inputText)
        if cursorIndex == 0 { return }

        var idx = min(cursorIndex, textChars.count)

        enum CharCategory {
            case asciiWord
            case cjkScript
            case nonWord
        }

        func category(at i: Int) -> CharCategory {
            let ch = textChars[i]
            if TextUnicodeClassifier.isCJKScriptCharacter(ch) {
                return .cjkScript
            } else if TextUnicodeClassifier.isASCIIWordCharacter(ch) {
                return .asciiWord
            } else {
                return .nonWord
            }
        }

        while idx > 0 && category(at: idx - 1) == .nonWord {
            idx -= 1
        }

        if idx == 0 {
            cursorIndex = 0
            return
        }

        let cat = category(at: idx - 1)
        if cat == .cjkScript {
            cursorIndex = idx - 1
        } else if cat == .asciiWord {
            while idx > 0 && category(at: idx - 1) == .asciiWord {
                idx -= 1
            }
            cursorIndex = idx
        }
    }

    private func replacePromptPrefix(_ replacement: String) {
        completionText = nil
        let clamped = max(0, min(cursorIndex, inputText.count))
        let splitIndex = inputText.index(inputText.startIndex, offsetBy: clamped)
        inputText = replacement + inputText[splitIndex...]
        cursorIndex = replacement.count
    }

    private func showCommandBarCompletions(_ items: [String], label: String, editor: Editor) {
        if items.isEmpty {
            completionText = editor.l10n["status.no_completions"]
        } else {
            let text = String(format: editor.l10n["status.command_completions"], label, items.joined(separator: ", "))
            completionText = text
        }
    }

    private func completeSettingCommandPrompt(editor: Editor) -> Bool {
        let clamped = max(0, min(cursorIndex, inputText.count))
        let splitIdx = inputText.index(inputText.startIndex, offsetBy: clamped)
        let prefix = String(inputText[..<splitIdx])

        let commandParts = prefix.split(maxSplits: 1, whereSeparator: \.isWhitespace).map(String.init)
        guard let command = commandParts.first?.lowercased(), command == "set" || command == "unset" else {
            return false
        }

        guard prefix.contains(where: \.isWhitespace) else {
            replacePromptPrefix(command + " ")
            showCommandBarCompletions(SettingCommand.settingNames, label: command.uppercased(), editor: editor)
            return true
        }

        let commandEnd = prefix.firstIndex(where: \.isWhitespace) ?? prefix.endIndex
        let restStart = prefix[commandEnd...].firstIndex(where: { !$0.isWhitespace }) ?? prefix.endIndex
        let rest = String(prefix[restStart...])

        guard !rest.isEmpty else {
            showCommandBarCompletions(SettingCommand.settingNames, label: command.uppercased(), editor: editor)
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
                showCommandBarCompletions(matches, label: setting, editor: editor)
            } else {
                showCommandBarCompletions(matches, label: setting, editor: editor)
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
            showCommandBarCompletions(matches, label: command.uppercased(), editor: editor)
        } else {
            showCommandBarCompletions(matches, label: command.uppercased(), editor: editor)
        }

        return true
    }

    private func completeCommandBarPrompt(editor: Editor) -> Bool {
        let clamped = max(0, min(cursorIndex, inputText.count))
        let splitIdx = inputText.index(inputText.startIndex, offsetBy: clamped)
        let prefix = String(inputText[..<splitIdx])

        if completeSettingCommandPrompt(editor: editor) {
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
            showCommandBarCompletions(matches, label: "Tab", editor: editor)
        } else {
            showCommandBarCompletions([], label: "Tab", editor: editor)
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
