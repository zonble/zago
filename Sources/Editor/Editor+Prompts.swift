import Foundation
import LogoEngine
import TextMetrics

extension Editor {
    // Prompt state mode (handles Ctrl+O file path input, Ctrl+X exit
    // confirmation, Ctrl+W search, Ctrl+R insert file, Ctrl+T spell check)
    public enum PromptMode {
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
    }

    /// Processes key input events.
    func processKey(_ key: Key) {
        if key == .resize {
            terminal.clearScreen()
            return
        }

        // Handle input if currently in bottom prompt mode
        if case .none = currentPromptMode {
            if isMenuBarActive {
                processMenuBarKey(key)
                return
            }
            if key == .f1 || key == .ctrl("M") {
                toggleMenuBar()
                return
            }
        } else {
            if key == .esc || key == .ctrl("C") || key == .ctrl("G") {
                cancelPrompt()
                return
            }
            processPromptKey(key)
            return
        }

        if buffer.handleKey(key, editor: self) {
            return
        }

        if processTableModeKey(key) {
            return
        }

        if processCanvasDrawingKey(key) {
            return
        }

        if (key == .shiftHome || key == .shiftEnd) && (isCanvasModeActive || isTableModeActive) {
            return
        }

        if isCanvasModeActive {
            switch key {
            case .pageUp:
                saveUndoSnapshot()
                clearActiveMark()
                let pageStep = max(1, terminal.getWindowSize().rows - (displayConfig.showRuler ? 5 : 4))
                let originalCanvasColumn = canvasVisualColumn
                buffer.lineIndex = max(0, buffer.lineIndex - pageStep)
                canvasVisualColumn = originalCanvasColumn
                syncCanvasCursorToBuffer()
                return
            case .pageDown:
                saveUndoSnapshot()
                clearActiveMark()
                let pageStep = max(1, terminal.getWindowSize().rows - (displayConfig.showRuler ? 5 : 4))
                let targetLine = min(buffer.lines.count - 1, buffer.lineIndex + pageStep)
                let originalCanvasColumn = canvasVisualColumn
                buffer.lineIndex = max(0, targetLine)
                canvasVisualColumn = originalCanvasColumn
                syncCanvasCursorToBuffer()
                return
            default:
                break
            }
        }

        if commandRegistry.dispatch(key: key, editor: self) {
            if isTableModeActive {
                clampTableModeCursor()
            } else if isCanvasModeActive {
                syncCanvasCursorToBuffer()
            } else {
                buffer.clampCursor()
            }
            return
        }

        switch key {
        case .backspace:
            if !isCanvasModeActive && deleteTextSelectionIfNeeded(updateClipboard: false) {
                break
            }
            saveUndoSnapshot()
            if isCanvasModeActive {
                backspaceCanvasCharacter()
            } else {
                buffer.backspace()
            }

        case .enter:
            if !isCanvasModeActive && deleteTextSelectionIfNeeded(updateClipboard: false) {
                buffer.insertNewline(enableListAutoIndent: isListAutoIndentSupportedBuffer)
                break
            }
            saveUndoSnapshot()
            if isCanvasModeActive {
                insertCanvasNewline()
            } else {
                buffer.insertNewline(enableListAutoIndent: isListAutoIndentSupportedBuffer)
            }

        case .char(let ch):
            let pastedText = terminal.readPendingText(firstChar: ch)
            let isMultiChar = (pastedText.count > 1)
            let now = Date()
            let replacedSelection = !isCanvasModeActive && selectionMark != nil

            let isCoalescedPaste =
                isMultiChar && lastIsPaste
                && (lastMutationTime != nil && now.timeIntervalSince(lastMutationTime!) < 0.5)

            if replacedSelection {
                _ = deleteTextSelectionIfNeeded(updateClipboard: false)
            } else if !isCoalescedPaste {
                saveUndoSnapshot()
            }

            if isTableModeActive {
                pasteTableCellText(pastedText)
            } else if isCanvasModeActive {
                insertCanvasString(pastedText)
            } else if !isMultiChar {
                buffer.insert(character: ch)
            } else {
                buffer.insertString(pastedText)
            }

            lastIsPaste = isMultiChar
            lastMutationTime = now

        case .unknown:
            break

        default:
            setStatusMessage(L10n["status.unknown_command"])
        }

        if isCanvasModeActive {
            syncCanvasCursorToBuffer()
        } else {
            buffer.clampCursor()
        }
    }

    /// Helper for prompt inline character insertion at promptCursorIndex.
    private func insertPromptChar(_ ch: Character) {
        promptCompletionText = nil
        let clamped = max(0, min(promptCursorIndex, promptInputText.count))
        let idx = promptInputText.index(promptInputText.startIndex, offsetBy: clamped)
        promptInputText.insert(ch, at: idx)
        promptCursorIndex = clamped + 1
    }

    /// Helper to clear the entire prompt input line (Ctrl+Backspace).
    private func clearPromptLine() {
        promptCompletionText = nil
        promptInputText = ""
        promptCursorIndex = 0
    }

    /// Helper for prompt inline backspace deletion.
    private func deletePromptBackspace() {
        promptCompletionText = nil
        if promptCursorIndex > 0 && !promptInputText.isEmpty {
            let clamped = max(1, min(promptCursorIndex, promptInputText.count))
            let idx = promptInputText.index(promptInputText.startIndex, offsetBy: clamped - 1)
            promptInputText.remove(at: idx)
            promptCursorIndex = clamped - 1
        }
    }

    /// Helper for prompt inline delete key deletion.
    private func deletePromptDelete() {
        promptCompletionText = nil
        if promptCursorIndex < promptInputText.count && !promptInputText.isEmpty {
            let clamped = max(0, min(promptCursorIndex, promptInputText.count - 1))
            let idx = promptInputText.index(promptInputText.startIndex, offsetBy: clamped)
            promptInputText.remove(at: idx)
        }
    }

    /// Handles common prompt navigation keys (Left, Right, Home, End, Delete, Ctrl+A/E/B/F/D).
    private func handlePromptNavigationKeys(_ key: Key) -> Bool {
        switch key {
        case .arrowLeft, .ctrl("B"):
            promptCursorIndex = max(0, promptCursorIndex - 1)
            return true
        case .arrowRight, .ctrl("F"):
            promptCursorIndex = min(promptInputText.count, promptCursorIndex + 1)
            return true
        case .ctrl("A"), .home:
            promptCursorIndex = 0
            return true

        case .ctrl("E"), .end:
            promptCursorIndex = promptInputText.count
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

    private func replacePromptPrefix(_ replacement: String) {
        promptCompletionText = nil
        let clamped = max(0, min(promptCursorIndex, promptInputText.count))
        let splitIndex = promptInputText.index(promptInputText.startIndex, offsetBy: clamped)
        promptInputText = replacement + promptInputText[splitIndex...]
        promptCursorIndex = replacement.count
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

    private func showCommandBarCompletions(_ items: [String], label: String) {
        if items.isEmpty {
            promptCompletionText = L10n["status.no_completions"]
        } else {
            let text = String(format: L10n["status.command_completions"], label, items.joined(separator: ", "))
            promptCompletionText = text
        }
    }

    private func completeSettingCommandPrompt() -> Bool {
        let clamped = max(0, min(promptCursorIndex, promptInputText.count))
        let cursorIndex = promptInputText.index(promptInputText.startIndex, offsetBy: clamped)
        let prefix = String(promptInputText[..<cursorIndex])
        let suffix = String(promptInputText[cursorIndex...])

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

        _ = suffix
        return true
    }

    private func completeCommandBarPrompt() -> Bool {
        let clamped = max(0, min(promptCursorIndex, promptInputText.count))
        let cursorIndex = promptInputText.index(promptInputText.startIndex, offsetBy: clamped)
        let prefix = String(promptInputText[..<cursorIndex])

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

        let commandNames = commandBarRegistry.completionNames(for: self)
        let logoNames = buffer.allowsLogoExecution ? LogoPrimitive.keywordAliases : []
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

    /// Common handler for text input prompts.
    private func processTextInputPromptKey(
        _ key: Key,
        trimWhitespace: Bool = false,
        completion: (String?) -> Void
    ) {
        switch key {
        case .enter:
            let raw = promptInputText
            let result = trimWhitespace ? raw.trimmingCharacters(in: .whitespacesAndNewlines) : raw
            currentPromptMode = .none
            completion(trimWhitespace && result.isEmpty ? nil : result)

        case .backspace:
            deletePromptBackspace()

        case .char(let ch):
            insertPromptChar(ch)

        default:
            break
        }
    }

    /// Processes keyboard input when in prompt mode.
    func processPromptKey(_ key: Key) {
        if handlePromptNavigationKeys(key) {
            return
        }

        if key == .esc || key == .ctrl("C") || key == .ctrl("G") {
            cancelPrompt()
            return
        }

        switch currentPromptMode {
        case .saveFilePath(let completion):
            processTextInputPromptKey(key, trimWhitespace: true, completion: completion)

        case .confirmExitSave(let completion):
            switch key {
            case .char("y"), .char("Y"):
                currentPromptMode = .none
                completion(true)
            case .char("n"), .char("N"):
                currentPromptMode = .none
                completion(false)
            default:
                break
            }

        case .confirmExternalReload(let completion):
            switch key {
            case .char("y"), .char("Y"), .enter:
                currentPromptMode = .none
                completion(true)
            case .char("n"), .char("N"):
                currentPromptMode = .none
                completion(false)
            default:
                break
            }

        case .confirmEncodingFallback(_, let completion):
            switch key {
            case .char("y"), .char("Y"):
                currentPromptMode = .none
                completion(true)
            case .char("n"), .char("N"):
                currentPromptMode = .none
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
                _ = completeCommandBarPrompt()
            case .enter:
                let script = promptInputText
                promptCompletionText = nil
                if !script.isEmpty && logoPromptHistory.last != script {
                    logoPromptHistory.append(script)
                }
                currentPromptMode = .none
                completion(script)
            case .arrowUp:
                promptCompletionText = nil
                if logoHistoryIndex > 0 {
                    logoHistoryIndex -= 1
                    promptInputText = logoPromptHistory[logoHistoryIndex]
                    promptCursorIndex = promptInputText.count
                }
            case .arrowDown:
                promptCompletionText = nil
                if logoHistoryIndex < logoPromptHistory.count - 1 {
                    logoHistoryIndex += 1
                    promptInputText = logoPromptHistory[logoHistoryIndex]
                    promptCursorIndex = promptInputText.count
                } else {
                    logoHistoryIndex = logoPromptHistory.count
                    promptInputText = ""
                    promptCursorIndex = 0
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

    /// Prompts user to input file path for saving (^O / ^S / F3).
    func promptWriteFilePath() {
        promptInputText = buffer.filePath ?? ""
        currentPromptMode = .saveFilePath(completion: { [weak self] path in
            guard let self = self, let path = path, !path.isEmpty else {
                self?.setStatusMessage(L10n["status.cancelled"])
                return
            }
            self.doSave(to: path)
        })
    }

    /// Saves current buffer to disk and closes current buffer / exits editor (F4).
    func promptSaveAndExit() {
        if let path = buffer.filePath, !path.isEmpty {
            doSave(to: path)
            closeCurrentBuffer()
        } else {
            promptInputText = ""
            currentPromptMode = .saveFilePath(completion: { [weak self] path in
                guard let self = self, let path = path, !path.isEmpty else {
                    self?.setStatusMessage(L10n["status.cancelled"])
                    return
                }
                self.doSave(to: path)
                self.closeCurrentBuffer()
            })
        }
    }

    /// Prompts user to save modified buffer before exiting (^X / F2).
    func promptExitSaveConfirm() {
        currentPromptMode = .confirmExitSave(completion: { [weak self] save in
            guard let self = self, let save = save else {
                self?.setStatusMessage(L10n["status.cancelled_exit"])
                return
            }
            if save {
                if let path = self.buffer.filePath, !path.isEmpty {
                    self.doSave(to: path)
                    self.closeCurrentBuffer()
                } else {
                    self.promptWriteFilePath()
                }
            } else {
                self.closeCurrentBuffer()
            }
        })
    }

    /// Prompts user for search string (^W / F6).
    func promptSearch() {
        promptInputText = ""
        currentPromptMode = .search(completion: { [weak self] query in
            guard let self = self, let query = query else {
                self?.setStatusMessage(L10n["status.cancelled_search"])
                return
            }
            let targetQuery: String
            if !query.isEmpty {
                targetQuery = query
                self.lastSearchQuery = query
            } else if !self.lastSearchQuery.isEmpty {
                targetQuery = self.lastSearchQuery
            } else {
                self.setStatusMessage(L10n["status.cancelled_search"])
                return
            }
            self.performSearch(query: targetQuery)
        })
    }

    /// Prompts user to input file path to insert into buffer (^R / F5).
    func promptInsertFilePath() {
        promptInputText = ""
        currentPromptMode = .insertFilePath(completion: { [weak self] path in
            guard let self = self, let path = path, !path.isEmpty else {
                self?.setStatusMessage(L10n["status.cancelled_insert"])
                return
            }
            do {
                self.saveUndoSnapshot()
                let count = try self.buffer.insertFile(at: path, fileIO: self.fileIOStrategy)
                self.setStatusMessage(L10n.insertedLines(count))
            } catch {
                self.setStatusMessage(L10n.errorInsertingFile(error: error.localizedDescription))
            }
        })
    }

    /// Prompts user to check and replace misspelled words (^T / F12).
    func promptSpellCheck() {
        let syntaxName = activeLanguageSyntax?.name
        if let target = spellChecker.findNextMisspelled(in: buffer, syntaxName: syntaxName) {
            buffer.lineIndex = target.line
            buffer.columnIndex = target.col
            promptInputText = target.word
            currentPromptMode = .spellCheck(
                word: target.word, line: target.line, col: target.col,
                completion: { [weak self] replacement in
                    guard let self = self, let newWord = replacement, !newWord.isEmpty else {
                        self?.setStatusMessage(L10n["status.spell_check_skipped"])
                        return
                    }
                    if newWord != target.word {
                        self.saveUndoSnapshot()
                        var lineStr = self.buffer.lines[target.line]
                        let sIdx = lineStr.index(lineStr.startIndex, offsetBy: target.col)
                        let eIdx = lineStr.index(sIdx, offsetBy: target.word.count)
                        lineStr.replaceSubrange(sIdx..<eIdx, with: newWord)
                        self.buffer.lines[target.line] = lineStr
                        self.buffer.isModified = true
                        self.setStatusMessage(L10n.replacedWord(target: target.word, newWord: newWord))
                    } else {
                        self.setStatusMessage(L10n["status.word_kept"])
                    }
                })
        } else {
            setStatusMessage(L10n["status.no_misspelled"])
        }
    }

    /// Cancels active prompt mode.
    func cancelPrompt() {
        switch currentPromptMode {
        case .saveFilePath(let completion):
            currentPromptMode = .none
            completion(nil)
            setStatusMessage(L10n["status.cancelled"])
        case .confirmExitSave(let completion):
            currentPromptMode = .none
            completion(nil)
        case .confirmExternalReload(let completion):
            currentPromptMode = .none
            completion(false)
        case .confirmEncodingFallback(_, let completion):
            currentPromptMode = .none
            completion(false)
        case .search(let completion):
            currentPromptMode = .none
            completion(nil)
        case .insertFilePath(let completion):
            currentPromptMode = .none
            completion(nil)
        case .spellCheck(_, _, _, let completion):
            currentPromptMode = .none
            completion(nil)
        case .logoMacro(let completion):
            currentPromptMode = .none
            completion(nil)
        case .fillText(let completion):
            currentPromptMode = .none
            completion(nil)
        case .tableDimensions(let completion):
            currentPromptMode = .none
            completion(nil)
        case .gotoLine(let completion):
            currentPromptMode = .none
            completion(nil)
        case .none:
            break
        }
        currentPromptMode = .none
        promptInputText = ""
        promptCompletionText = nil
    }

    /// Prompts user for LOGO macro script input (:logo / ^L).
    func promptLogoMacro() {
        promptInputText = ""
        logoHistoryIndex = logoPromptHistory.count
        currentPromptMode = .logoMacro(completion: { [weak self] script in
            guard let self = self, let script = script, !script.isEmpty else {
                self?.setStatusMessage(L10n["status.cancelled"])
                return
            }
            switch self.commandBarRegistry.dispatch(script, editor: self) {
            case .handled:
                break
            case .noMatch:
                self.runLogoScript(script)
            }
        })
    }

    func promptFillText() {
        promptInputText = ""
        currentPromptMode = .fillText(completion: { [weak self] text in
            guard let self = self, let text = text, !text.isEmpty else {
                self?.setStatusMessage(L10n["status.cancelled"])
                return
            }
            self.runLogoScript("FILL \(self.logoStringLiteral(text))")
        })
    }

    func promptTableDimensions() {
        promptInputText = "3 3 16"
        promptCursorIndex = promptInputText.count
        currentPromptMode = .tableDimensions(completion: { [weak self] input in
            guard let self = self, let input = input?.trimmingCharacters(in: .whitespacesAndNewlines), !input.isEmpty
            else {
                self?.setStatusMessage(L10n["status.cancelled"])
                return
            }
            let parts = input.components(separatedBy: .whitespaces).compactMap { Int($0) }
            let rows = parts.count > 0 ? parts[0] : 3
            let cols = parts.count > 1 ? parts[1] : 3

            if let syntaxName = self.activeLanguageSyntax?.name, syntaxName == "Markdown" || syntaxName == "Org-mode" {
                self.insertTextTable(rows: rows, cols: cols, isOrg: syntaxName == "Org-mode")
                return
            }

            let width = parts.count > 2 ? parts[2] : nil
            self.createTable(rows: rows, cols: cols, cellWidth: width, enterMode: true, saveSnapshot: true)
        })
    }

    func insertTextTable(rows: Int, cols: Int, isOrg: Bool) {
        saveUndoSnapshot()
        var tableLines: [String] = []
        var header = "|"
        for c in 1...cols {
            header += " Header \(c) |"
        }
        tableLines.append(header)

        if isOrg {
            var sep = "|"
            for (cIdx, _) in (1...cols).enumerated() {
                sep += "----------" + (cIdx == cols - 1 ? "|" : "+")
            }
            tableLines.append(sep)
        } else {
            var sep = "|"
            for _ in 1...cols {
                sep += " -------- |"
            }
            tableLines.append(sep)
        }

        for r in 1...rows {
            var rowStr = "|"
            for c in 1...cols {
                rowStr += " Cell \(r).\(c) |"
            }
            tableLines.append(rowStr)
        }

        let insertIdx = min(max(0, buffer.lineIndex), buffer.lines.count)
        buffer.lines.insert(contentsOf: tableLines, at: insertIdx)
        buffer.lineIndex = insertIdx
        buffer.columnIndex = 2
        setStatusMessage(L10n["status.table_created"])
    }

    private func logoStringLiteral(_ text: String) -> String {
        "\"\(text.replacingOccurrences(of: "\"", with: "'"))\""
    }

    /// Prompts user for target line/column number input (^/ / M-g).
    func promptGotoLine() {
        promptInputText = ""
        currentPromptMode = .gotoLine(completion: { [weak self] input in
            guard let self = self, let input = input, !input.isEmpty else {
                self?.setStatusMessage(L10n["status.cancelled"])
                return
            }
            self.performGotoLine(input)
        })
    }

    func performGotoLine(_ input: String) {
        let parts = input.components(separatedBy: CharacterSet(charactersIn: ", "))
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        if parts.isEmpty { return }

        goToLocation(line: parts[0], column: parts.count > 1 ? parts[1] : nil)
    }

    /// Saves buffer to specified file path.
    func doSave(to path: String, forcedEncoding: String.Encoding? = nil) {
        do {
            if displayConfig.trimTrailingWhitespaceOnSave && !buffer.isDirectoryBuffer {
                _ = buffer.trimTrailingWhitespace()
            }
            try buffer.saveFile(to: path, fileIO: fileIOStrategy, encoding: forcedEncoding)
            for b in buffers {
                if let dirBuf = b as? DirectoryBuffer {
                    dirBuf.loadDirectory(at: dirBuf.directoryPath)
                }
            }
            if forcedEncoding == .utf8 && buffer.fileEncoding == .utf8 {
                setStatusMessage(L10n["status.saved_as_utf8"])
            } else {
                setStatusMessage(L10n.wroteToFile("\(path) (\(buffer.lines.count) lines)"))
            }
        } catch EncodingError.unsupportedCharacters {
            let originalEncoding = buffer.fileEncoding
            currentPromptMode = .confirmEncodingFallback(originalEncoding: originalEncoding) { [weak self] confirmed in
                guard let self = self else { return }
                if confirmed {
                    self.doSave(to: path, forcedEncoding: .utf8)
                } else {
                    self.setStatusMessage(L10n["status.save_cancelled"])
                }
            }
        } catch {
            setStatusMessage(L10n.errorSavingFile(error: error.localizedDescription))
        }
    }
}
