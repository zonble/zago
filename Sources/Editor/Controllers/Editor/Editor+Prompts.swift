import Foundation
import LogoEngine
import TextMetrics
import TextTransform

extension Editor {
    typealias PromptMode = PromptController.Mode

    /// Prompts user to input file path for saving (^O / ^S / F3).
    func promptWriteFilePath() {
        promptInputText = buffer.filePath ?? ""
        currentPromptMode = .saveFilePath(completion: { [weak self] path in
            guard let self = self, let path = path, !path.isEmpty else {
                self?.reportOperationResult(.cancelled(message: self?.l10n["status.cancelled"] ?? ""))
                return
            }
            self.applyOperationResult(self.doSave(to: path))
        })
    }

    /// Saves current buffer to disk and closes current buffer / exits editor (F4).
    func promptSaveAndExit() {
        if let path = buffer.filePath, !path.isEmpty {
            applyOperationResult(completeSaveAndClose(path: path))
        } else {
            promptInputText = ""
            currentPromptMode = .saveFilePath(completion: { [weak self] path in
                guard let self = self, let path = path, !path.isEmpty else {
                    self?.reportOperationResult(.cancelled(message: self?.l10n["status.cancelled"] ?? ""))
                    return
                }
                self.applyOperationResult(self.completeSaveAndClose(path: path))
            })
        }
    }

    /// Prompts user to save modified buffer before exiting (^X / F2).
    func promptExitSaveConfirm() {
        currentPromptMode = .confirmExitSave(completion: { [weak self] save in
            guard let self = self, let save = save else {
                self?.reportOperationResult(.cancelled(message: self?.l10n["status.cancelled_exit"] ?? ""))
                return
            }
            self.applyOperationResult(self.completeExitSaveDecision(shouldSave: save))
        })
    }

    /// Prompts user for search string (^W / F6).
    func promptSearch() {
        promptInputText = ""
        currentPromptMode = .search(completion: { [weak self] query in
            guard let self = self, let query = query else {
                self?.reportOperationResult(.cancelled(message: self?.l10n["status.cancelled_search"] ?? ""))
                return
            }
            let targetQuery: String
            if !query.isEmpty {
                targetQuery = query
                self.lastSearchQuery = query
            } else if !self.lastSearchQuery.isEmpty {
                targetQuery = self.lastSearchQuery
            } else {
                self.reportOperationResult(.cancelled(message: self.l10n["status.cancelled_search"]))
                return
            }
            self.searchController.performSearch(query: targetQuery)
        })
    }

    /// Prompts user for interactive search and replace (^\ / ^H / :replace).
    func promptSearchAndReplace() {
        if buffer.isReadOnly {
            reportOperationResult(.noOp(message: l10n["status.read_only"]))
            return
        }
        promptInputText = lastSearchQuery
        currentPromptMode = .replaceSearch(completion: { [weak self] query in
            guard let self = self, let query = query, !query.isEmpty else {
                self?.reportOperationResult(.cancelled(message: self?.l10n["status.cancelled_search"] ?? ""))
                return
            }
            self.lastSearchQuery = query
            self.promptInputText = ""
            self.currentPromptMode = .replaceWith(
                searchQuery: query,
                completion: { [weak self] replacement in
                    guard let self = self, let replacement = replacement else {
                        self?.reportOperationResult(.cancelled(message: self?.l10n["status.cancelled_search"] ?? ""))
                        return
                    }
                    self.searchController.startInteractiveReplace(query: query, replacement: replacement)
                })
        })
    }

    /// Prompts user to input file path to open in a new buffer.
    func promptOpenFilePath() {
        promptInputText = ""
        currentPromptMode = .openFilePath(completion: { [weak self] path in
            guard let self = self, let path = path, !path.isEmpty else {
                self?.reportOperationResult(.cancelled(message: self?.l10n["status.cancelled_open"] ?? ""))
                return
            }
            self.applyOperationResult(self.openBuffer(path: path))
        })
    }

    /// Prompts user to input file path to insert into buffer (^R / F5).
    func promptInsertFilePath() {
        if buffer.isReadOnly {
            reportOperationResult(.noOp(message: l10n["status.read_only"]))
            return
        }
        promptInputText = ""
        currentPromptMode = .insertFilePath(completion: { [weak self] path in
            guard let self = self, let path = path, !path.isEmpty else {
                self?.reportOperationResult(.cancelled(message: self?.l10n["status.cancelled_insert"] ?? ""))
                return
            }
            self.applyOperationResult(self.insertFileContent(from: path))
        })
    }

    /// Prompts user to check and replace misspelled words (^T / F12).
    func promptSpellCheck() {
        let syntaxName = activeLanguageSyntax?.name
        let target =
            if isTableModeActive {
                spellChecker.findNextMisspelled(
                    lines: tableScopedSpellCheckLines(),
                    filePath: buffer.filePath,
                    startingAt: buffer.lineIndex,
                    startingCol: buffer.columnIndex,
                    syntaxName: syntaxName)
            } else {
                spellChecker.findNextMisspelled(
                    in: buffer,
                    startingAt: buffer.lineIndex,
                    startingCol: buffer.columnIndex,
                    syntaxName: syntaxName)
            }
        if let target {
            buffer.lineIndex = target.line
            buffer.columnIndex = target.col
            promptInputText = target.word
            currentPromptMode = .spellCheck(
                word: target.word, line: target.line, col: target.col,
                completion: { [weak self] replacement in
                    guard let self = self, let newWord = replacement, !newWord.isEmpty else {
                        self?.reportOperationResult(
                            .cancelled(message: self?.l10n["status.spell_check_skipped"] ?? ""))
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
                        self.reportOperationResult(
                            .succeeded(message: self.l10n.replacedWord(target: target.word, newWord: newWord)))
                    } else {
                        self.reportOperationResult(.succeeded(message: self.l10n["status.word_kept"]))
                    }
                })
        } else {
            reportOperationResult(.noOp(message: l10n["status.no_misspelled"]))
        }
    }

    private func tableScopedSpellCheckLines() -> [String] {
        var lines = buffer.lines
        guard isTableModeActive else { return lines }
        for lineIndex in lines.indices {
            guard let bounds = tableModeController.currentCellInnerBounds(on: lineIndex) else {
                lines[lineIndex] = ""
                continue
            }
            let chars = Array(lines[lineIndex])
            let scopedChars = chars.enumerated().map { index, ch in
                index >= bounds.start && index < bounds.end ? ch : " "
            }
            lines[lineIndex] = String(scopedChars)
        }
        return lines
    }

    /// Prompts user for LOGO macro script input (:logo / ^L).
    func promptLogoMacro() {
        promptInputText = ""
        logoHistoryIndex = logoPromptHistory.count
        currentPromptMode = .logoMacro(completion: { [weak self] script in
            guard let self = self, let script = script, !script.isEmpty else {
                self?.reportOperationResult(.cancelled(message: self?.l10n["status.cancelled"] ?? ""))
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
        menuBarController.isActive = false
        promptInputText = ""
        currentPromptMode = .fillText(completion: { [weak self] text in
            guard let self = self, let text = text, !text.isEmpty else {
                self?.reportOperationResult(.cancelled(message: self?.l10n["status.cancelled"] ?? ""))
                return
            }
            self.runLogoScript("FILL \(self.logoStringLiteral(text))")
        })
    }

    func promptTableDimensions() {
        menuBarController.isActive = false
        guard !buffer.isReadOnly else {
            reportOperationResult(.noOp(message: l10n["status.buffer_readonly_bracketed"]))
            return
        }
        promptInputText = "3 3 16"
        promptCursorIndex = promptInputText.count
        currentPromptMode = .tableDimensions(completion: { [weak self] input in
            guard let self = self, let input = input?.trimmingCharacters(in: .whitespacesAndNewlines), !input.isEmpty
            else {
                self?.reportOperationResult(.cancelled(message: self?.l10n["status.cancelled"] ?? ""))
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
            self.tableModeController.createTable(
                rows: rows, cols: cols, cellWidth: width, enterMode: true, saveSnapshot: true)
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
        reportOperationResult(.succeeded(message: l10n["status.table_created"]))
    }

    private func logoStringLiteral(_ text: String) -> String {
        "\"\(text.replacingOccurrences(of: "\"", with: "'"))\""
    }

    /// Prompts user for target line/column number input (^/ / M-g).
    func promptGotoLine() {
        promptInputText = ""
        currentPromptMode = .gotoLine(completion: { [weak self] input in
            guard let self = self, let input = input, !input.isEmpty else {
                self?.reportOperationResult(.cancelled(message: self?.l10n["status.cancelled"] ?? ""))
                return
            }
            self.performGotoLine(input)
        })
    }

    /// Prompts user to press any key to describe its function (:help-key / Help -> Describe Key).
    func promptDescribeKey() {
        promptInputText = ""
        currentPromptMode = .describeKey(completion: { [weak self] key in
            guard let self else { return }
            let desc = self.describeKey(key)
            self.reportOperationResult(.succeeded(message: desc))
        })
    }

    /// Resolves a Key across base, canvas, and table modes and returns a formatted description.
    func describeKey(_ key: Key) -> String {
        let keyLabel = key.helpBarLabel

        func commandDescription(for cmdId: CommandID) -> String {
            if cmdId == .customMacro, let customCmd = commandRegistry.customCommand(for: key) {
                if language == .zh_TW {
                    let script = customCmd.description.replacingOccurrences(of: "Execute LOGO script ", with: "")
                    return "執行自訂 LOGO 腳本 \(script)"
                }
                return customCmd.description
            }
            let key = "command.\(cmdId.rawValue).description"
            let localized = l10n[key]
            if localized != key && !localized.isEmpty {
                return localized
            }
            if let cmd = commandRegistry.commands.first(where: { $0.id == cmdId }) {
                return cmd.description
            }
            return cmdId.rawValue
        }

        let textCmd = keymapManager.resolve(key: key, in: .text)
        let canvasCmd = keymapManager.resolve(key: key, in: .canvas)
        let tableCmd = keymapManager.resolve(key: key, in: .table)

        if textCmd == nil && canvasCmd == nil && tableCmd == nil {
            if case .char(let ch) = key {
                return String(format: l10n["status.describe_char"], String(ch), String(ch))
            }
            return String(format: l10n["status.describe_unbound"], keyLabel)
        }

        var parts: [String] = []
        if let textCmd {
            let desc = commandDescription(for: textCmd)
            parts.append("\(desc) (\(textCmd.rawValue))")
        }

        let modeSep = (language == .zh_TW) ? "：" : ": "

        if let canvasCmd, canvasCmd != textCmd {
            let desc = commandDescription(for: canvasCmd)
            let modeTitle = l10n["mode.canvas_mode"]
            parts.append("\(modeTitle)\(modeSep)\(desc) (\(canvasCmd.rawValue))")
        }

        if let tableCmd, tableCmd != textCmd {
            let desc = commandDescription(for: tableCmd)
            let modeTitle = l10n["mode.table_mode"]
            parts.append("\(modeTitle)\(modeSep)\(desc) (\(tableCmd.rawValue))")
        }

        let sep = (language == .zh_TW) ? "：" : ": "
        return "\(keyLabel)\(sep)\(parts.joined(separator: " | "))"
    }

    func performGotoLine(_ input: String) {
        let parts = input.components(separatedBy: CharacterSet(charactersIn: ", "))
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        if parts.isEmpty { return }

        goToLocation(line: parts[0], column: parts.count > 1 ? parts[1] : nil)
    }

    /// Saves buffer to specified file path.
    @discardableResult
    func doSave(
        to path: String,
        forcedEncoding: String.Encoding? = nil,
        onSuccess: (() -> Void)? = nil
    ) -> EditorOperationResult {
        saveBufferContent(to: path, forcedEncoding: forcedEncoding, onSuccess: onSuccess)
    }

    /// Prompts user for export target path for TMD format.
    func promptTMDExport(format: TMDExportFormat) {
        let currentPath = buffer.filePath ?? ""
        let defaultPath: String
        if !currentPath.isEmpty {
            let ns = currentPath as NSString
            let basePath = ns.deletingPathExtension
            defaultPath = "\(basePath).\(format.fileExtension)"
        } else {
            defaultPath = "score.\(format.fileExtension)"
        }

        promptInputText = defaultPath
        currentPromptMode = .tmdExport(format: format, completion: { [weak self] targetPath in
            guard let self else { return }
            guard let targetPath, !targetPath.isEmpty else {
                self.reportOperationResult(.cancelled(message: self.l10n["status.cancelled"]))
                return
            }
            self.executeTMDExport(format: format, toPath: targetPath)
        })
    }

    /// Dispatches TMD export via delegate and reports outcome.
    func executeTMDExport(format: TMDExportFormat, toPath targetPath: String) {
        let sourceText = buffer.lines.joined(separator: "\n")
        do {
            try tmdExportDelegate.exportTMD(sourceText: sourceText, format: format, toPath: targetPath)
            reportOperationResult(.succeeded(message: String(format: l10n["status.tmd_exported"], format.displayName, targetPath)))
        } catch {
            reportOperationResult(.failed(error.localizedDescription, message: String(format: l10n["status.tmd_export_failed"], format.displayName, error.localizedDescription)))
        }
    }
}
