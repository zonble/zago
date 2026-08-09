import Foundation
import Config
import IPCServer
import LogoEngine

extension Editor: JSONRPCDelegateTarget {

    public func startIPCServerIfNeeded() {
        guard displayConfig.ipcEnabled else { return }
        if ipcServer == nil {
            let server = ZagoIPCServer()
            let handler = JSONRPCHandler(sessionToken: server.sessionToken, target: self)
            server.delegate = handler
            self.ipcServer = server
            self.jsonRpcHandler = handler

            do {
                try server.start()
                setStatusMessage("[IPC] Socket: \(server.socketPath) | Token: \(server.sessionToken)")
            } catch {
                setStatusMessage("[IPC Error] \(error.localizedDescription)")
            }
        }
    }

    public func stopIPCServer() {
        if let server = ipcServer {
            server.stop()
            self.ipcServer = nil
            self.jsonRpcHandler = nil
            setStatusMessage("[IPC Disabled]")
        }
    }

    // MARK: - JSONRPCDelegateTarget

    public func handleGetBuffers() -> [BufferInfo] {
        return buffers.enumerated().map { (index, buf) in
            let fName = buf.filePath.map { NSString(string: $0).lastPathComponent } ?? "Untitled"
            return BufferInfo(
                bufferId: buf.id,
                filePath: buf.filePath,
                fileName: fName,
                isModified: buf.isModified,
                isFocused: index == currentBufferIndex
            )
        }
    }

    public func handleGetText(bufferTarget: String?, startLine: Int?, endLine: Int?) -> (lines: [String], totalLines: Int)? {
        let targetBuf = resolveBufferTarget(bufferTarget) ?? buffer
        let allLines = targetBuf.lines
        let total = allLines.count
        guard total > 0 else { return (lines: [], totalLines: 0) }

        let sLine = max(1, startLine ?? 1) - 1
        let eLine = min(total, endLine ?? total) - 1

        guard sLine <= eLine, sLine < total else {
            return (lines: [], totalLines: total)
        }

        let slice = Array(allLines[sLine...eLine])
        return (lines: slice, totalLines: total)
    }

    public func handleGetCursor(bufferTarget: String?) -> (line: Int, column: Int, visualCol: Int, mode: String)? {
        let targetBuf = resolveBufferTarget(bufferTarget) ?? buffer
        let currentLine = targetBuf.lineIndex + 1
        let currentCol = targetBuf.columnIndex + 1
        let modeStr = isCanvasModeActive ? "canvas" : (isTableModeActive ? "table" : "text")
        let visualCol = isCanvasModeActive ? canvasVisualColumn + 1 : targetBuf.lines[targetBuf.lineIndex].visualColumn(forCharacterOffset: targetBuf.columnIndex) + 1
        return (line: currentLine, column: currentCol, visualCol: visualCol, mode: modeStr)
    }

    private func resolveBufferTarget(_ target: String?) -> TextBuffer? {
        guard let target = target, !target.isEmpty, target != "active" else { return buffer }
        return buffers.first(where: { $0.id == target || $0.filePath == target || ($0.filePath != nil && NSString(string: $0.filePath!).lastPathComponent == target) })
    }

    public func handleShowPreview(clientId: String, reason: String, affectedFiles: [AffectedFilePayload]) -> Bool {
        var affectedProposals: [AffectedFileProposal] = []
        for file in affectedFiles {
            var chunks: [ProposalChunk] = []
            for chunkPayload in file.chunks {
                let mode = OverlayInsertMode.parse(chunkPayload.insertMode ?? "2d_overwrite")
                chunks.append(ProposalChunk(
                    targetLine: chunkPayload.targetLine,
                    targetCol: chunkPayload.targetCol,
                    lines: chunkPayload.lines,
                    insertMode: mode
                ))
            }
            affectedProposals.append(AffectedFileProposal(filePath: file.filePath, bufferId: file.bufferId, chunks: chunks))
        }

        let proposal = AIProposal(
            clientId: clientId,
            clientName: clientId,
            reason: reason,
            affectedFiles: affectedProposals
        )

        proposalQueue.pushProposal(proposal)
        if let minLine = affectedProposals.flatMap({ $0.chunks }).map({ $0.targetLine - 1 }).min() {
            if minLine < topVLineIndex || minLine >= topVLineIndex + 15 {
                topVLineIndex = max(0, minLine)
            }
        }
        self.setStatusMessage("🤖 [AI Proposal from \(proposal.clientName)] \"\(reason)\" (Press Alt+a to Accept, Alt+r to Reject, Alt+p to Preview)")
        self.renderer.invalidateScreenCache()
        terminal.wakeup()
        return true
    }

    public func handleExecuteLogo(script: String, mode: String?) -> (success: Bool, result: String, error: String?) {
        logoEngine.execute(script)
        let outputStr = buffer.lines.joined(separator: "\n")
        self.renderer.invalidateScreenCache()
        terminal.wakeup()
        return (success: true, result: outputStr, error: nil)
    }

    public func handleGetHistory(limit: Int) -> [JSONValue] {
        let entries = AIHistoryLogManager.shared.recentEntries(limit: limit)
        return entries.map { entry in
            let obj: [String: JSONValue] = [
                "id": .string(entry.id),
                "author": .string(entry.clientName),
                "reason": .string(entry.reason),
                "action": .string(entry.decision),
                "timestamp": .string(ISO8601DateFormatter().string(from: entry.timestamp))
            ]
            return JSONValue.object(obj)
        }
    }
}
