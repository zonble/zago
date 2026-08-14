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

    func stopFileWatcherForCurrentBuffer() {
        if let oldPath = currentWatchedPath {
            fileIOStrategy.stopWatchingFile(at: oldPath)
            currentWatchedPath = nil
        }
    }

    /// Handles external file system modifications detected by FileWatcher.
    func handleExternalFileChange() {
        guard displayConfig.autoReload, buffer.filePath != nil else { return }

        if buffer.isModified {
            currentPromptMode = .confirmExternalReload(completion: { [weak self] reload in
                guard let self = self else { return }
                if reload {
                    switch self.reloadBufferFromDisk(self.buffer).kind {
                    case .succeeded:
                        self.setStatusMessage(self.l10n["status.file_reloaded"])
                        self.renderer.invalidateScreenCache()
                    case .failed:
                        break
                    case .cancelled, .prompting, .noOp:
                        break
                    }
                } else {
                    self.setStatusMessage(self.l10n["status.kept_local"])
                }
            })
            setStatusMessage(l10n["prompt.confirm_reload"])
        } else {
            switch reloadBufferFromDisk(buffer).kind {
            case .succeeded:
                setStatusMessage(l10n["status.file_reloaded"])
                renderer.invalidateScreenCache()
            case .failed:
                break
            case .cancelled, .prompting, .noOp:
                break
            }
        }
    }

    // MARK: - Buffer Capabilities

    var isListAutoIndentSupportedBuffer: Bool {
        guard !buffer.isDirectoryBuffer else { return false }
        if let currentSyntax = activeLanguageSyntax {
            return currentSyntax.supportsListAutoIndent
        }
        return false
    }

    // MARK: - View Settings Persistence

    func saveCurrentViewSettingsToBuffer() {
        let current = buffer
        current.viewShowRuler = displayConfig.showRuler
        current.viewShowLineNumbers = displayConfig.showLineNumbers
        current.viewShowSubLineNumbers = displayConfig.showSubLineNumbers
        current.viewWrapColumn = layoutEngine.wrapColumn
    }

    func loadCurrentViewSettingsFromBuffer() {
        let current = buffer
        displayConfig.showRuler = current.viewShowRuler
        displayConfig.showLineNumbers = current.viewShowLineNumbers
        displayConfig.showSubLineNumbers = current.viewShowSubLineNumbers
        layoutEngine.setWrapColumn(current.viewWrapColumn)
    }

    // MARK: - Buffer Navigation

    func switchToBuffer(index: Int) {
        guard bufferCoordinator.isValidIndex(index) else { return }
        saveCurrentViewSettingsToBuffer()
        bufferCoordinator.activeIndex = index
        loadCurrentViewSettingsFromBuffer()
        if let dirBuffer = buffer as? DirectoryBuffer {
            dirBuffer.loadDirectory(at: dirBuffer.directoryPath, language: self.language)
        }
        startFileWatcherForCurrentBuffer()
        renderer.invalidateScreenCache()
    }

    func nextBuffer() {
        guard let index = bufferCoordinator.nextIndex() else { return }
        switchToBuffer(index: index)
    }

    func prevBuffer() {
        guard let index = bufferCoordinator.previousIndex() else { return }
        switchToBuffer(index: index)
    }

    func openNewBuffer(filePath: String? = nil) {
        saveCurrentViewSettingsToBuffer()
        let newBuffer = Self.makeBuffer(
            filePath: filePath,
            fileIO: fileIOStrategy,
            gitService: gitService,
            language: language
        )
        bufferCoordinator.appendAndActivate(newBuffer)
        if !newBuffer.isDirectoryBuffer, let path = newBuffer.filePath {
            _ = loadFileContent(into: newBuffer, path: path)
        }
        loadCurrentViewSettingsFromBuffer()
        startFileWatcherForCurrentBuffer()
    }

    func closeCurrentBuffer() {
        guard buffers.count > 1 else {
            // Closing last remaining buffer: stop watcher and exit editor loop
            stopFileWatcherForCurrentBuffer()
            isRunning = false
            renderer.invalidateScreenCache()
            return
        }

        stopFileWatcherForCurrentBuffer()
        let hasActiveBuffer = bufferCoordinator.removeActive()
        renderer.invalidateScreenCache()

        if !hasActiveBuffer {
            isRunning = false
        } else {
            loadCurrentViewSettingsFromBuffer()
            startFileWatcherForCurrentBuffer()
        }
        renderer.invalidateScreenCache()
    }
}
