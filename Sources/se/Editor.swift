import Foundation

/// Nano 介面狀態機與編輯器核心
public final class Editor {
    private let terminal: Terminal
    public let buffer: TextBuffer
    public let layoutEngine: LayoutEngine

    private var isRunning = true
    private var statusMessage: String = ""
    private var statusMessageTime: Date?

    private var clipboardLine: String? = nil

    // UI Viewport Scrolling Offset (以 虛擬行 VirtualLineIndex 為單位)
    private var topVLineIndex: Int = 0

    // Prompt 狀態 (處理 Ctrl+O 檔名輸入、Ctrl+X 儲存確認)
    private enum PromptMode {
        case none
        case saveFilePath(completion: (String?) -> Void)
        case confirmExitSave(completion: (Bool?) -> Void)
        case search(completion: (String?) -> Void)
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

    /// 啟動編輯器主循環 (Event Loop)
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

    /// 設定底部狀態列訊息
    private func setStatusMessage(_ msg: String) {
        self.statusMessage = msg
        self.statusMessageTime = Date()
    }

    /// 處理輸入按鍵
    private func processKey(_ key: Key) {
        // 如果目前處於底部 Prompt 輸入模式
        if case .none = currentPromptMode {
            // normal mode
        } else {
            processPromptKey(key)
            return
        }

        switch key {
        // Nano 快捷鍵: Ctrl+X (Exit)
        case .ctrl("X"), .ctrl("Q"):
            if buffer.isModified {
                promptExitSaveConfirm()
            } else {
                isRunning = false
            }

        // Nano 快捷鍵: Ctrl+O 或 Ctrl+S (WriteOut / Save)
        case .ctrl("O"), .ctrl("S"):
            if let currentPath = buffer.filePath, !currentPath.isEmpty {
                doSave(to: currentPath)
            } else {
                promptSaveFilePath()
            }

        // Nano 快捷鍵: Ctrl+K (Cut Line)
        case .ctrl("K"):
            buffer.clampCursor()
            clipboardLine = buffer.lines[buffer.lineIndex]
            if buffer.lines.count > 1 {
                buffer.lines.remove(at: buffer.lineIndex)
            } else {
                buffer.lines[0] = ""
            }
            buffer.isModified = true
            setStatusMessage("Cut 1 line")

        // Nano 快捷鍵: Ctrl+U (Uncut / Paste Line)
        case .ctrl("U"):
            if let clip = clipboardLine {
                buffer.lines.insert(clip, at: buffer.lineIndex)
                buffer.isModified = true
                setStatusMessage("Pasted 1 line")
            } else {
                setStatusMessage("Clipboard is empty")
            }

        // Nano 快捷鍵: Ctrl+J (Justify Paragraph)
        case .ctrl("J"):
            let (_, cols) = terminal.getWindowSize()
            let targetWidth = layoutEngine.wrapColumn ?? max(20, cols - 5)
            buffer.justifyParagraph(targetWidth: targetWidth)
            setStatusMessage("Justified paragraph")

        // Nano 快捷鍵: Ctrl+W (Where Is / Search)
        case .ctrl("W"), .ctrl("F"):
            promptSearch()

        // Nano 快捷鍵: Ctrl+C (Cur Pos)
        case .ctrl("C"):
            let totalLines = buffer.lines.count
            let currentLine = buffer.lineIndex + 1
            let percent = totalLines > 0 ? Int(Double(currentLine) / Double(totalLines) * 100) : 100
            let currentCol = buffer.columnIndex + 1
            let totalCol = buffer.lines[buffer.lineIndex].count + 1
            setStatusMessage("line \(currentLine)/\(totalLines) (\(percent)%), col \(currentCol)/\(totalCol)")

        // Nano 快捷鍵: Ctrl+Y (Prev Pg)
        case .ctrl("Y"):
            let (rows, _) = terminal.getWindowSize()
            moveCursorVirtual(deltaRow: -(rows - 4))

        // Nano 快捷鍵: Ctrl+V (Next Pg)
        case .ctrl("V"):
            let (rows, _) = terminal.getWindowSize()
            moveCursorVirtual(deltaRow: (rows - 4))

        // Nano 快捷鍵: Ctrl+G (Get Help)
        case .ctrl("G"):
            setStatusMessage("se: Swift TUI Nano Editor [Ctrl+O: Save, Ctrl+X: Exit, Ctrl+K: Cut, Ctrl+U: Uncut]")

        // Nano 快捷鍵: Ctrl+L (Refresh)
        case .ctrl("L"):
            Terminal.clearScreen()

        // 游標移動與編輯
        case .arrowUp:
            moveCursorVirtual(deltaRow: -1)
        case .arrowDown:
            moveCursorVirtual(deltaRow: 1)
        case .arrowLeft:
            if buffer.columnIndex > 0 {
                buffer.columnIndex -= 1
            } else if buffer.lineIndex > 0 {
                buffer.lineIndex -= 1
                buffer.columnIndex = buffer.lines[buffer.lineIndex].count
            }
        case .arrowRight:
            let currentLineLength = buffer.lines[buffer.lineIndex].count
            if buffer.columnIndex < currentLineLength {
                buffer.columnIndex += 1
            } else if buffer.lineIndex < buffer.lines.count - 1 {
                buffer.lineIndex += 1
                buffer.columnIndex = 0
            }
        case .home:
            buffer.columnIndex = 0
        case .end:
            buffer.columnIndex = buffer.lines[buffer.lineIndex].count
        case .pageUp:
            let (rows, _) = terminal.getWindowSize()
            moveCursorVirtual(deltaRow: -(rows - 4))
        case .pageDown:
            let (rows, _) = terminal.getWindowSize()
            moveCursorVirtual(deltaRow: (rows - 4))
        case .backspace:
            buffer.backspace()
        case .delete:
            buffer.delete()
        case .enter:
            buffer.insertNewline()
        case .char(let ch):
            buffer.insert(character: ch)
        default:
            break
        }

        buffer.clampCursor()
    }

    /// 在虛擬顯示行之間進行上下移動
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

    /// 提示儲存檔案路徑
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

    /// 提示退出前確認儲存
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

    /// 執行儲存動作
    private func doSave(to path: String) {
        do {
            try buffer.saveFile(to: path)
            setStatusMessage("[ Wrote \(buffer.lines.count) lines to \(path) ]")
        } catch {
            setStatusMessage("Error saving file: \(error.localizedDescription)")
        }
    }

    /// 處理 Prompt 模式下的鍵盤輸入
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

        case .none:
            break
        }
    }

    /// 提示搜尋 (Where Is / ^W)
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

    /// 執行文字搜尋
    private func performSearch(query: String) {
        guard !query.isEmpty else { return }
        self.lastSearchQuery = query

        let totalLines = buffer.lines.count
        let startLine = buffer.lineIndex
        let startCol = buffer.columnIndex + 1

        // 1. 從目前游標位置向後搜尋
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

        // 2. Wrap 繞回檔案開頭搜尋
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

    /// 雙重緩衝畫面繪製
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

        // 計算 Viewport Scroll
        let mainAreaHeight = max(1, rows - 4) // 1 top title, 1 status, 2 key help
        if cursorVLineIdx < topVLineIndex {
            topVLineIndex = cursorVLineIdx
        } else if cursorVLineIdx >= topVLineIndex + mainAreaHeight {
            topVLineIndex = cursorVLineIdx - mainAreaHeight + 1
        }

        var output = ""
        output += "\u{1B}[H" // 游標歸位到 (1, 1)

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
                output += vLine.text
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
        case .none:
            if let time = statusMessageTime, Date().timeIntervalSince(time) < 5.0 {
                output += "  \(statusMessage)"
            }
        }
        output += "\r\n"

        // 4. Nano Key Help Bar (2 lines) - 限制在 80 欄以內，不使用白色反白背景 (\u{1B}[7m)
        let helpWidth = min(cols, 80)
        let helpLine1 = " ^G Get Help   ^O WriteOut   ^R Read File  ^Y Prev Pg    ^K Cut Text   ^C Cur Pos"
        let helpLine2 = " ^X Exit       ^J Justify    ^W Where Is   ^V Next Pg    ^U UnCut Text ^T To Spell"
        output += formatHelpLine(helpLine1, width: helpWidth) + "\r\n"
        output += formatHelpLine(helpLine2, width: helpWidth)

        // 5. Position Terminal Cursor (考量全形/中文顯示寬度)
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

    /// 格式化 Nano 幫助列 (標題青色粗體，無反白背景，縮在指定寬度內)
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
