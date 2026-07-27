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

    // Prompt state mode (handles Ctrl+O file path input, Ctrl+X exit confirmation, Ctrl+W search, Ctrl+R insert file)
    private enum PromptMode {
        case none
        case saveFilePath(completion: (String?) -> Void)
        case confirmExitSave(completion: (Bool?) -> Void)
        case search(completion: (String?) -> Void)
        case insertFilePath(completion: (String?) -> Void)
    }
    private var currentPromptMode: PromptMode = .none
    private var promptInputText: String = ""
    private var lastSearchQuery: String = ""

    public init(filePath: String? = nil, wrapColumn: Int? = nil) {
        self.terminal = Terminal()
        self.buffer = TextBuffer(filePath: filePath)
        self.layoutEngine = LayoutEngine(wrapColumn: wrapColumn)
        
        if let path = buffer.filePath {
            setStatusMessage("File loaded: \(path)")
        } else {
            setStatusMessage("New File")
        }
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

    /// Processes key input events.
    private func processKey(_ key: Key) {
        // Handle input if currently in bottom prompt mode
        if case .none = currentPromptMode {
            // Normal mode
        } else {
            processPromptKey(key)
            return
        }

        switch key {
        // Navigation Shortcuts
        case .ctrl("F"), .arrowRight:
            let currentLineLength = buffer.lines[buffer.lineIndex].count
            if buffer.columnIndex < currentLineLength {
                buffer.columnIndex += 1
            } else if buffer.lineIndex < buffer.lines.count - 1 {
                buffer.lineIndex += 1
                buffer.columnIndex = 0
            }

        case .ctrl("B"), .arrowLeft:
            if buffer.columnIndex > 0 {
                buffer.columnIndex -= 1
            } else if buffer.lineIndex > 0 {
                buffer.lineIndex -= 1
                buffer.columnIndex = buffer.lines[buffer.lineIndex].count
            }

        case .ctrl("P"), .arrowUp:
            moveCursorVirtual(deltaRow: -1)

        case .ctrl("N"), .arrowDown:
            moveCursorVirtual(deltaRow: 1)

        case .ctrl("A"), .home:
            buffer.columnIndex = 0

        case .ctrl("E"), .end:
            buffer.columnIndex = buffer.lines[buffer.lineIndex].count

        case .ctrl("Y"), .f7, .pageUp:
            let (rows, _) = terminal.getWindowSize()
            moveCursorVirtual(deltaRow: -(rows - 4))

        case .ctrl("V"), .f8, .pageDown:
            let (rows, _) = terminal.getWindowSize()
            moveCursorVirtual(deltaRow: (rows - 4))

        // File & Exit Shortcuts
        case .ctrl("X"), .f2:
            if buffer.isModified {
                promptExitSaveConfirm()
            } else {
                isRunning = false
            }

        case .ctrl("O"), .ctrl("S"), .f3:
            if let currentPath = buffer.filePath, !currentPath.isEmpty {
                doSave(to: currentPath)
            } else {
                promptSaveFilePath()
            }

        case .ctrl("R"), .f5:
            promptInsertFilePath()

        // Search & Refresh Shortcuts
        case .ctrl("W"), .f6:
            promptSearch()

        case .ctrl("L"):
            Terminal.clearScreen()

        // Editing & Selection Shortcuts
        case .ctrl("D"), .delete:
            buffer.delete()

        case .mark:
            if selectionMark == nil {
                selectionMark = (line: buffer.lineIndex, column: buffer.columnIndex)
                setStatusMessage("Mark Set")
            } else {
                selectionMark = nil
                setStatusMessage("Mark Unset")
            }

        case .ctrl("K"), .f9:
            buffer.clampCursor()
            if let mark = selectionMark {
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

                clipboardText = buffer.cutRange(start: start, end: end)
                selectionMark = nil
                setStatusMessage("Cut text")
            } else {
                let currentLine = buffer.lines[buffer.lineIndex]
                clipboardText = currentLine + "\n"
                if buffer.lines.count > 1 {
                    buffer.lines.remove(at: buffer.lineIndex)
                } else {
                    buffer.lines[0] = ""
                }
                buffer.isModified = true
                setStatusMessage("Cut 1 line")
            }

        case .ctrl("U"), .f10:
            if let text = clipboardText, !text.isEmpty {
                buffer.insertString(text)
                setStatusMessage("Uncut text")
            } else {
                setStatusMessage("Clipboard is empty")
            }

        case .tab, .ctrl("I"):
            for _ in 0..<4 {
                buffer.insert(character: " ")
            }

        // Formatting & Status Shortcuts
        case .ctrl("J"), .f4:
            let (_, cols) = terminal.getWindowSize()
            let targetWidth = layoutEngine.wrapColumn ?? max(20, cols - 5)
            buffer.justifyParagraph(targetWidth: targetWidth)
            setStatusMessage("Justified paragraph")

        case .ctrl("T"), .f12:
            setStatusMessage("Spell checker not available")

        case .ctrl("C"), .f11:
            let totalLines = buffer.lines.count
            let currentLine = buffer.lineIndex + 1
            let percent = totalLines > 0 ? Int(Double(currentLine) / Double(totalLines) * 100) : 100
            let currentCol = buffer.columnIndex + 1
            let totalCol = buffer.lines[buffer.lineIndex].count + 1
            setStatusMessage("line \(currentLine)/\(totalLines) (\(percent)%), col \(currentCol)/\(totalCol)")

        case .ctrl("G"), .f1:
            setStatusMessage("se: Swift TUI Nano/Pico Editor [F2:Exit F3:Save F5:Insert F6:Search F9:Cut F10:Uncut]")

        case .backspace:
            buffer.backspace()
        case .enter:
            buffer.insertNewline()
        case .char(let ch):
            buffer.insert(character: ch)
        default:
            break
        }

        buffer.clampCursor()
    }

    /// Moves cursor vertically across virtual display lines.
    private func moveCursorVirtual(deltaRow: Int) {
        let (_, cols) = terminal.getWindowSize()
        let gutterWidth = 5
        let textWidth = max(10, cols - gutterWidth)

        let virtualLines = layoutEngine.computeVirtualLines(from: buffer.lines, viewWidth: textWidth)
        let (currentVLineIdx, currentVCol) = layoutEngine.getVirtualCursor(
            lineIndex: buffer.lineIndex,
            columnIndex: buffer.columnIndex,
            virtualLines: virtualLines
        )

        let newVLineIdx = currentVLineIdx + deltaRow
        let (newLine, newCol) = layoutEngine.getBufferCursor(
            vLineIndex: newVLineIdx,
            vColIndex: currentVCol,
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
                let count = try self.buffer.insertFile(at: path)
                self.setStatusMessage("[ Inserted \(count) lines ]")
            } catch {
                self.setStatusMessage("Error inserting file: \(error.localizedDescription)")
            }
        })
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
        let mainAreaHeight = max(1, rows - 4) // 1 top title, 1 status, 2 key help
        if cursorVLineIdx < topVLineIndex {
            topVLineIndex = cursorVLineIdx
        } else if cursorVLineIdx >= topVLineIndex + mainAreaHeight {
            topVLineIndex = cursorVLineIdx - mainAreaHeight + 1
        }

        var output = ""
        output += "\u{1B}[H" // Reset cursor to (1, 1)

        // 1. Title Bar (Inverted Colors)
        let titleName = buffer.filePath ?? "New Buffer"
        let modStr = buffer.isModified ? " Modified" : ""
        let rawTitle = "  se (Swift TUI Nano)  |  File: \(titleName)\(modStr)"
        let paddedTitle = rawTitle.paddedToDisplayWidth(cols)
        output += "\u{1B}[7m\(paddedTitle)\u{1B}[m\r\n"

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
        case .none:
            if let time = statusMessageTime, Date().timeIntervalSince(time) < 5.0 {
                output += "  \(statusMessage)"
            }
        }
        output += "\r\n"

        // 4. Nano Key Help Bar (2 lines) - Constrained within 80 columns without inverted background
        let helpWidth = min(cols, 80)
        let helpLine1 = " ^G Get Help   ^O WriteOut   ^R Read File  ^Y Prev Pg    ^K Cut Text   ^C Cur Pos"
        let helpLine2 = " ^X Exit       ^J Justify    ^W Where Is   ^V Next Pg    ^U UnCut Text ^T To Spell"
        output += formatHelpLine(helpLine1, width: helpWidth) + "\r\n"
        output += formatHelpLine(helpLine2, width: helpWidth)

        // 5. Position Terminal Cursor (accounting for CJK/wide character display width)
        let vLineText = virtualLines[cursorVLineIdx].text
        let vLineChars = Array(vLineText)
        let clampedCol = max(0, min(cursorVColIdx, vLineChars.count))
        let cursorDisplayWidth = vLineChars[..<clampedCol].reduce(0) { $0 + $1.displayWidth }

        let screenRow = (cursorVLineIdx - topVLineIndex) + 2 // +2 for title bar
        let screenCol = gutterWidth + cursorDisplayWidth + 1
        output += "\u{1B}[\(screenRow);\(screenCol)H"
        output += "\u{1B}[?25h" // Show cursor

        print(output, terminator: "")
        fflush(stdout)
    }

    /// Formats Nano help bar lines (Bold Cyan for key tags, no inverted background, constrained to width).
    private func formatHelpLine(_ rawText: String, width: Int) -> String {
        let trimmed = rawText.paddedToDisplayWidth(width)
        var result = ""
        let parts = trimmed.components(separatedBy: " ")
        for (idx, part) in parts.enumerated() {
            if part.hasPrefix("^") {
                result += "\u{1B}[1;36m\(part)\u{1B}[0m"
            } else {
                result += part
            }
            if idx < parts.count - 1 {
                result += " "
            }
        }
        return result
    }
}
