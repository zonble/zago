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
            targetBuffer.replaceContents("", filePath: expandedPath, isModified: false)
            targetBuffer.fileEncoding = .utf8
            targetBuffer.loadErrorDescription = nil
            targetBuffer.isReadOnly = false
            return .succeeded
        }

        do {
            let result = try fileIOStrategy.readTextFile(at: expandedPath)
            targetBuffer.fileEncoding = result.encoding
            targetBuffer.loadErrorDescription = nil
            targetBuffer.replaceContents(result.content, filePath: expandedPath, isModified: false)
            targetBuffer.lineIndex = 0
            targetBuffer.columnIndex = 0
            return .succeeded
        } catch {
            let message = error.localizedDescription
            targetBuffer.replaceContents("", filePath: expandedPath, isModified: false)
            targetBuffer.fileEncoding = .utf8
            targetBuffer.loadErrorDescription = message
            targetBuffer.isReadOnly = true
            if reportStatus {
                setStatusMessage(l10n.errorOpeningFile(error: message))
            }
            return .failed(message)
        }
    }

    @discardableResult
    func reloadBufferFromDisk(_ targetBuffer: TextBuffer, reportStatus: Bool = true) -> EditorOperationResult {
        guard let path = targetBuffer.filePath, !path.isEmpty else {
            let message = l10n["status.path_required"]
            if reportStatus { setStatusMessage(message) }
            return .failed(message)
        }

        do {
            let result = try fileIOStrategy.readTextFile(at: path)
            targetBuffer.fileEncoding = result.encoding
            targetBuffer.loadErrorDescription = nil
            targetBuffer.replaceContents(result.content, filePath: path, isModified: false)
            targetBuffer.clampCursor()
            if reportStatus { setStatusMessage(l10n["status.file_reloaded"]) }
            return .succeeded
        } catch {
            let message = error.localizedDescription
            if reportStatus { setStatusMessage(message) }
            return .failed(message)
        }
    }

    @discardableResult
    func insertFileContent(from path: String) -> EditorOperationResult {
        let expandedPath = fileIOStrategy.normalizePath(path, isDirectory: false)
        do {
            let result = try fileIOStrategy.readTextFile(at: expandedPath)
            saveUndoSnapshot()
            buffer.insertString(result.content)
            setStatusMessage(l10n.insertedLines(result.content.components(separatedBy: .newlines).count))
            return .succeeded
        } catch {
            let message = error.localizedDescription
            setStatusMessage(l10n.errorInsertingFile(error: message))
            return .failed(message)
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
            try fileIOStrategy.writeTextFile(
                buffer.lines.joined(separator: "\n"),
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
            if forcedEncoding == .utf8 && buffer.fileEncoding == .utf8 {
                setStatusMessage(l10n["status.saved_as_utf8"])
            } else {
                setStatusMessage(l10n.wroteToFile("\(path) (\(buffer.lines.count) lines)"))
            }
            onSuccess?()
            return .succeeded
        } catch EncodingError.unsupportedCharacters {
            let originalEncoding = buffer.fileEncoding
            currentPromptMode = .confirmEncodingFallback(originalEncoding: originalEncoding) { [weak self] confirmed in
                guard let self = self else { return }
                if confirmed {
                    _ = self.saveBufferContent(to: path, forcedEncoding: .utf8, onSuccess: onSuccess)
                } else {
                    self.setStatusMessage(self.l10n["status.save_cancelled"])
                }
            }
            return .prompting
        } catch {
            let message = error.localizedDescription
            setStatusMessage(l10n.errorSavingFile(error: message))
            return .failed(message)
        }
    }
}
