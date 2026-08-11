import Editor
import Foundation
import IPCServer

final class ZagoEditorIPCSession {
    let server: any ZagoIPCServer
    private let target: ZagoEditorJSONRPCTarget

    var socketPath: String { server.socketPath }
    var sessionToken: String { server.sessionToken }

    init(editor: Editor, terminal: EditorTerminal) {
        let server = ZagoIPCServerFactory.make()
        let target = ZagoEditorJSONRPCTarget(editor: editor, terminal: terminal)
        server.delegate = target
        self.server = server
        self.target = target
    }

    func start() throws {
        try server.start()
    }

    func stop() {
        server.stop()
    }
}

final class ZagoEditorJSONRPCTarget: ZagoIPCServerDelegate {
    private weak var editor: Editor?
    private let terminal: EditorTerminal
    private let dateFormatter = ISO8601DateFormatter()

    init(editor: Editor, terminal: EditorTerminal) {
        self.editor = editor
        self.terminal = terminal
    }

    func handleGetBuffers() -> [BufferInfo] {
        guard let editor else { return [] }
        return editor.performOnEditorLoop {
            editor.externalGetBuffers().map {
                BufferInfo(
                    bufferId: $0.bufferId,
                    filePath: $0.filePath,
                    fileName: $0.fileName,
                    isModified: $0.isModified,
                    isFocused: $0.isFocused
                )
            }
        }
    }

    func handleGetText(
        bufferTarget: String?,
        startLine: Int?,
        endLine: Int?
    ) -> (lines: [String], totalLines: Int)? {
        guard let editor else { return nil }
        return editor.performOnEditorLoop {
            guard let result = editor.externalGetText(
                bufferTarget: bufferTarget,
                startLine: startLine,
                endLine: endLine
            ) else {
                return nil
            }
            return (lines: result.lines, totalLines: result.totalLines)
        }
    }

    func handleGetCursor(bufferTarget: String?) -> (line: Int, column: Int, visualCol: Int, mode: String)? {
        guard let editor else { return nil }
        return editor.performOnEditorLoop {
            guard let cursor = editor.externalGetCursor(bufferTarget: bufferTarget) else {
                return nil
            }
            return (line: cursor.line, column: cursor.column, visualCol: cursor.visualCol, mode: cursor.mode)
        }
    }

    func handleShowPreview(clientId: String, reason: String, affectedFiles: [AffectedFilePayload]) -> Bool {
        guard let editor else { return false }
        let proposal = AIProposal(
            clientId: clientId,
            clientName: clientId,
            reason: reason,
            affectedFiles: affectedFiles.map(Self.makeAffectedFileProposal)
        )
        let size = terminal.getWindowSize()
        let accepted = editor.performOnEditorLoop {
            editor.externalShowPreview(proposal, viewportRows: size.rows, viewportCols: size.cols)
        }
        if accepted {
            terminal.wakeup()
        }
        return accepted
    }

    func handleExecuteLogo(script: String, mode: String?) -> (success: Bool, result: String, error: String?) {
        guard let editor else {
            return (success: false, result: "", error: "Editor unavailable")
        }
        let result = editor.performOnEditorLoop {
            editor.externalExecuteLogo(script: script, mode: mode)
        }
        terminal.wakeup()
        return (success: result.success, result: result.result, error: result.error)
    }

    func handleGetHistory(limit: Int) -> [JSONValue] {
        guard let editor else { return [] }
        return editor.performOnEditorLoop {
            editor.externalGetHistory(limit: limit).map { entry in
                .object([
                    "id": .string(entry.id),
                    "author": .string(entry.clientName),
                    "reason": .string(entry.reason),
                    "action": .string(entry.decision),
                    "timestamp": .string(self.dateFormatter.string(from: entry.timestamp)),
                ])
            }
        }
    }

    private static func makeAffectedFileProposal(_ payload: AffectedFilePayload) -> AffectedFileProposal {
        AffectedFileProposal(
            filePath: payload.filePath,
            bufferId: payload.bufferId,
            chunks: payload.chunks.map { chunk in
                ProposalChunk(
                    targetLine: chunk.targetLine,
                    targetCol: chunk.targetCol,
                    lines: chunk.lines,
                    insertMode: OverlayInsertMode.parse(chunk.insertMode),
                    type: ProposalContentType.parse(chunk.type)
                )
            }
        )
    }
}
