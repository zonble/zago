import Foundation
import LogoEngine
import TextMetrics
import TextTransform

extension Editor {
    public typealias PromptMode = PromptController.Mode

    /// Prompts user to input file path for saving (^O / ^S / F3).
    func promptWriteFilePath() {
        promptInputText = buffer.filePath ?? ""
        currentPromptMode = .saveFilePath(completion: { [weak self] path in
            guard let self = self, let path = path, !path.isEmpty else {
                self?.setStatusMessage(self?.l10n["status.cancelled"] ?? "")
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
                    self?.setStatusMessage(self?.l10n["status.cancelled"] ?? "")
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
                self?.setStatusMessage(self?.l10n["status.cancelled_exit"] ?? "")
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
                self?.setStatusMessage(self?.l10n["status.cancelled_search"] ?? "")
                return
            }
            let targetQuery: String
            if !query.isEmpty {
                targetQuery = query
                self.lastSearchQuery = query
            } else if !self.lastSearchQuery.isEmpty {
                targetQuery = self.lastSearchQuery
            } else {
                self.setStatusMessage(self.l10n["status.cancelled_search"])
                return
            }
            self.searchController.performSearch(query: targetQuery)
        })
    }

    /// Prompts user to input file path to insert into buffer (^R / F5).
    func promptInsertFilePath() {
        promptInputText = ""
        currentPromptMode = .insertFilePath(completion: { [weak self] path in
            guard let self = self, let path = path, !path.isEmpty else {
                self?.setStatusMessage(self?.l10n["status.cancelled_insert"] ?? "")
                return
            }
            do {
                self.saveUndoSnapshot()
                let count = try self.buffer.insertFile(at: path, fileIO: self.fileIOStrategy)
                self.setStatusMessage(self.l10n.insertedLines(count))
            } catch {
                self.setStatusMessage(self.l10n.errorInsertingFile(error: error.localizedDescription))
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
                        self?.setStatusMessage(self?.l10n["status.spell_check_skipped"] ?? "")
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
                        self.setStatusMessage(self.l10n.replacedWord(target: target.word, newWord: newWord))
                    } else {
                        self.setStatusMessage(self.l10n["status.word_kept"])
                    }
                })
        } else {
            setStatusMessage(l10n["status.no_misspelled"])
        }
    }

    /// Prompts user for LOGO macro script input (:logo / ^L).
    func promptLogoMacro() {
        promptInputText = ""
        logoHistoryIndex = logoPromptHistory.count
        currentPromptMode = .logoMacro(completion: { [weak self] script in
            guard let self = self, let script = script, !script.isEmpty else {
                self?.setStatusMessage(self?.l10n["status.cancelled"] ?? "")
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
                self?.setStatusMessage(self?.l10n["status.cancelled"] ?? "")
                return
            }
            self.runLogoScript("FILL \(self.logoStringLiteral(text))")
        })
    }

    func promptTableDimensions() {
        guard !buffer.isReadOnly else {
            setStatusMessage("[ Buffer is read-only ]")
            return
        }
        promptInputText = "3 3 16"
        promptCursorIndex = promptInputText.count
        currentPromptMode = .tableDimensions(completion: { [weak self] input in
            guard let self = self, let input = input?.trimmingCharacters(in: .whitespacesAndNewlines), !input.isEmpty
            else {
                self?.setStatusMessage(self?.l10n["status.cancelled"] ?? "")
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
        setStatusMessage(l10n["status.table_created"])
    }

    private func logoStringLiteral(_ text: String) -> String {
        "\"\(text.replacingOccurrences(of: "\"", with: "'"))\""
    }

    /// Prompts user for target line/column number input (^/ / M-g).
    func promptGotoLine() {
        promptInputText = ""
        currentPromptMode = .gotoLine(completion: { [weak self] input in
            guard let self = self, let input = input, !input.isEmpty else {
                self?.setStatusMessage(self?.l10n["status.cancelled"] ?? "")
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
            startFileWatcherForCurrentBuffer()
            if forcedEncoding == .utf8 && buffer.fileEncoding == .utf8 {
                setStatusMessage(l10n["status.saved_as_utf8"])
            } else {
                setStatusMessage(l10n.wroteToFile("\(path) (\(buffer.lines.count) lines)"))
            }
        } catch EncodingError.unsupportedCharacters {
            let originalEncoding = buffer.fileEncoding
            currentPromptMode = .confirmEncodingFallback(originalEncoding: originalEncoding) { [weak self] confirmed in
                guard let self = self else { return }
                if confirmed {
                    self.doSave(to: path, forcedEncoding: .utf8)
                } else {
                    self.setStatusMessage(self.l10n["status.save_cancelled"])
                }
            }
        } catch {
            setStatusMessage(l10n.errorSavingFile(error: error.localizedDescription))
        }
    }
}
