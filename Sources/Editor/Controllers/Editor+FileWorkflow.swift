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
    func loadFileContent(into targetBuffer: TextBuffer, path: String, reportStatus: Bool = true) -> EditorOperationResult {
        let expandedPath = fileIOStrategy.normalizePath(path, isDirectory: false)
        guard fileIOStrategy.fileInfo(at: expandedPath).exists else {
            targetBuffer.replaceContents("", filePath: expandedPath, isModified: false, defaultLineEnding: defaultLineEnding)
            targetBuffer.fileEncoding = .utf8
            targetBuffer.loadErrorDescription = nil
            targetBuffer.isReadOnly = false
            return .succeeded
        }

        do {
            let result = try fileIOStrategy.readTextFile(at: expandedPath)
            targetBuffer.fileEncoding = result.encoding
            targetBuffer.loadErrorDescription = nil
            targetBuffer.replaceContents(result.content, filePath: expandedPath, isModified: false, defaultLineEnding: defaultLineEnding)
            targetBuffer.lineIndex = 0
            targetBuffer.columnIndex = 0
            return .succeeded
        } catch {
            let message = error.localizedDescription
            targetBuffer.replaceContents("", filePath: expandedPath, isModified: false, defaultLineEnding: defaultLineEnding)
            targetBuffer.fileEncoding = .utf8
            targetBuffer.loadErrorDescription = message
            targetBuffer.isReadOnly = true
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

        do {
            let result = try fileIOStrategy.readTextFile(at: path)
            targetBuffer.fileEncoding = result.encoding
            targetBuffer.loadErrorDescription = nil
            targetBuffer.replaceContents(result.content, filePath: path, isModified: false, defaultLineEnding: defaultLineEnding)
            targetBuffer.clampCursor()
            return reportOperationResult(.succeeded(message: reportStatus ? l10n["status.file_reloaded"] : nil))
        } catch {
            let message = error.localizedDescription
            return reportOperationResult(.failed(message, message: reportStatus ? message : nil))
        }
    }

    @discardableResult
    func insertFileContent(from path: String) -> EditorOperationResult {
        let expandedPath = fileIOStrategy.normalizePath(path, isDirectory: false)
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

    @discardableResult
    func saveBufferContent(
        to path: String,
        forcedEncoding: String.Encoding? = nil,
        onSuccess: (() -> Void)? = nil
    ) -> EditorOperationResult {
        do {
            if displayConfig.trimTrailingWhitespaceOnSave && !buffer.isDirectoryBuffer {
                _ = buffer.trimTrailingWhitespace()
            }

            let expandedPath = fileIOStrategy.normalizePath(path, isDirectory: false)
            let targetEncoding = forcedEncoding ?? buffer.fileEncoding
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
                message = l10n.wroteToFile("\(path) (\(buffer.lines.count) lines)")
            }
            onSuccess?()
            return reportOperationResult(.succeeded(message: message))
        } catch EncodingError.unsupportedCharacters {
            let originalEncoding = buffer.fileEncoding
            currentPromptMode = .confirmEncodingFallback(originalEncoding: originalEncoding) { [weak self] confirmed in
                guard let self = self else { return }
                if confirmed {
                    self.applyOperationResult(
                        self.saveBufferContent(to: path, forcedEncoding: .utf8, onSuccess: onSuccess))
                } else {
                    self.reportOperationResult(.cancelled(message: self.l10n["status.save_cancelled"]))
                }
            }
            return .prompting
        } catch {
            let message = error.localizedDescription
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
