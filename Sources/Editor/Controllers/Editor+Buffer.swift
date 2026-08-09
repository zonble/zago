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
        startFileWatcherForCurrentBuffer()
    }

    public func nextBuffer() {
        guard buffers.count > 1 else { return }
        let nextIndex = (currentBufferIndex + 1) % buffers.count
        switchToBuffer(index: nextIndex)
    }

    public func prevBuffer() {
        guard buffers.count > 1 else { return }
        let prevIndex = (currentBufferIndex - 1 + buffers.count) % buffers.count
        switchToBuffer(index: prevIndex)
    }

    public func openNewBuffer(filePath: String? = nil) {
        saveCurrentViewSettingsToBuffer()
        let newBuffer = TextBuffer.makeBuffer(
            filePath: filePath,
            fileIO: fileIOStrategy,
            gitService: gitService,
            language: language
        )
        buffers.append(newBuffer)
        currentBufferIndex = buffers.count - 1
        loadCurrentViewSettingsFromBuffer()
        startFileWatcherForCurrentBuffer()
    }

    public func closeCurrentBuffer() {
        guard buffers.count > 1 else {
            // Last buffer: replace with empty untitled scratch buffer
            stopFileWatcherForCurrentBuffer()
            buffers[0] = TextBuffer()
            currentBufferIndex = 0
            return
        }

        stopFileWatcherForCurrentBuffer()
        buffers.remove(at: currentBufferIndex)
        if currentBufferIndex >= buffers.count {
            currentBufferIndex = max(0, buffers.count - 1)
        }
        loadCurrentViewSettingsFromBuffer()
        startFileWatcherForCurrentBuffer()
    }
}
