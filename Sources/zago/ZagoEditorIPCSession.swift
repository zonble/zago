import Editor
import Foundation
import IPCServer

final class ZagoEditorIPCSession: ZagoIPCServerDataSource, ZagoIPCServerDelegate {
    let server: any ZagoIPCServer
    private weak var editor: Editor?
    private let terminal: EditorTerminal
    private let dateFormatter = ISO8601DateFormatter()

    var socketPath: String { server.socketPath }
    var sessionToken: String { server.sessionToken }

    init(editor: Editor, terminal: EditorTerminal) {
        self.editor = editor
        self.terminal = terminal
        let server = ZagoIPCServerFactory.make()
        self.server = server
        server.delegate = self
        server.dataSource = self
    }

    func start() throws {
        try server.start()
    }

    func stop() {
        server.stop()
    }
    func ipcServerGetBuffers(_ server: any ZagoIPCServer) throws -> [BufferInfo] {
        guard let editor else { throw IPCServerRequestError.unavailable }
        return try perform(on: editor) {
            editor.externalGetBuffers().map {
                BufferInfo(
                    bufferId: $0.bufferId, filePath: $0.filePath, fileName: $0.fileName, isModified: $0.isModified,
                    isFocused: $0.isFocused)
            }
        }
    }

    func ipcServer(
        _ server: any ZagoIPCServer,
        textFor bufferTarget: String?,
        startLine: Int?,
        endLine: Int?
    ) throws -> (lines: [String], totalLines: Int)? {
        guard let editor else { throw IPCServerRequestError.unavailable }
        return try perform(on: editor) {
            guard
                let result = editor.externalGetText(
                    bufferTarget: bufferTarget,
                    startLine: startLine,
                    endLine: endLine
                )
            else {
                return nil
            }
            return (lines: result.lines, totalLines: result.totalLines)
        }
    }

    func ipcServer(_ server: any ZagoIPCServer, cursorFor bufferTarget: String?) throws -> (
        line: Int, column: Int, visualCol: Int, mode: String
    )? {
        guard let editor else { throw IPCServerRequestError.unavailable }
        return try perform(on: editor) {
            guard let cursor = editor.externalGetCursor(bufferTarget: bufferTarget) else {
                return nil
            }
            return (line: cursor.line, column: cursor.column, visualCol: cursor.visualCol, mode: cursor.mode)
        }
    }

    func ipcServer(
        _ server: any ZagoIPCServer, showPreviewFor client: IPCClientIdentity, reason: String,
        affectedFiles: [AffectedFilePayload]
    ) throws -> Bool {
        guard let editor else { throw IPCServerRequestError.unavailable }
        let proposal = AIProposal(
            clientId: client.clientId,
            clientName: client.clientName,
            clientColor: client.color,
            reason: reason,
            affectedFiles: affectedFiles.map(Self.makeAffectedFileProposal)
        )
        let size = terminal.getWindowSize()
        let accepted = try perform(on: editor) {
            editor.externalShowPreview(proposal, viewportRows: size.rows, viewportCols: size.cols)
        }
        if accepted {
            terminal.wakeup()
        }
        return accepted
    }

    func ipcServer(_ server: any ZagoIPCServer, executeLogo script: String, mode: String?) throws -> (
        success: Bool, result: String, error: String?
    ) {
        guard let editor else { throw IPCServerRequestError.unavailable }
        let result = try perform(on: editor) {
            editor.externalExecuteLogo(script: script, mode: mode)
        }
        terminal.wakeup()
        return (success: result.success, result: result.result, error: result.error)
    }

    func ipcServer(_ server: any ZagoIPCServer, historyWithLimit limit: Int) throws -> [IPCHistoryEntry] {
        guard let editor else { throw IPCServerRequestError.unavailable }
        return try perform(on: editor) {
            editor.externalGetHistory(limit: limit).map { entry in
                IPCHistoryEntry(
                    id: entry.id,
                    author: entry.clientName,
                    reason: entry.reason,
                    action: entry.decision,
                    timestamp: self.dateFormatter.string(from: entry.timestamp)
                )
            }
        }
    }

    func ipcServer(_ server: any ZagoIPCServer, clientDidDisconnect client: IPCClientIdentity) {
        // Do not auto-purge proposals from queue on disconnect.
        // Pushed proposals stay in editor.proposalQueue until explicitly accepted or rejected by the user.
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

    private func perform<T>(on editor: Editor, _ operation: @escaping () -> T) throws -> T {
        do {
            return try editor.performOnEditorLoop(operation)
        } catch EditorLoopRequestError.timedOut {
            throw IPCServerRequestError.timedOut
        }
    }
}
