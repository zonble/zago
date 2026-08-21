import Foundation
import Git
import TextEncoding

extension Editor {
    static func makeBuffer(
        filePath: String?,
        fileIO: EditorFileIOStrategy,
        gitService: GitServiceProtocol = GitService(),
        language: Language = .detectSystemLanguage()
    ) -> TextBuffer {
        guard let path = filePath, !path.isEmpty else { return TextBuffer() }
        let expandedPath = fileIO.normalizePath(path, isDirectory: false)
        let info = fileIO.fileInfo(at: expandedPath)
        if info.exists, info.isDirectory {
            return DirectoryBuffer(
                directoryPath: expandedPath,
                fileIO: fileIO,
                gitService: gitService,
                language: language
            )
        }
        return TextBuffer(filePath: expandedPath)
    }

    @discardableResult
    func loadFileContent(into targetBuffer: TextBuffer, path: String, reportStatus: Bool = true)
        -> EditorOperationResult
    {
        let expandedPath = fileIOStrategy.normalizePath(path, isDirectory: false)
        let info = fileIOStrategy.fileInfo(at: expandedPath)
        guard info.exists else {
            targetBuffer.replaceContents(
                "", filePath: expandedPath, isModified: false, defaultLineEnding: defaultLineEnding)
            targetBuffer.fileEncoding = .utf8
            targetBuffer.loadErrorDescription = nil
            targetBuffer.isReadOnly = false
            targetBuffer.isLargeFileMode = false
            targetBuffer.fileSize = 0
            return .succeeded
        }

        if maxFileSizeBytes > 0 && info.size > maxFileSizeBytes {
            let error = EditorFileError.fileTooLarge(size: info.size, limit: maxFileSizeBytes)
            let message = error.localizedDescription
            targetBuffer.replaceContents(
                "[\(message)]", filePath: expandedPath, isModified: false, defaultLineEnding: defaultLineEnding)
            targetBuffer.fileEncoding = .utf8
            targetBuffer.loadErrorDescription = message
            targetBuffer.isReadOnly = true
            targetBuffer.isLargeFileMode = false
            targetBuffer.fileSize = info.size
            return reportOperationResult(
                .failed(message, message: reportStatus ? l10n.errorOpeningFile(error: message) : nil))
        }

        do {
            let result = try fileIOStrategy.readTextFile(at: expandedPath)
            targetBuffer.fileEncoding = result.encoding
            targetBuffer.loadErrorDescription = nil
            targetBuffer.replaceContents(
                result.content, filePath: expandedPath, isModified: false, defaultLineEnding: defaultLineEnding)
            targetBuffer.lineIndex = 0
            targetBuffer.columnIndex = 0
            targetBuffer.fileSize = info.size

            if largeFileThresholdBytes > 0 && info.size >= largeFileThresholdBytes {
                targetBuffer.isLargeFileMode = true
                let sizeFormatted = ByteCountFormatter.string(fromByteCount: info.size, countStyle: .file)
                let statusMessage = String(format: l10n["status.large_file_mode"], sizeFormatted)
                return reportOperationResult(.succeeded(message: reportStatus ? statusMessage : nil))
            } else {
                targetBuffer.isLargeFileMode = false
                return .succeeded
            }
        } catch {
            let message = error.localizedDescription
            targetBuffer.replaceContents(
                "", filePath: expandedPath, isModified: false, defaultLineEnding: defaultLineEnding)
            targetBuffer.fileEncoding = .utf8
            targetBuffer.loadErrorDescription = message
            targetBuffer.isReadOnly = true
            targetBuffer.isLargeFileMode = false
            targetBuffer.fileSize = info.size
            return reportOperationResult(
                .failed(message, message: reportStatus ? l10n.errorOpeningFile(error: message) : nil))
        }
    }

    @discardableResult
    func reloadBufferFromDisk(_ targetBuffer: TextBuffer, reportStatus: Bool = true) -> EditorOperationResult {
        guard let path = targetBuffer.filePath, !path.isEmpty else {
            let message = l10n["status.path_required"]
            return reportOperationResult(.failed(message, message: reportStatus ? message : nil))
        }

        let info = fileIOStrategy.fileInfo(at: path)
        if maxFileSizeBytes > 0 && info.size > maxFileSizeBytes {
            let error = EditorFileError.fileTooLarge(size: info.size, limit: maxFileSizeBytes)
            let message = error.localizedDescription
            return reportOperationResult(.failed(message, message: reportStatus ? message : nil))
        }

        do {
            let result = try fileIOStrategy.readTextFile(at: path)
            targetBuffer.fileEncoding = result.encoding
            targetBuffer.loadErrorDescription = nil
            targetBuffer.replaceContents(
                result.content, filePath: path, isModified: false, defaultLineEnding: defaultLineEnding)
            targetBuffer.fileSize = info.size
            targetBuffer.isLargeFileMode = (largeFileThresholdBytes > 0 && info.size >= largeFileThresholdBytes)
            targetBuffer.clampCursor()
            return reportOperationResult(.succeeded(message: reportStatus ? l10n["status.file_reloaded"] : nil))
        } catch {
            let message = error.localizedDescription
            return reportOperationResult(.failed(message, message: reportStatus ? message : nil))
        }
    }

    @discardableResult
    func insertFileContent(from path: String) -> EditorOperationResult {
        if buffer.isReadOnly {
            return reportOperationResult(.noOp(message: l10n["status.read_only"]))
        }
        let expandedPath = fileIOStrategy.normalizePath(path, isDirectory: false)
        let info = fileIOStrategy.fileInfo(at: expandedPath)
        if maxFileSizeBytes > 0 && info.size > maxFileSizeBytes {
            let error = EditorFileError.fileTooLarge(size: info.size, limit: maxFileSizeBytes)
            let message = error.localizedDescription
            return reportOperationResult(.failed(message, message: l10n.errorInsertingFile(error: message)))
        }

        do {
            let result = try fileIOStrategy.readTextFile(at: expandedPath)
            saveUndoSnapshot()
            buffer.insertString(result.content)
            return reportOperationResult(
                .succeeded(message: l10n.insertedLines(result.content.components(separatedBy: .newlines).count)))
        } catch {
            let message = error.localizedDescription
            return reportOperationResult(.failed(message, message: l10n.errorInsertingFile(error: message)))
        }
    }

    func suggestedSafeSavePath(for originalPath: String?) -> String {
        let baseFilename: String
        if let originalPath, !originalPath.isEmpty {
            let normalized = fileIOStrategy.normalizePath(originalPath, isDirectory: false)
            let lastComponent = URL(fileURLWithPath: normalized).lastPathComponent
            baseFilename = lastComponent.isEmpty ? "untitled.txt" : lastComponent
        } else {
            baseFilename = "untitled.txt"
        }

        let homeDir = fileIOStrategy.homeDirectoryPath()
        if fileIOStrategy.isDirectoryWritable(at: homeDir) {
            return fileIOStrategy.childPath(baseFilename, in: homeDir)
        }

        let tempDir = fileIOStrategy.temporaryDirectoryPath()
        if fileIOStrategy.isDirectoryWritable(at: tempDir) {
            return fileIOStrategy.childPath(baseFilename, in: tempDir)
        }

        return fileIOStrategy.childPath(baseFilename, in: fileIOStrategy.currentDirectoryPath())
    }

    @discardableResult
    func saveBufferContent(
        to path: String,
        forcedEncoding: String.Encoding? = nil,
        onSuccess: (() -> Void)? = nil
    ) -> EditorOperationResult {
        if displayConfig.trimTrailingWhitespaceOnSave && !buffer.isDirectoryBuffer {
            _ = buffer.trimTrailingWhitespace()
        }

        let expandedPath = fileIOStrategy.normalizePath(path, isDirectory: false)
        let targetEncoding = forcedEncoding ?? buffer.fileEncoding

        if backup && fileIOStrategy.fileInfo(at: expandedPath).exists {
            let backupPath: String
            if let customDir = backupDir, !customDir.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let expandedDir = fileIOStrategy.normalizePath(customDir, isDirectory: true)
                let filename = URL(fileURLWithPath: expandedPath).lastPathComponent
                backupPath = fileIOStrategy.childPath(filename + "~", in: expandedDir)
            } else {
                backupPath = expandedPath + "~"
            }

            do {
                try fileIOStrategy.copyFile(at: expandedPath, to: backupPath)
            } catch {
                let message = error.localizedDescription
                currentPromptMode = .confirmBackupFailure(error: message) { [weak self] continueAnyway in
                    guard let self = self else { return }
                    if continueAnyway {
                        self.applyOperationResult(
                            self.performSaveBufferWrite(
                                to: expandedPath,
                                originalPath: path,
                                targetEncoding: targetEncoding,
                                forcedEncoding: forcedEncoding,
                                onSuccess: onSuccess
                            )
                        )
                    } else {
                        self.reportOperationResult(.cancelled(message: self.l10n["status.save_cancelled"]))
                    }
                }
                return .prompting
            }
        }

        return performSaveBufferWrite(
            to: expandedPath,
            originalPath: path,
            targetEncoding: targetEncoding,
            forcedEncoding: forcedEncoding,
            onSuccess: onSuccess
        )
    }

    private func performSaveBufferWrite(
        to expandedPath: String,
        originalPath: String,
        targetEncoding: String.Encoding,
        forcedEncoding: String.Encoding?,
        onSuccess: (() -> Void)?
    ) -> EditorOperationResult {
        do {
            let separator = buffer.lineEnding.separator
            var fileContent = buffer.lines.joined(separator: separator)
            if buffer.hasTrailingNewline && !fileContent.isEmpty && !fileContent.hasSuffix(separator) {
                fileContent += separator
            }
            try fileIOStrategy.writeTextFile(
                fileContent,
                to: expandedPath,
                encoding: targetEncoding
            )

            buffer.filePath = expandedPath
            buffer.fileEncoding = targetEncoding
            buffer.isModified = false
            buffer.isReadOnly = false
            buffer.loadErrorDescription = nil

            for b in buffers {
                if let dirBuf = b as? DirectoryBuffer {
                    dirBuf.loadDirectory(at: dirBuf.directoryPath)
                }
            }
            startFileWatcherForCurrentBuffer()
            let message: String
            if forcedEncoding == .utf8 && buffer.fileEncoding == .utf8 {
                message = l10n["status.saved_as_utf8"]
            } else {
                message = l10n.wroteToFile("\(originalPath) (\(buffer.lines.count) lines)")
            }
            onSuccess?()
            return reportOperationResult(.succeeded(message: message))
        } catch EncodingError.unsupportedCharacters {
            let originalEncoding = buffer.fileEncoding
            currentPromptMode = .confirmEncodingFallback(originalEncoding: originalEncoding) { [weak self] confirmed in
                guard let self = self else { return }
                if confirmed {
                    self.applyOperationResult(
                        self.saveBufferContent(to: originalPath, forcedEncoding: .utf8, onSuccess: onSuccess))
                } else {
                    self.reportOperationResult(.cancelled(message: self.l10n["status.save_cancelled"]))
                }
            }
            return .prompting
        } catch {
            let message = error.localizedDescription
            let fallbackPath = suggestedSafeSavePath(for: expandedPath)
            promptInputText = fallbackPath
            promptCursorIndex = fallbackPath.count
            currentPromptMode = .saveFilePath { [weak self] newPath in
                guard let self = self, let newPath = newPath, !newPath.isEmpty else {
                    self?.reportOperationResult(.cancelled(message: self?.l10n["status.save_cancelled"] ?? ""))
                    return
                }
                self.applyOperationResult(
                    self.saveBufferContent(to: newPath, forcedEncoding: forcedEncoding, onSuccess: onSuccess)
                )
            }
            statusMessage = l10n.errorSavingFile(error: message)
            statusMessageTime = Date()
            return reportOperationResult(.failed(message, message: l10n.errorSavingFile(error: message)))
        }
    }

    @discardableResult
    func completeSaveAndClose(path: String) -> EditorOperationResult {
        saveBufferContent(to: path) { [weak self] in
            self?.closeCurrentBuffer()
        }
    }

    @discardableResult
    func completeExitSaveDecision(shouldSave: Bool) -> EditorOperationResult {
        guard shouldSave else {
            closeCurrentBufferOrExitEditor()
            return .succeeded
        }

        guard let path = buffer.filePath, !path.isEmpty else {
            promptSaveAndExit()
            return .prompting
        }

        return saveBufferContent(to: path) { [weak self] in
            self?.closeCurrentBufferOrExitEditor()
        }
    }

    private func closeCurrentBufferOrExitEditor() {
        if buffers.count == 1 {
            isRunning = false
        } else {
            closeCurrentBuffer()
        }
    }
}
