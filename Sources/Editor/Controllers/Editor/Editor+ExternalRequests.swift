import Foundation

extension Editor {
    public func externalGetBuffers() -> [EditorExternalBufferInfo] {
        externalRequestService.getBuffers(
            buffers: buffers,
            activeIndex: currentBufferIndex,
            untitledName: l10n["buffer.untitled"]
        )
    }

    public func externalGetText(
        bufferTarget: String?,
        startLine: Int?,
        endLine: Int?
    ) -> EditorExternalTextResult? {
        let targetBuf = resolveExternalBufferTarget(bufferTarget) ?? buffer
        return externalRequestService.getText(from: targetBuf, startLine: startLine, endLine: endLine)
    }

    public func externalGetSelection(bufferTarget: String?) -> EditorExternalSelectionResult? {
        let targetBuf = resolveExternalBufferTarget(bufferTarget) ?? buffer
        return externalRequestService.getSelection(from: targetBuf)
    }

    public func externalGetCursor(bufferTarget: String?) -> EditorExternalCursorInfo? {
        let targetBuf = resolveExternalBufferTarget(bufferTarget) ?? buffer
        return externalRequestService.getCursor(
            from: targetBuf,
            isCanvasModeActive: isCanvasModeActive,
            isTableModeActive: isTableModeActive,
            canvasVisualColumn: canvasVisualColumn
        )
    }

    public func externalShowPreview(_ proposal: AIProposal, viewportRows: Int, viewportCols: Int) -> Bool {
        guard !buffer.isReadOnly && !buffer.isDirectoryBuffer else { return false }
        guard proposalQueue.pushProposal(proposal) else { return false }

        let geometry = ScreenGeometry(rows: viewportRows, cols: viewportCols, editor: self)
        let mainAreaHeight = geometry.mainAreaHeight
        let textWidth = geometry.textWidth

        let baseVLines =
            isCanvasModeActive
            ? layoutEngine.computeCanvasLines(from: buffer.lines)
            : layoutEngine.computeVirtualLines(from: buffer.lines, viewWidth: textWidth)
        let expandedVLines = renderer.expandVirtualLinesWithProposal(
            virtualLines: baseVLines,
            editor: self,
            textWidth: textWidth
        )

        if let firstBoxIdx = expandedVLines.firstIndex(where: { $0.isProposalOverlay }),
            let lastBoxIdx = expandedVLines.lastIndex(where: { $0.isProposalOverlay })
        {
            if firstBoxIdx < topVLineIndex {
                topVLineIndex = firstBoxIdx
            } else if lastBoxIdx >= topVLineIndex + mainAreaHeight {
                topVLineIndex = max(0, lastBoxIdx - mainAreaHeight + 1)
            }
        }

        reportOperationResult(
            .succeeded(message: String(format: l10n["ai.proposal.received"], proposal.clientName, proposal.reason)))
        renderer.invalidateScreenCache()
        return true
    }

    public func externalExecuteLogo(
        clientId: String,
        clientName: String,
        clientColor: String = "cyan",
        script: String,
        mode: String?,
        viewportRows: Int,
        viewportCols: Int
    ) -> EditorExternalLogoResult {
        let cursor = externalGetCursor(bufferTarget: nil)
        let (proposal, outputStr) = externalRequestService.createLogoProposal(
            clientId: clientId,
            clientName: clientName,
            clientColor: clientColor,
            script: script,
            targetBuffer: buffer,
            cursorLine: cursor?.line ?? 1,
            cursorVisualCol: cursor?.visualCol ?? 1,
            tabSize: displayConfig.tabSize,
            borderStyle: defaultBorderStyle,
            arrowStyle: defaultArrowStyle
        )
        guard externalShowPreview(proposal, viewportRows: viewportRows, viewportCols: viewportCols) else {
            return EditorExternalLogoResult(success: false, result: outputStr, error: "Failed to create proposal")
        }
        return EditorExternalLogoResult(success: true, result: outputStr, error: nil)
    }

    public func externalExecuteLogo(script: String, mode: String?) -> EditorExternalLogoResult {
        let size = terminal.getWindowSize()
        return externalExecuteLogo(
            clientId: "zago-ipc-logo",
            clientName: "zago IPC",
            script: script,
            mode: mode,
            viewportRows: size.rows,
            viewportCols: size.cols
        )
    }

    public func externalExecuteLogoDirect(script: String, mode: String?) -> EditorExternalLogoResult {
        logoEngine.execute(script)
        let outputStr = buffer.lines.joined(separator: "\n")
        renderer.invalidateScreenCache()
        return EditorExternalLogoResult(success: true, result: outputStr, error: nil)
    }

    public func externalGetHistory(limit: Int) -> [AIHistoryEntry] {
        historyStore.recentEntries(limit: limit)
    }

    private func resolveExternalBufferTarget(_ target: String?) -> TextBuffer? {
        externalRequestService.resolveBuffer(target: target, buffers: buffers, activeBuffer: buffer)
    }
}
