import Diagram
import Drawing
import Foundation

/// Service handling external inspection and proposal creation for IPC and remote clients.
final class ExternalRequestService: @unchecked Sendable {
    init() {}

    /// Resolves target buffer by ID, full file path, or filename suffix.
    func resolveBuffer(
        target: String?,
        buffers: [TextBuffer],
        activeBuffer: TextBuffer
    ) -> TextBuffer? {
        guard let target, !target.isEmpty, target != "active" else { return activeBuffer }
        return buffers.first {
            $0.id == target
                || $0.filePath == target
                || ($0.filePath != nil && NSString(string: $0.filePath!).lastPathComponent == target)
        }
    }

    /// Lists snapshot information of all open buffers.
    func getBuffers(
        buffers: [TextBuffer],
        activeIndex: Int,
        untitledName: String = "Untitled"
    ) -> [EditorExternalBufferInfo] {
        buffers.enumerated().map { (index, buf) in
            let fileName = buf.filePath.map { NSString(string: $0).lastPathComponent } ?? untitledName
            return EditorExternalBufferInfo(
                bufferId: buf.id,
                filePath: buf.filePath,
                fileName: fileName,
                isModified: buf.isModified,
                isFocused: index == activeIndex
            )
        }
    }

    /// Extracts lines within range from target buffer.
    func getText(
        from targetBuf: TextBuffer,
        startLine: Int?,
        endLine: Int?
    ) -> EditorExternalTextResult? {
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

    /// Extracts current text selection from target buffer.
    func getSelection(from targetBuf: TextBuffer) -> EditorExternalSelectionResult? {
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

    /// Queries cursor coordinate and mode string for target buffer.
    func getCursor(
        from targetBuf: TextBuffer,
        isCanvasModeActive: Bool,
        isTableModeActive: Bool,
        canvasVisualColumn: Int
    ) -> EditorExternalCursorInfo {
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

    /// Renders LOGO script into proposal lines and creates AIProposal container.
    func createLogoProposal(
        clientId: String,
        clientName: String,
        clientColor: String = "cyan",
        script: String,
        targetBuffer: TextBuffer,
        cursorLine: Int,
        cursorVisualCol: Int,
        tabSize: Int = 4,
        borderStyle: BorderStyle = .single,
        arrowStyle: ArrowStyle = .solid
    ) -> (proposal: AIProposal, outputStr: String) {
        let generatedLines = LogoExecutionService.render(
            script: script,
            initialVariables: [:],
            tabSize: tabSize,
            borderStyle: borderStyle,
            arrowStyle: arrowStyle
        )
        let outputStr = generatedLines.joined(separator: "\n")
        let chunk = ProposalChunk(
            targetLine: cursorLine,
            targetCol: cursorVisualCol,
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
                    filePath: targetBuffer.filePath ?? "active",
                    bufferId: targetBuffer.id,
                    chunks: [chunk]
                )
            ]
        )
        return (proposal, outputStr)
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
