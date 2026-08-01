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
        case search(completion: (String?) -> Void)
        case insertFilePath(completion: (String?) -> Void)
        case spellCheck(word: String, line: Int, col: Int, completion: (String?) -> Void)
        case logoMacro(completion: (String?) -> Void)
        case fillText(completion: (String?) -> Void)
        case tableDimensions(completion: (String?) -> Void)
        case gotoLine(completion: (String?) -> Void)
        case confirmCreateTable(completion: (Bool?) -> Void)
    }

    /// Processes key input events.
    func processKey(_ key: Key) {
        if key == .resize {
            Terminal.clearScreen()
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
            if key == .esc {
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
                buffer.insertNewline()
                break
            }
            saveUndoSnapshot()
            if isCanvasModeActive {
                insertCanvasNewline()
            } else {
                buffer.insertNewline()
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
            showCommandBarCompletions(SettingCommandBarCommand.settingNames, label: command.uppercased())
            return true
        }

        let commandEnd = prefix.firstIndex(where: \.isWhitespace) ?? prefix.endIndex
        let restStart = prefix[commandEnd...].firstIndex(where: { !$0.isWhitespace }) ?? prefix.endIndex
        let rest = String(prefix[restStart...])

        guard !rest.isEmpty else {
            showCommandBarCompletions(SettingCommandBarCommand.settingNames, label: command.uppercased())
            return true
        }

        if let settingEnd = rest.firstIndex(where: \.isWhitespace) {
            let setting = String(rest[..<settingEnd])
            let valuePrefixStart = rest[settingEnd...].firstIndex(where: { !$0.isWhitespace }) ?? rest.endIndex
            let valuePrefix = String(rest[valuePrefixStart...]).lowercased()
            let matches = SettingCommandBarCommand.valueSuggestions(for: setting)
                .filter { valuePrefix.isEmpty || $0.lowercased().hasPrefix(valuePrefix) }

            if matches.count == 1 && !valuePrefix.isEmpty {
                replacePromptPrefix("\(command) \(setting) \(matches[0])")
            } else {
                showCommandBarCompletions(matches, label: setting)
            }
            return true
        }

        let settingPrefix = rest.lowercased()
        let matches = SettingCommandBarCommand.settingNames.filter { $0.hasPrefix(settingPrefix) }
        if matches.count == 1 && !settingPrefix.isEmpty {
            replacePromptPrefix("\(command) \(matches[0]) ")
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

        let tokenStartIndex = prefix.lastIndex(where: { !isCompletionTokenChar($0) })
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
        } else {
            showCommandBarCompletions(matches, label: "Tab")
        }
        return true
    }

    /// Processes keyboard input when in prompt mode.
    func processPromptKey(_ key: Key) {
        if handlePromptNavigationKeys(key) {
            return
        }

        switch currentPromptMode {
        case .saveFilePath(let completion):
            switch key {
            case .enter:
                let path = promptInputText.trimmingCharacters(in: .whitespacesAndNewlines)
                currentPromptMode = .none
                completion(path.isEmpty ? nil : path)
            case .esc, .ctrl("C"):
                cancelPrompt()
                setStatusMessage(L10n["status.cancelled"])
            case .backspace:
                deletePromptBackspace()
            case .char(let ch):
                insertPromptChar(ch)
            default:
                break
            }

        case .confirmExitSave(let completion):
            switch key {
            case .char("y"), .char("Y"):
                currentPromptMode = .none
                completion(true)
            case .char("n"), .char("N"):
                currentPromptMode = .none
                completion(false)
            case .esc, .ctrl("C"):
                currentPromptMode = .none
                completion(nil)
            default:
                break
            }

        case .confirmExternalReload(let completion):
            switch key {
            case .char("y"), .char("Y"), .enter:
                currentPromptMode = .none
                completion(true)
            case .char("n"), .char("N"), .esc, .ctrl("C"):
                currentPromptMode = .none
                completion(false)
            default:
                break
            }

        case .confirmCreateTable(let completion):
            switch key {
            case .char("y"), .char("Y"), .enter:
                currentPromptMode = .none
                completion(true)
            case .char("n"), .char("N"), .esc, .ctrl("C"):
                currentPromptMode = .none
                completion(false)
            default:
                break
            }

        case .search(let completion):
            switch key {
            case .enter:
                let result = promptInputText
                currentPromptMode = .none
                completion(result)
            case .esc, .ctrl("C"):
                currentPromptMode = .none
                completion(nil)
            case .backspace:
                deletePromptBackspace()
            case .char(let ch):
                insertPromptChar(ch)
            default:
                break
            }

        case .insertFilePath(let completion):
            switch key {
            case .enter:
                let result = promptInputText
                currentPromptMode = .none
                completion(result)
            case .esc, .ctrl("C"):
                currentPromptMode = .none
                completion(nil)
            case .backspace:
                deletePromptBackspace()
            case .char(let ch):
                insertPromptChar(ch)
            default:
                break
            }

        case .spellCheck(_, _, _, let completion):
            switch key {
            case .enter:
                let replacement = promptInputText.trimmingCharacters(in: .whitespacesAndNewlines)
                currentPromptMode = .none
                completion(replacement)
            case .esc, .ctrl("C"):
                currentPromptMode = .none
                completion(nil)
            case .backspace:
                deletePromptBackspace()
            case .char(let ch):
                insertPromptChar(ch)
            default:
                break
            }

        case .logoMacro(let completion):
            switch key {
            case .tab:
                if completeCommandBarPrompt() {
                    break
                }
            case .enter:
                let script = promptInputText
                promptCompletionText = nil
                if !script.isEmpty {
                    if logoPromptHistory.last != script {
                        logoPromptHistory.append(script)
                    }
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
            case .esc, .ctrl("C"):
                promptCompletionText = nil
                currentPromptMode = .none
                completion(nil)
            case .backspace:
                deletePromptBackspace()
            case .char(let ch):
                insertPromptChar(ch)
            default:
                break
            }

        case .fillText(let completion), .tableDimensions(let completion):
            switch key {
            case .enter:
                let text = promptInputText
                currentPromptMode = .none
                completion(text)
            case .esc, .ctrl("C"):
                currentPromptMode = .none
                completion(nil)
            case .backspace:
                deletePromptBackspace()
            case .char(let ch):
                insertPromptChar(ch)
            default:
                break
            }

        case .gotoLine(let completion):
            switch key {
            case .enter:
                let lineStr = promptInputText
                currentPromptMode = .none
                completion(lineStr)
            case .esc, .ctrl("C"):
                currentPromptMode = .none
                completion(nil)
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

    /// Performs search operation for target query string.
    public func performSearch(query: String, useRegex: Bool = false) {
        guard !query.isEmpty else { return }

        let activeRegex: Bool = useRegex || isRegexSearchEnabled
        let startLine = buffer.lineIndex
        let startCol = buffer.columnIndex

        if activeRegex, let regex = try? NSRegularExpression(pattern: query, options: [.caseInsensitive]) {
            // 1. Search forward from current position with Regex
            for lIdx in startLine..<buffer.lines.count {
                let line = buffer.lines[lIdx]
                let fromCol = (lIdx == startLine) ? min(startCol + 1, line.count) : 0
                if fromCol < line.count {
                    let searchStr = String(line.suffix(line.count - fromCol))
                    let nsRange = NSRange(searchStr.startIndex..<searchStr.endIndex, in: searchStr)
                    if let match = regex.firstMatch(in: searchStr, options: [], range: nsRange),
                       let range = Range(match.range(at: 0), in: searchStr) {
                        let colOffset = searchStr.distance(from: searchStr.startIndex, to: range.lowerBound)
                        buffer.lineIndex = lIdx
                        buffer.columnIndex = fromCol + colOffset
                        setStatusMessage(L10n.foundQueryAtLine(query: query, line: lIdx + 1))
                        return
                    }
                }
            }

            // 2. Wrap search around from line 0 with Regex
            for lIdx in 0...startLine {
                let line = buffer.lines[lIdx]
                let toCol = (lIdx == startLine) ? startCol : line.count
                let searchStr = String(line.prefix(toCol))
                let nsRange = NSRange(searchStr.startIndex..<searchStr.endIndex, in: searchStr)
                if let match = regex.firstMatch(in: searchStr, options: [], range: nsRange),
                   let range = Range(match.range(at: 0), in: searchStr) {
                    let colOffset = searchStr.distance(from: searchStr.startIndex, to: range.lowerBound)
                    buffer.lineIndex = lIdx
                    buffer.columnIndex = colOffset
                    setStatusMessage(L10n.searchWrappedFound(query: query, line: lIdx + 1))
                    return
                }
            }
        } else {
            // 1. Search forward from current position with String
            for lIdx in startLine..<buffer.lines.count {
                let line = buffer.lines[lIdx]
                let fromCol = (lIdx == startLine) ? min(startCol + 1, line.count) : 0
                if fromCol < line.count {
                    let searchStr = String(line.suffix(line.count - fromCol))
                    if let range = searchStr.range(of: query, options: .caseInsensitive) {
                        let colOffset = searchStr.distance(from: searchStr.startIndex, to: range.lowerBound)
                        buffer.lineIndex = lIdx
                        buffer.columnIndex = fromCol + colOffset
                        setStatusMessage(L10n.foundQueryAtLine(query: query, line: lIdx + 1))
                        return
                    }
                }
            }

            // 2. Wrap search around from line 0 with String
            for lIdx in 0...startLine {
                let line = buffer.lines[lIdx]
                let toCol = (lIdx == startLine) ? startCol : line.count
                let searchStr = String(line.prefix(toCol))
                if let range = searchStr.range(of: query, options: .caseInsensitive) {
                    let colOffset = searchStr.distance(from: searchStr.startIndex, to: range.lowerBound)
                    buffer.lineIndex = lIdx
                    buffer.columnIndex = colOffset
                    setStatusMessage(L10n.searchWrappedFound(query: query, line: lIdx + 1))
                    return
                }
            }
        }

        setStatusMessage(L10n.notFound(query: query))
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
                let count = try self.buffer.insertFile(at: path)
                self.setStatusMessage(L10n.insertedLines(count))
            } catch {
                self.setStatusMessage(L10n.errorInsertingFile(error: error.localizedDescription))
            }
        })
    }

    /// Prompts user to check and replace misspelled words (^T / F12).
    func promptSpellCheck() {
        if let target = spellChecker.findNextMisspelled(in: buffer) {
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
            guard let self = self, let input = input?.trimmingCharacters(in: .whitespacesAndNewlines), !input.isEmpty else {
                self?.setStatusMessage(L10n["status.cancelled"])
                return
            }
            self.runLogoScript("TABLE \(input)")
        })
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

    /// Toggles Menu Bar mode on ESC key in normal edit mode.
    func toggleMenuBar() {
        isMenuBarActive.toggle()
        if isMenuBarActive {
            menuBar.updateCategories(for: self)
            menuBar.categoryIndex = 0
            menuBar.itemIndex = 0
        }
    }

    /// Handles key input navigation when Menu Bar is active.
    func processMenuBarKey(_ key: Key) {
        switch key {
        case .esc, .ctrl("C"):
            isMenuBarActive = false

        case .arrowLeft:
            menuBar.categoryIndex = (menuBar.categoryIndex - 1 + menuBar.categories.count) % menuBar.categories.count
            menuBar.itemIndex = min(menuBar.itemIndex, max(0, menuBar.currentCategory.items.count - 1))

        case .arrowRight:
            menuBar.categoryIndex = (menuBar.categoryIndex + 1) % menuBar.categories.count
            menuBar.itemIndex = min(menuBar.itemIndex, max(0, menuBar.currentCategory.items.count - 1))

        case .arrowUp:
            let count = menuBar.currentCategory.items.count
            if count > 0 {
                menuBar.itemIndex = (menuBar.itemIndex - 1 + count) % count
            }

        case .arrowDown:
            let count = menuBar.currentCategory.items.count
            if count > 0 {
                menuBar.itemIndex = (menuBar.itemIndex + 1) % count
            }

        case .home:
            menuBar.itemIndex = 0

        case .end:
            menuBar.itemIndex = max(0, menuBar.currentCategory.items.count - 1)

        case .pageUp:
            menuBar.categoryIndex = 0
            menuBar.itemIndex = min(menuBar.itemIndex, max(0, menuBar.currentCategory.items.count - 1))

        case .pageDown:
            menuBar.categoryIndex = max(0, menuBar.categories.count - 1)
            menuBar.itemIndex = min(menuBar.itemIndex, max(0, menuBar.currentCategory.items.count - 1))

        case .enter:
            executeCurrentMenuItem()

        case .char(let ch):
            let lowerCh = Character(String(ch).lowercased())
            // Check if letter matches any category hotkey (f, e, s, b, t, h)
            if let catIdx = menuBar.categories.firstIndex(where: { $0.hotkeyChar == lowerCh }) {
                menuBar.categoryIndex = catIdx
                menuBar.itemIndex = 0
            } else {
                // Check if letter matches any item hotkey within active category
                let items = menuBar.currentCategory.items
                if let itemIdx = items.firstIndex(where: { $0.hotkeyChar == lowerCh }) {
                    menuBar.itemIndex = itemIdx
                    executeCurrentMenuItem()
                }
            }

        default:
            break
        }
    }

    /// Executes current selected menu item action.
    func executeCurrentMenuItem() {
        guard let item = menuBar.currentItem else { return }
        isMenuBarActive = false

        if let cmdId = item.commandId {
            _ = commandRegistry.dispatch(id: cmdId, editor: self)
        } else if let action = item.action {
            action(self)
        }
    }

    /// Saves buffer to specified file path.
    func doSave(to path: String) {
        do {
            try buffer.saveFile(to: path)
            setStatusMessage(L10n.wroteToFile("\(path) (\(buffer.lines.count) lines)"))
        } catch {
            setStatusMessage(L10n.errorSavingFile(error: error.localizedDescription))
        }
    }
}
