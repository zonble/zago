import Foundation

/// Nano-style UI state machine and core editor engine.
public final class Editor {
    private let terminal: Terminal
    public let buffer: TextBuffer
    public let layoutEngine: LayoutEngine

    private var isRunning = true
    private var statusMessage: String = ""
    private var statusMessageTime: Date?

    private var clipboardText: String? = nil
    private var selectionMark: (line: Int, column: Int)? = nil

    // UI Viewport Scrolling Offset (measured in VirtualLineIndex units)
    private var topVLineIndex: Int = 0

    private let spellChecker = SpellChecker()

    // Prompt state mode (handles Ctrl+O file path input, Ctrl+X exit confirmation, Ctrl+W search, Ctrl+R insert file, Ctrl+T spell check)
    private enum PromptMode {
        case none
        case saveFilePath(completion: (String?) -> Void)
        case confirmExitSave(completion: (Bool?) -> Void)
        case search(completion: (String?) -> Void)
        case insertFilePath(completion: (String?) -> Void)
        case spellCheck(word: String, line: Int, col: Int, completion: (String?) -> Void)
    }
    private var currentPromptMode: PromptMode = .none
    private var promptInputText: String = ""
    private var lastSearchQuery: String = ""

    public struct UndoSnapshot: Equatable {
        public let lines: [String]
        public let lineIndex: Int
        public let columnIndex: Int
        public let isModified: Bool
    }

    private var undoStack: [UndoSnapshot] = []
    private let maxUndoStackSize = 100
    private var lastMutationTime: Date?
    private var lastIsPaste: Bool = false

    public let commandRegistry = CommandRegistry()
    public var showRuler: Bool = false

    public init(filePath: String? = nil, wrapColumn: Int? = nil, showRuler: Bool? = nil) {
        self.terminal = Terminal()
        self.buffer = TextBuffer(filePath: filePath)

        let loadedConfig = ConfigLoader().loadConfig()

        // CLI argument priority > .serc config > default
        let finalWrap = wrapColumn ?? loadedConfig.wrapColumn
        let finalRuler = showRuler ?? loadedConfig.showRuler

        self.layoutEngine = LayoutEngine(wrapColumn: finalWrap)
        self.showRuler = finalRuler

        setupDefaultCommands()
        applyCustomConfig(loadedConfig)
    }

    /// Applies custom user configuration loaded from ~/.serc or ./.serc files.
    private func applyCustomConfig(_ config: EditorConfig) {
        for key in config.unbindKeys {
            commandRegistry.unbind(key: key)
        }

        for (key, cmdId) in config.customKeyBinds {
            if let cmd = commandRegistry.commands.first(where: { $0.id == cmdId }) {
                commandRegistry.bind(key: key, command: cmd)
            }
        }

        if config.syntaxErrorCount > 0 {
            setStatusMessage("[ Config loaded with \(config.syntaxErrorCount) syntax error(s) ]")
        }
    }

    /// Registers default editor commands and keybindings.
    private func setupDefaultCommands() {
        // Navigation Commands
        commandRegistry.register(Command(id: "move.right", name: "Forward", description: "Move forward a character", keys: [.ctrl("F"), .arrowRight]) { editor in
            let currentLineLength = editor.buffer.lines[editor.buffer.lineIndex].count
            if editor.buffer.columnIndex < currentLineLength {
                editor.buffer.columnIndex += 1
            } else if editor.buffer.lineIndex < editor.buffer.lines.count - 1 {
                editor.buffer.lineIndex += 1
                editor.buffer.columnIndex = 0
            }
        })

        commandRegistry.register(Command(id: "move.left", name: "Backward", description: "Move backward a character", keys: [.ctrl("B"), .arrowLeft]) { editor in
            if editor.buffer.columnIndex > 0 {
                editor.buffer.columnIndex -= 1
            } else if editor.buffer.lineIndex > 0 {
                editor.buffer.lineIndex -= 1
                editor.buffer.columnIndex = editor.buffer.lines[editor.buffer.lineIndex].count
            }
        })

        commandRegistry.register(Command(id: "move.up", name: "Prev Line", description: "Move up a visual line", keys: [.ctrl("P"), .arrowUp]) { editor in
            editor.moveCursorVirtual(deltaRow: -1)
        })

        commandRegistry.register(Command(id: "move.down", name: "Next Line", description: "Move down a visual line", keys: [.ctrl("N"), .arrowDown]) { editor in
            editor.moveCursorVirtual(deltaRow: 1)
        })

        commandRegistry.register(Command(id: "select.left", name: "Select Left", description: "Extend selection left", keys: [.shiftArrowLeft]) { editor in
            if editor.selectionMark == nil {
                editor.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
                editor.setStatusMessage("Mark Set")
            }
            if editor.buffer.columnIndex > 0 {
                editor.buffer.columnIndex -= 1
            } else if editor.buffer.lineIndex > 0 {
                editor.buffer.lineIndex -= 1
                editor.buffer.columnIndex = editor.buffer.lines[editor.buffer.lineIndex].count
            }
        })

        commandRegistry.register(Command(id: "select.right", name: "Select Right", description: "Extend selection right", keys: [.shiftArrowRight]) { editor in
            if editor.selectionMark == nil {
                editor.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
                editor.setStatusMessage("Mark Set")
            }
            let currentLineLength = editor.buffer.lines[editor.buffer.lineIndex].count
            if editor.buffer.columnIndex < currentLineLength {
                editor.buffer.columnIndex += 1
            } else if editor.buffer.lineIndex < editor.buffer.lines.count - 1 {
                editor.buffer.lineIndex += 1
                editor.buffer.columnIndex = 0
            }
        })

        commandRegistry.register(Command(id: "select.up", name: "Select Up", description: "Extend selection up", keys: [.shiftArrowUp]) { editor in
            if editor.selectionMark == nil {
                editor.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
                editor.setStatusMessage("Mark Set")
            }
            editor.moveCursorVirtual(deltaRow: -1)
        })

        commandRegistry.register(Command(id: "select.down", name: "Select Down", description: "Extend selection down", keys: [.shiftArrowDown]) { editor in
            if editor.selectionMark == nil {
                editor.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
                editor.setStatusMessage("Mark Set")
            }
            editor.moveCursorVirtual(deltaRow: 1)
        })

        commandRegistry.register(Command(id: "move.home", name: "Line Home", description: "Move to start of visual line", keys: [.ctrl("A"), .home]) { editor in
            let vLine = editor.getVirtualLineForCursor()
            editor.buffer.columnIndex = vLine.startCol
        })

        commandRegistry.register(Command(id: "move.end", name: "Line End", description: "Move to end of visual line", keys: [.ctrl("E"), .end]) { editor in
            let vLine = editor.getVirtualLineForCursor()
            let realLineLen = editor.buffer.lines[vLine.bufferLineIndex].count
            if vLine.endCol > vLine.startCol && vLine.endCol < realLineLen {
                editor.buffer.columnIndex = vLine.endCol - 1
            } else {
                editor.buffer.columnIndex = vLine.endCol
            }
        })

        commandRegistry.register(Command(id: "move.pageUp", name: "Prev Page", description: "Move up one page", keys: [.ctrl("Y"), .f7, .pageUp]) { editor in
            let (rows, _) = editor.terminal.getWindowSize()
            editor.moveCursorVirtual(deltaRow: -(rows - 4))
        })

        commandRegistry.register(Command(id: "move.pageDown", name: "Next Page", description: "Move down one page", keys: [.ctrl("V"), .f8, .pageDown]) { editor in
            let (rows, _) = editor.terminal.getWindowSize()
            editor.moveCursorVirtual(deltaRow: (rows - 4))
        })

        // File & Exit Commands
        commandRegistry.register(Command(id: "file.exit", name: "Exit", description: "Exit editor", keys: [.ctrl("X"), .f2]) { editor in
            if editor.buffer.isModified {
                editor.promptExitSaveConfirm()
            } else {
                editor.isRunning = false
            }
        })

        commandRegistry.register(Command(id: "file.save", name: "Write Out", description: "Save buffer to file", keys: [.ctrl("O"), .ctrl("S"), .f3]) { editor in
            if let currentPath = editor.buffer.filePath, !currentPath.isEmpty {
                editor.doSave(to: currentPath)
            } else {
                editor.promptSaveFilePath()
            }
        })

        commandRegistry.register(Command(id: "file.insert", name: "Read File", description: "Insert file content", keys: [.ctrl("R"), .f5]) { editor in
            editor.promptInsertFilePath()
        })

        // Search & Edit & Undo Commands
        commandRegistry.register(Command(id: "edit.search", name: "Where Is", description: "Search text", keys: [.ctrl("W"), .f6]) { editor in
            editor.promptSearch()
        })

        commandRegistry.register(Command(id: "screen.refresh", name: "Refresh", description: "Refresh screen", keys: [.ctrl("L")]) { _ in
            Terminal.clearScreen()
        })

        commandRegistry.register(Command(id: "edit.undo", name: "Undo", description: "Undo last edit", keys: [.ctrl("Z")]) { editor in
            editor.performUndo()
        })

        commandRegistry.register(Command(id: "edit.delete", name: "Delete", description: "Delete character", keys: [.ctrl("D"), .delete]) { editor in
            editor.saveUndoSnapshot()
            editor.buffer.delete()
        })

        commandRegistry.register(Command(id: "edit.mark", name: "Mark", description: "Set or unset selection mark", keys: [.mark]) { editor in
            if editor.selectionMark == nil {
                editor.selectionMark = (line: editor.buffer.lineIndex, column: editor.buffer.columnIndex)
                editor.setStatusMessage("Mark Set")
            } else {
                editor.selectionMark = nil
                editor.setStatusMessage("Mark Unset")
            }
        })

        commandRegistry.register(Command(id: "edit.cut", name: "Cut Text", description: "Cut selected text or line", keys: [.ctrl("K"), .f9]) { editor in
            editor.saveUndoSnapshot()
            editor.buffer.clampCursor()
            if let mark = editor.selectionMark {
                let cursor = (line: editor.buffer.lineIndex, col: editor.buffer.columnIndex)
                let start: (line: Int, col: Int)
                let end: (line: Int, col: Int)

                if (cursor.line < mark.line) || (cursor.line == mark.line && cursor.col < mark.column) {
                    start = cursor
                    end = (line: mark.line, col: mark.column)
                } else {
                    start = (line: mark.line, col: mark.column)
                    end = cursor
                }

                editor.clipboardText = editor.buffer.cutRange(start: start, end: end)
                editor.selectionMark = nil
                editor.setStatusMessage("Cut text")
            } else {
                let currentLine = editor.buffer.lines[editor.buffer.lineIndex]
                editor.clipboardText = currentLine + "\n"
                if editor.buffer.lines.count > 1 {
                    editor.buffer.lines.remove(at: editor.buffer.lineIndex)
                } else {
                    editor.buffer.lines[0] = ""
                }
                editor.buffer.isModified = true
                editor.setStatusMessage("Cut 1 line")
            }
        })

        commandRegistry.register(Command(id: "edit.uncut", name: "UnCut Text", description: "Paste cut text", keys: [.ctrl("U"), .f10]) { editor in
            if let text = editor.clipboardText, !text.isEmpty {
                editor.saveUndoSnapshot()
                editor.buffer.insertString(text)
                editor.setStatusMessage("Uncut text")
            } else {
                editor.setStatusMessage("Clipboard is empty")
            }
        })

        commandRegistry.register(Command(id: "edit.tab", name: "Tab", description: "Insert 4 spaces", keys: [.tab, .ctrl("I")]) { editor in
            editor.saveUndoSnapshot()
            for _ in 0..<4 {
                editor.buffer.insert(character: " ")
            }
        })

        commandRegistry.register(Command(id: "edit.justify", name: "Justify", description: "Format paragraph width", keys: [.ctrl("J"), .f4]) { editor in
            editor.saveUndoSnapshot()
            let (_, cols) = editor.terminal.getWindowSize()
            let targetWidth = editor.layoutEngine.wrapColumn ?? max(20, cols - 5)
            editor.buffer.justifyParagraph(targetWidth: targetWidth)
            editor.setStatusMessage("Justified paragraph")
        })

        commandRegistry.register(Command(id: "edit.spell", name: "To Spell", description: "Check spelling", keys: [.ctrl("T"), .f12]) { editor in
            editor.promptSpellCheck()
        })

        commandRegistry.register(Command(id: "status.curpos", name: "Cur Pos", description: "Report cursor position", keys: [.ctrl("C"), .f11]) { editor in
            let totalLines = editor.buffer.lines.count
            let currentLine = editor.buffer.lineIndex + 1
            let percent = totalLines > 0 ? Int(Double(currentLine) / Double(totalLines) * 100) : 100
            let currentCol = editor.buffer.columnIndex + 1
            let totalCol = editor.buffer.lines[editor.buffer.lineIndex].count + 1
            editor.setStatusMessage("line \(currentLine)/\(totalLines) (\(percent)%), col \(currentCol)/\(totalCol)")
        })

        commandRegistry.register(Command(id: "help.show", name: "Get Help", description: "Show full-screen help", keys: [.ctrl("G"), .f1]) { editor in
            let helpView = HelpView(terminal: editor.terminal)
            helpView.show()
        })
    }

    /// Starts the editor event loop.
    public func run() {
        terminal.enableRawMode()
        Terminal.hideCursor()

        defer {
            Terminal.clearScreen()
            Terminal.showCursor()
            terminal.disableRawMode()
        }

        while isRunning {
            refreshScreen()
            let key = terminal.readKey()
            processKey(key)
        }
    }

    /// Sets status message to display in the bottom status line.
    private func setStatusMessage(_ msg: String) {
        self.statusMessage = msg
        self.statusMessageTime = Date()
    }

    /// Saves a snapshot of the buffer and cursor position to the undo stack before mutation.
    public func saveUndoSnapshot() {
        lastIsPaste = false
        let snapshot = UndoSnapshot(
            lines: buffer.lines,
            lineIndex: buffer.lineIndex,
            columnIndex: buffer.columnIndex,
            isModified: buffer.isModified
        )
        if undoStack.last != snapshot {
            undoStack.append(snapshot)
            if undoStack.count > maxUndoStackSize {
                undoStack.removeFirst()
            }
        }
    }

    /// Performs Undo (^Z).
    public func performUndo() {
        guard let snapshot = undoStack.popLast() else {
            setStatusMessage("Already at oldest change")
            return
        }
        buffer.lines = snapshot.lines
        buffer.lineIndex = max(0, min(snapshot.lineIndex, buffer.lines.count - 1))
        buffer.columnIndex = max(0, min(snapshot.columnIndex, buffer.lines[buffer.lineIndex].count))
        buffer.isModified = snapshot.isModified
        setStatusMessage("Undo performed")
    }

    /// Processes key input events.
    private func processKey(_ key: Key) {
        // Handle input if currently in bottom prompt mode
        if case .none = currentPromptMode {
            // Normal mode
        } else {
            processPromptKey(key)
            return
        }

        if commandRegistry.dispatch(key: key, editor: self) {
            buffer.clampCursor()
            return
        }

        switch key {
        case .backspace:
            saveUndoSnapshot()
            buffer.backspace()

        case .enter:
            saveUndoSnapshot()
            buffer.insertNewline()

        case .char(let ch):
            let pastedText = terminal.readPendingText(firstChar: ch)
            let isMultiChar = (pastedText.count > 1)
            let now = Date()

            let isCoalescedPaste = isMultiChar && lastIsPaste && (lastMutationTime != nil && now.timeIntervalSince(lastMutationTime!) < 0.5)

            if !isCoalescedPaste {
                saveUndoSnapshot()
            }

            lastIsPaste = isMultiChar
            lastMutationTime = now

            if !isMultiChar {
                buffer.insert(character: ch)
            } else {
                buffer.insertString(pastedText)
            }

        case .unknown:
            break

        default:
            setStatusMessage("Unknown command")
        }

        buffer.clampCursor()
    }

    /// Returns the VirtualLine structure containing current cursor.
    private func getVirtualLineForCursor() -> VirtualLine {
        let (_, cols) = terminal.getWindowSize()
        let textWidth = max(10, cols - 5)
        let virtualLines = layoutEngine.computeVirtualLines(from: buffer.lines, viewWidth: textWidth)

        let (cursorVLineIdx, _) = layoutEngine.getVirtualCursor(
            lineIndex: buffer.lineIndex,
            columnIndex: buffer.columnIndex,
            virtualLines: virtualLines
        )

        if cursorVLineIdx >= 0 && cursorVLineIdx < virtualLines.count {
            return virtualLines[cursorVLineIdx]
        }

        return VirtualLine(
            bufferLineIndex: buffer.lineIndex,
            subLineIndex: 0,
            text: buffer.lines[buffer.lineIndex],
            startCol: 0,
            endCol: buffer.lines[buffer.lineIndex].count
        )
    }

    /// Maps virtual line index and target visual display column width to real buffer cursor.
    private func getBufferCursorForVisualColumn(
        vLineIndex: Int,
        targetDisplayCol: Int,
        virtualLines: [VirtualLine]
    ) -> (lineIndex: Int, columnIndex: Int) {
        guard !virtualLines.isEmpty else { return (0, 0) }
        let clampedVLineIndex = max(0, min(vLineIndex, virtualLines.count - 1))
        let vLine = virtualLines[clampedVLineIndex]

        var currentWidth = 0
        var charIndex = 0

        for ch in vLine.text {
            let w = ch.displayWidth
            if currentWidth + w > targetDisplayCol {
                break
            }
            currentWidth += w
            charIndex += 1
        }

        let realCol = vLine.startCol + charIndex
        return (vLine.bufferLineIndex, realCol)
    }

    /// Moves cursor vertically across virtual display lines, maintaining visual display column alignment.
    private func moveCursorVirtual(deltaRow: Int) {
        let (_, cols) = terminal.getWindowSize()
        let gutterWidth = 5
        let textWidth = max(10, cols - gutterWidth)

        let virtualLines = layoutEngine.computeVirtualLines(from: buffer.lines, viewWidth: textWidth)
        let (currentVLineIdx, _) = layoutEngine.getVirtualCursor(
            lineIndex: buffer.lineIndex,
            columnIndex: buffer.columnIndex,
            virtualLines: virtualLines
        )

        guard currentVLineIdx >= 0 && currentVLineIdx < virtualLines.count else { return }

        let currentVLine = virtualLines[currentVLineIdx]
        let colInSubLine = max(0, min(buffer.columnIndex - currentVLine.startCol, currentVLine.text.count))
        let subLineChars = Array(currentVLine.text)
        let currentDisplayCol = subLineChars[..<colInSubLine].reduce(0) { $0 + $1.displayWidth }

        let newVLineIdx = max(0, min(currentVLineIdx + deltaRow, virtualLines.count - 1))
        let (newLine, newCol) = getBufferCursorForVisualColumn(
            vLineIndex: newVLineIdx,
            targetDisplayCol: currentDisplayCol,
            virtualLines: virtualLines
        )

        buffer.lineIndex = newLine
        buffer.columnIndex = newCol
    }

    /// Prompts user to input file path for saving.
    private func promptSaveFilePath() {
        promptInputText = buffer.filePath ?? ""
        currentPromptMode = .saveFilePath(completion: { [weak self] path in
            guard let self = self, let path = path, !path.isEmpty else {
                self?.setStatusMessage("Cancelled")
                return
            }
            self.doSave(to: path)
        })
    }

    /// Prompts user to confirm saving changes before exiting.
    private func promptExitSaveConfirm() {
        currentPromptMode = .confirmExitSave(completion: { [weak self] save in
            guard let self = self, let save = save else {
                self?.setStatusMessage("Cancelled exit")
                return
            }
            if save {
                if let path = self.buffer.filePath, !path.isEmpty {
                    self.doSave(to: path)
                    self.isRunning = false
                } else {
                    self.promptSaveFilePath()
                }
            } else {
                self.isRunning = false
            }
        })
    }

    /// Saves buffer to specified file path.
    private func doSave(to path: String) {
        do {
            try buffer.saveFile(to: path)
            setStatusMessage("[ Wrote \(buffer.lines.count) lines to \(path) ]")
        } catch {
            setStatusMessage("Error saving file: \(error.localizedDescription)")
        }
    }

    /// Processes keyboard input when in prompt mode.
    private func processPromptKey(_ key: Key) {
        switch currentPromptMode {
        case .saveFilePath(let completion):
            switch key {
            case .enter:
                let result = promptInputText
                currentPromptMode = .none
                completion(result)
            case .esc, .ctrl("C"):
                currentPromptMode = .none
                completion(nil)
            case .backspace:
                if !promptInputText.isEmpty {
                    promptInputText.removeLast()
                }
            case .char(let ch):
                promptInputText.append(ch)
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
                if !promptInputText.isEmpty {
                    promptInputText.removeLast()
                }
            case .char(let ch):
                promptInputText.append(ch)
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
                if !promptInputText.isEmpty {
                    promptInputText.removeLast()
                }
            case .char(let ch):
                promptInputText.append(ch)
            default:
                break
            }

        case .spellCheck(_, _, _, let completion):
            switch key {
            case .enter:
                let result = promptInputText
                currentPromptMode = .none
                completion(result)
            case .esc, .ctrl("C"):
                currentPromptMode = .none
                completion(nil)
            case .backspace:
                if !promptInputText.isEmpty {
                    promptInputText.removeLast()
                }
            case .char(let ch):
                promptInputText.append(ch)
            default:
                break
            }

        case .none:
            break
        }
    }

    /// Prompts user to input search query (Where Is / ^W).
    private func promptSearch() {
        promptInputText = ""
        currentPromptMode = .search(completion: { [weak self] query in
            guard let self = self else { return }
            let targetQuery: String
            if let q = query, !q.isEmpty {
                targetQuery = q
            } else if !self.lastSearchQuery.isEmpty {
                targetQuery = self.lastSearchQuery
            } else {
                self.setStatusMessage("Cancelled search")
                return
            }
            self.performSearch(query: targetQuery)
        })
    }

    /// Performs text search for target query string.
    private func performSearch(query: String) {
        guard !query.isEmpty else { return }
        self.lastSearchQuery = query

        let totalLines = buffer.lines.count
        let startLine = buffer.lineIndex
        let startCol = buffer.columnIndex + 1

        // 1. Search forward from current cursor position
        for lIdx in startLine..<totalLines {
            let line = buffer.lines[lIdx]
            let fromCol = (lIdx == startLine) ? startCol : 0
            if fromCol < line.count {
                let searchStr = String(line.suffix(line.count - fromCol))
                if let range = searchStr.range(of: query, options: .caseInsensitive) {
                    let colOffset = searchStr.distance(from: searchStr.startIndex, to: range.lowerBound)
                    buffer.lineIndex = lIdx
                    buffer.columnIndex = fromCol + colOffset
                    setStatusMessage("Found \"\(query)\" at line \(lIdx + 1)")
                    return
                }
            }
        }

        // 2. Wrap search around from line 0
        for lIdx in 0...startLine {
            let line = buffer.lines[lIdx]
            let toCol = (lIdx == startLine) ? startCol : line.count
            let searchStr = String(line.prefix(toCol))
            if let range = searchStr.range(of: query, options: .caseInsensitive) {
                let colOffset = searchStr.distance(from: searchStr.startIndex, to: range.lowerBound)
                buffer.lineIndex = lIdx
                buffer.columnIndex = colOffset
                setStatusMessage("Search wrapped, found \"\(query)\" at line \(lIdx + 1)")
                return
            }
        }

        setStatusMessage("\"\(query)\" not found")
    }

    /// Prompts user to input file path to insert into buffer (^R / F5).
    private func promptInsertFilePath() {
        promptInputText = ""
        currentPromptMode = .insertFilePath(completion: { [weak self] path in
            guard let self = self, let path = path, !path.isEmpty else {
                self?.setStatusMessage("Cancelled insert")
                return
            }
            do {
                self.saveUndoSnapshot()
                let count = try self.buffer.insertFile(at: path)
                self.setStatusMessage("[ Inserted \(count) lines ]")
            } catch {
                self.setStatusMessage("Error inserting file: \(error.localizedDescription)")
            }
        })
    }

    /// Prompts user to check and replace misspelled words (^T / F12).
    private func promptSpellCheck() {
        if let target = spellChecker.findNextMisspelled(in: buffer) {
            buffer.lineIndex = target.line
            buffer.columnIndex = target.col
            promptInputText = target.word
            currentPromptMode = .spellCheck(word: target.word, line: target.line, col: target.col, completion: { [weak self] replacement in
                guard let self = self, let newWord = replacement, !newWord.isEmpty else {
                    self?.setStatusMessage("Spell check skipped")
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
                    self.setStatusMessage("Replaced '\(target.word)' with '\(newWord)'")
                } else {
                    self.setStatusMessage("Word kept")
                }
            })
        } else {
            setStatusMessage("[ No misspelled words found ]")
        }
    }

    /// Checks if a buffer character (line, col) is within the current selection mark range.
    private func isCharacterSelected(line: Int, col: Int) -> Bool {
        guard let mark = selectionMark else { return false }
        let cursor = (line: buffer.lineIndex, col: buffer.columnIndex)

        let start: (line: Int, col: Int)
        let end: (line: Int, col: Int)

        if (cursor.line < mark.line) || (cursor.line == mark.line && cursor.col < mark.column) {
            start = cursor
            end = (line: mark.line, col: mark.column)
        } else {
            start = (line: mark.line, col: mark.column)
            end = cursor
        }

        if line < start.line || line > end.line { return false }
        if line == start.line && col < start.col { return false }
        if line == end.line && col >= end.col { return false }

        return true
    }

    /// Generates a classic WordStar-style ruler bar string (e.g. "----!----1----!----2----!----3").
    public func generateWordStarRuler(width: Int) -> String {
        var ruler = ""
        for col in 1...width {
            if col % 10 == 0 {
                let digit = (col / 10) % 10
                ruler.append(String(digit))
            } else if col % 5 == 0 {
                ruler.append("!")
            } else {
                ruler.append("-")
            }
        }
        return ruler
    }

    /// Double-buffered screen rendering logic.
    private func refreshScreen() {
        let (rows, cols) = terminal.getWindowSize()
        let gutterWidth = 5
        let textWidth = max(10, cols - gutterWidth)

        let virtualLines = layoutEngine.computeVirtualLines(from: buffer.lines, viewWidth: textWidth)
        let (cursorVLineIdx, cursorVColIdx) = layoutEngine.getVirtualCursor(
            lineIndex: buffer.lineIndex,
            columnIndex: buffer.columnIndex,
            virtualLines: virtualLines
        )

        // Calculate Viewport Scrolling
        let mainAreaHeight = max(1, rows - (showRuler ? 5 : 4)) // 1 top title, 1 optional ruler, 1 status, 2 key help
        if cursorVLineIdx < topVLineIndex {
            topVLineIndex = cursorVLineIdx
        } else if cursorVLineIdx >= topVLineIndex + mainAreaHeight {
            topVLineIndex = cursorVLineIdx - mainAreaHeight + 1
        }

        var output = ""
        output += "\u{1B}[H" // Reset cursor to (1, 1)

        // 1. Title Bar (Inverted Colors, centered filename)
        let leftText = "  se"
        let centerText = buffer.filePath ?? "New Buffer"
        let rightText = buffer.isModified ? "Modified  " : "  "

        let leftW = leftText.displayWidth
        let centerW = centerText.displayWidth
        let rightW = rightText.displayWidth

        let targetCenterStart = max(leftW + 1, (cols - centerW) / 2)
        let leftPaddingCount = max(0, targetCenterStart - leftW)
        let leftSideWidth = leftW + leftPaddingCount

        let rightPaddingCount = max(0, cols - leftSideWidth - centerW - rightW)

        let titleStr = leftText
            + String(repeating: " ", count: leftPaddingCount)
            + centerText
            + String(repeating: " ", count: rightPaddingCount)
            + rightText

        let paddedTitle = titleStr.paddedToDisplayWidth(cols)
        output += "\u{1B}[7m\(paddedTitle)\u{1B}[m\r\n"

        // 1.5 Optional WordStar Ruler Bar
        if showRuler {
            let rulerStr = generateWordStarRuler(width: textWidth)
            output += "\u{1B}[K\u{1B}[90m     \(rulerStr)\u{1B}[0m\r\n"
        }

        // 2. Main Edit Area (Virtual Lines Rendering)
        for i in 0..<mainAreaHeight {
            let vIndex = topVLineIndex + i
            output += "\u{1B}[K" // Clear line

            if vIndex < virtualLines.count {
                let vLine = virtualLines[vIndex]
                let isFirstSubLine = (vLine.subLineIndex == 0)

                // Gutter (Line Number or Softwrap Indicator ↳)
                let lineNumStr: String
                if isFirstSubLine {
                    lineNumStr = String(format: "%4d ", vLine.bufferLineIndex + 1)
                } else {
                    lineNumStr = "   ↳ "
                }

                output += "\u{1B}[90m\(lineNumStr)\u{1B}[0m" // Dim gray gutter
                let chars = Array(vLine.text)
                for (cIdxInVLine, ch) in chars.enumerated() {
                    let realCol = vLine.startCol + cIdxInVLine
                    if isCharacterSelected(line: vLine.bufferLineIndex, col: realCol) {
                        output += "\u{1B}[7m\(ch)\u{1B}[m" // Inverse video for selected characters
                    } else {
                        output += String(ch)
                    }
                }
            }
            output += "\r\n"
        }

        // 3. Status / Prompt Line
        output += "\u{1B}[K" // Clear line
        switch currentPromptMode {
        case .saveFilePath:
            output += "\u{1B}[1mFile Name to Write: \(promptInputText)_\u{1B}[0m"
        case .confirmExitSave:
            output += "\u{1B}[1;33mSave modified buffer? (Answering \"N\" will discard changes) [Y/N]: \u{1B}[0m"
        case .search:
            let defaultHint = lastSearchQuery.isEmpty ? "" : " [default: \(lastSearchQuery)]"
            output += "\u{1B}[1mSearch\(defaultHint): \(promptInputText)_\u{1B}[0m"
        case .insertFilePath:
            output += "\u{1B}[1mFile to insert: \(promptInputText)_\u{1B}[0m"
        case .spellCheck(let word, _, _, _):
            output += "\u{1B}[1mEdit misspelled word \"\(word)\": \(promptInputText)_\u{1B}[0m"
        case .none:
            if let time = statusMessageTime, Date().timeIntervalSince(time) < 5.0 {
                let msgWidth = statusMessage.displayWidth
                let leftPaddingCount = max(0, (cols - msgWidth) / 2)
                let centeredMsg = String(repeating: " ", count: leftPaddingCount) + statusMessage
                output += centeredMsg.paddedToDisplayWidth(cols)
            }
        }
        output += "\r\n"

        // 4. Nano Key Help Bar (2 lines) - 2D column-aligned, dynamic gap spacing, no leading space
        output += formatHelpBar(cols: cols)

        // 5. Position Terminal Cursor (accounting for CJK/wide character display width)
        let vLineText = virtualLines[cursorVLineIdx].text
        let vLineChars = Array(vLineText)
        let clampedCol = max(0, min(cursorVColIdx, vLineChars.count))
        let cursorDisplayWidth = vLineChars[..<clampedCol].reduce(0) { $0 + $1.displayWidth }

        let screenRow = (cursorVLineIdx - topVLineIndex) + (showRuler ? 3 : 2) // +3 if ruler, +2 for title bar
        let screenCol = gutterWidth + cursorDisplayWidth + 1
        output += "\u{1B}[\(screenRow);\(screenCol)H"
        output += "\u{1B}[?25h" // Show cursor

        print(output, terminator: "")
        // Safely flush stdout buffer using fflush(nil) without referencing C global mutable 'stdout' in Swift 6 concurrency mode
        fflush(nil)
    }

    /// Formats Nano help bar lines with 2D column alignment and dynamic gap spacing (Bold Cyan keys, no leading space).
    private func formatHelpBar(cols: Int) -> String {
        let helpWidth = min(cols, 80)
        let helpItems1: [(key: String, label: String)] = [
            ("^G", "Get Help"), ("^O", "WriteOut"), ("^R", "Read File"),
            ("^Y", "Prev Pg"),  ("^K", "Cut Text"), ("^C", "Cur Pos")
        ]
        let helpItems2: [(key: String, label: String)] = [
            ("^X", "Exit"),     ("^J", "Justify"),  ("^W", "Where Is"),
            ("^V", "Next Pg"),  ("^U", "UnCut Text"), ("^T", "To Spell")
        ]

        let numCols = min(helpItems1.count, helpItems2.count)
        var maxColWidths: [Int] = []
        for i in 0..<numCols {
            let w1 = helpItems1[i].key.count + 1 + helpItems1[i].label.count
            let w2 = helpItems2[i].key.count + 1 + helpItems2[i].label.count
            maxColWidths.append(max(w1, w2))
        }

        let totalItemsWidth = maxColWidths.reduce(0, +)
        let gapCount = max(1, numCols - 1)
        let availableGapSpace = helpWidth - totalItemsWidth

        let gapSize = max(1, min(2, availableGapSpace / gapCount))
        let gapStr = String(repeating: " ", count: gapSize)

        func renderLine(_ items: [(key: String, label: String)]) -> String {
            var result = ""
            var currentDisplayWidth = 0

            for i in 0..<items.count {
                let targetColWidth = (i < maxColWidths.count) ? maxColWidths[i] : (items[i].key.count + 1 + items[i].label.count)
                let itemStr = "\u{1B}[1;36m\(items[i].key)\u{1B}[0m \(items[i].label)"
                let rawWidth = items[i].key.count + 1 + items[i].label.count
                let padCount = max(0, targetColWidth - rawWidth)
                let paddedItem = itemStr + String(repeating: " ", count: padCount)

                if i > 0 {
                    if currentDisplayWidth + gapSize + targetColWidth > helpWidth {
                        break
                    }
                    result += gapStr
                    currentDisplayWidth += gapSize
                }

                if currentDisplayWidth + targetColWidth > helpWidth {
                    break
                }

                result += paddedItem
                currentDisplayWidth += targetColWidth
            }

            if currentDisplayWidth < cols {
                result += String(repeating: " ", count: cols - currentDisplayWidth)
            }
            return result
        }

        let line1 = "\u{1B}[K" + renderLine(helpItems1)
        let line2 = "\u{1B}[K" + renderLine(helpItems2)
        return line1 + "\r\n" + line2
    }
}
