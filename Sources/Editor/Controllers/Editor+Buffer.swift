import Foundation

extension Editor {

    // MARK: - File Watcher

    func startFileWatcherForCurrentBuffer() {
        updateGitDiff()
        if let oldPath = currentWatchedPath {
            fileIOStrategy.stopWatchingFile(at: oldPath)
            currentWatchedPath = nil
        }
        if let path = buffer.filePath {
            currentWatchedPath = path
            fileIOStrategy.startWatchingFile(at: path) { [weak self] in
                guard let self = self, self.displayConfig.autoReload else { return }
                self.handleExternalFileChange()
            }
        }
    }

    public func stopFileWatcherForCurrentBuffer() {
        if let oldPath = currentWatchedPath {
            fileIOStrategy.stopWatchingFile(at: oldPath)
            currentWatchedPath = nil
        }
    }

    /// Handles external file system modifications detected by FileWatcher.
    public func handleExternalFileChange() {
        guard displayConfig.autoReload, buffer.filePath != nil else { return }

        if buffer.isModified {
            currentPromptMode = .confirmExternalReload(completion: { [weak self] reload in
                guard let self = self else { return }
                if reload {
                    do {
                        try self.buffer.reloadFile(fileIO: self.fileIOStrategy)
                        self.buffer.isModified = false
                        self.setStatusMessage(self.l10n["status.file_reloaded"])
                        self.renderer.invalidateScreenCache()
                    } catch {
                        self.setStatusMessage(error.localizedDescription)
                    }
                } else {
                    self.setStatusMessage(self.l10n["status.kept_local"])
                }
            })
            setStatusMessage(l10n["prompt.confirm_reload"])
        } else {
            do {
                try buffer.reloadFile(fileIO: fileIOStrategy)
                setStatusMessage(l10n["status.file_reloaded"])
                renderer.invalidateScreenCache()
            } catch {
                setStatusMessage(error.localizedDescription)
            }
        }
    }

    // MARK: - Buffer Capabilities

    public var isListAutoIndentSupportedBuffer: Bool {
        guard !buffer.isDirectoryBuffer else { return false }
        if let currentSyntax = activeLanguageSyntax {
            return currentSyntax.supportsListAutoIndent
        }
        return false
    }

    // MARK: - View Settings Persistence

    func saveCurrentViewSettingsToBuffer() {
        guard !buffers.isEmpty, currentBufferIndex >= 0, currentBufferIndex < buffers.count else { return }
        let current = buffers[currentBufferIndex]
        current.viewShowRuler = displayConfig.showRuler
        current.viewShowLineNumbers = displayConfig.showLineNumbers
        current.viewShowSubLineNumbers = displayConfig.showSubLineNumbers
        current.viewWrapColumn = layoutEngine.wrapColumn
    }

    func loadCurrentViewSettingsFromBuffer() {
        guard !buffers.isEmpty, currentBufferIndex >= 0, currentBufferIndex < buffers.count else { return }
        let current = buffers[currentBufferIndex]
        displayConfig.showRuler = current.viewShowRuler
        displayConfig.showLineNumbers = current.viewShowLineNumbers
        displayConfig.showSubLineNumbers = current.viewShowSubLineNumbers
        layoutEngine.setWrapColumn(current.viewWrapColumn)
    }

    // MARK: - Buffer Navigation

    func switchToBuffer(index: Int) {
        guard index >= 0, index < buffers.count else { return }
        saveCurrentViewSettingsToBuffer()
        currentBufferIndex = index
        loadCurrentViewSettingsFromBuffer()
        if let dirBuffer = buffers[currentBufferIndex] as? DirectoryBuffer {
            dirBuffer.loadDirectory(at: dirBuffer.directoryPath, language: self.language)
        }
        topVLineIndex = 0
        startFileWatcherForCurrentBuffer()
        renderer.invalidateScreenCache()
    }

    /// Switches to next open buffer in sequence.
    public func nextBuffer() {
        guard buffers.count > 1 else { return }
        switchToBuffer(index: (currentBufferIndex + 1) % buffers.count)
    }

    /// Switches to previous open buffer in sequence.
    public func prevBuffer() {
        guard buffers.count > 1 else { return }
        switchToBuffer(index: (currentBufferIndex - 1 + buffers.count) % buffers.count)
    }

    // MARK: - Buffer Lifecycle

    /// Opens a new buffer for given file path or empty buffer.
    public func openNewBuffer(filePath: String? = nil) {
        if let path = filePath, !path.isEmpty {
            let normalized = fileIOStrategy.normalizePath(path, isDirectory: false)
            let info = fileIOStrategy.fileInfo(at: normalized)
            if info.exists && !info.isDirectory && info.isBinary {
                let name = (path as NSString).lastPathComponent
                setStatusMessage("Cannot open binary file '\(name)'")
                return
            }
        }
        saveCurrentViewSettingsToBuffer()
        let newBuf = TextBuffer.makeBuffer(filePath: filePath, fileIO: fileIOStrategy, language: self.language)
        newBuf.baseMode = newBuf.isDirectoryBuffer ? .text : defaultBaseMode
        newBuf.viewShowRuler = defaultViewShowRuler
        newBuf.viewShowLineNumbers = defaultViewShowLineNumbers
        newBuf.viewShowSubLineNumbers = defaultViewShowSubLineNumbers
        newBuf.viewWrapColumn = defaultViewWrapColumn
        buffers.append(newBuf)
        currentBufferIndex = buffers.count - 1
        loadCurrentViewSettingsFromBuffer()
        topVLineIndex = 0
        clearActiveMark()
        startFileWatcherForCurrentBuffer()
        renderer.invalidateScreenCache()
    }

    /// Closes current active buffer. If no buffers remain, exits editor.
    public func closeCurrentBuffer() {
        guard !buffers.isEmpty else {
            isRunning = false
            return
        }

        saveCurrentViewSettingsToBuffer()
        buffers.remove(at: currentBufferIndex)
        if buffers.isEmpty {
            isRunning = false
        } else {
            currentBufferIndex = max(0, min(currentBufferIndex, buffers.count - 1))
            loadCurrentViewSettingsFromBuffer()
            topVLineIndex = 0
            clearActiveMark()
            startFileWatcherForCurrentBuffer()
            renderer.invalidateScreenCache()
        }
    }
}
