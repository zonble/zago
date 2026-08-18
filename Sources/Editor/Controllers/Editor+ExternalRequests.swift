import Foundation

public struct EditorExternalBufferInfo: Sendable {
    public let bufferId: String
    public let filePath: String?
    public let fileName: String
    public let isModified: Bool
    public let isFocused: Bool
}

public struct EditorExternalTextResult: Sendable {
    public let lines: [String]
    public let totalLines: Int
}

public struct EditorExternalSelectionResult: Sendable {
    public let hasSelection: Bool
    public let text: String
    public let lines: [String]
    public let startLine: Int?
    public let startColumn: Int?
    public let endLine: Int?
    public let endColumn: Int?
}

public struct EditorExternalCursorInfo: Sendable {
    public let line: Int
    public let column: Int
    public let visualCol: Int
    public let mode: String
}

public struct EditorExternalLogoResult: Sendable {
    public let success: Bool
    public let result: String
    public let error: String?
}

extension Editor {
    public func externalGetBuffers() -> [EditorExternalBufferInfo] {
        buffers.enumerated().map { (index, buf) in
            let fileName = buf.filePath.map { NSString(string: $0).lastPathComponent } ?? l10n["buffer.untitled"]
            return EditorExternalBufferInfo(
                bufferId: buf.id,
                filePath: buf.filePath,
                fileName: fileName,
                isModified: buf.isModified,
                isFocused: index == currentBufferIndex
            )
        }
    }

    public func externalGetText(
        bufferTarget: String?,
        startLine: Int?,
        endLine: Int?
    ) -> EditorExternalTextResult? {
        let targetBuf = resolveExternalBufferTarget(bufferTarget) ?? buffer
        let allLines = targetBuf.lines
        let total = allLines.count
        guard total > 0 else { return EditorExternalTextResult(lines: [], totalLines: 0) }

        let sLine = max(1, startLine ?? 1) - 1
        let eLine = min(total, endLine ?? total) - 1

        guard sLine <= eLine, sLine < total else {
            return EditorExternalTextResult(lines: [], totalLines: total)
        }

        return EditorExternalTextResult(lines: Array(allLines[sLine...eLine]), totalLines: total)
    }

    public func externalGetSelection(bufferTarget: String?) -> EditorExternalSelectionResult? {
        let targetBuf = resolveExternalBufferTarget(bufferTarget) ?? buffer
        guard !targetBuf.isDirectoryBuffer else { return nil }
        guard let mark = targetBuf.selectionMark else {
            return EditorExternalSelectionResult(
                hasSelection: false,
                text: "",
                lines: [],
                startLine: nil,
                startColumn: nil,
                endLine: nil,
                endColumn: nil
            )
        }

        let range = TextBuffer.getOrderedRange(
            mark1: mark,
            mark2: (line: targetBuf.lineIndex, column: targetBuf.columnIndex)
        )
        guard range.start.line != range.end.line || range.start.column != range.end.column else {
            return EditorExternalSelectionResult(
                hasSelection: false,
                text: "",
                lines: [],
                startLine: range.start.line + 1,
                startColumn: range.start.column + 1,
                endLine: range.end.line + 1,
                endColumn: range.end.column + 1
            )
        }
        guard range.start.line >= 0,
            range.end.line >= 0,
            range.start.line < targetBuf.lines.count,
            range.end.line < targetBuf.lines.count
        else {
            return nil
        }

        let selectedLines: [String]
        if range.start.line == range.end.line {
            let line = targetBuf.lines[range.start.line]
            selectedLines = [
                String(line[safeCharacterRange: range.start.column..<range.end.column])
            ]
        } else {
            var pieces: [String] = []
            let firstLine = targetBuf.lines[range.start.line]
            pieces.append(String(firstLine[safeCharacterRange: range.start.column..<firstLine.count]))
            if range.end.line > range.start.line + 1 {
                pieces.append(contentsOf: targetBuf.lines[(range.start.line + 1)..<range.end.line])
            }
            let lastLine = targetBuf.lines[range.end.line]
            pieces.append(String(lastLine[safeCharacterRange: 0..<range.end.column]))
            selectedLines = pieces
        }

        return EditorExternalSelectionResult(
            hasSelection: true,
            text: selectedLines.joined(separator: "\n"),
            lines: selectedLines,
            startLine: range.start.line + 1,
            startColumn: range.start.column + 1,
            endLine: range.end.line + 1,
            endColumn: range.end.column + 1
        )
    }

    public func externalGetCursor(bufferTarget: String?) -> EditorExternalCursorInfo? {
        let targetBuf = resolveExternalBufferTarget(bufferTarget) ?? buffer
        let modeStr = isCanvasModeActive ? "canvas" : (isTableModeActive ? "table" : "text")
        let visualCol =
            isCanvasModeActive
            ? canvasVisualColumn + 1
            : targetBuf.lines[targetBuf.lineIndex].visualColumn(forCharacterOffset: targetBuf.columnIndex) + 1
        return EditorExternalCursorInfo(
            line: targetBuf.lineIndex + 1,
            column: targetBuf.columnIndex + 1,
            visualCol: visualCol,
            mode: modeStr
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
        let generatedLines = renderExternalLogoProposalLines(script: script)
        let outputStr = generatedLines.joined(separator: "\n")
        let cursor = externalGetCursor(bufferTarget: nil)
        let chunk = ProposalChunk(
            targetLine: cursor?.line ?? 1,
            targetCol: cursor?.visualCol ?? 1,
            lines: generatedLines,
            insertMode: .d1Insert,
            type: .text
        )
        let proposal = AIProposal(
            clientId: clientId,
            clientName: clientName,
            clientColor: clientColor,
            reason: "LOGO proposal",
            affectedFiles: [
                AffectedFileProposal(
                    filePath: buffer.filePath ?? "active",
                    bufferId: buffer.id,
                    chunks: [chunk]
                )
            ]
        )
        guard externalShowPreview(proposal, viewportRows: viewportRows, viewportCols: viewportCols) else {
            return EditorExternalLogoResult(success: false, result: outputStr, error: "Failed to create proposal")
        }
        return EditorExternalLogoResult(success: true, result: outputStr, error: nil)
    }

    private func renderExternalLogoProposalLines(script: String) -> [String] {
        let scratch = Editor(
            options: EditorOptions(language: language),
            dependencies: EditorDependencies(
                fileIOStrategy: fileIOStrategy,
                terminal: terminal,
                gitService: gitService
            ),
            initialVariables: [:]
        )
        scratch.logoEngine.execute(script)
        let lines = scratch.buffer.lines
        guard lines.count > 1 || lines.first?.isEmpty == false else {
            return [""]
        }
        return lines
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
        AIHistoryLogManager.shared.recentEntries(limit: limit)
    }

    private func resolveExternalBufferTarget(_ target: String?) -> TextBuffer? {
        guard let target, !target.isEmpty, target != "active" else { return buffer }
        return buffers.first {
            $0.id == target
                || $0.filePath == target
                || ($0.filePath != nil && NSString(string: $0.filePath!).lastPathComponent == target)
        }
    }
}

extension String {
    fileprivate subscript(safeCharacterRange range: Range<Int>) -> Substring {
        let lower = max(0, min(range.lowerBound, count))
        let upper = max(lower, min(range.upperBound, count))
        let lowerIndex = index(startIndex, offsetBy: lower)
        let upperIndex = index(startIndex, offsetBy: upper)
        return self[lowerIndex..<upperIndex]
    }
}
