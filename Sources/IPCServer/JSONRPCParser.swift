import Foundation

enum ZagoIPCRequest {
    case register(client: IPCClientIdentity)
    case getBuffers
    case getText(bufferTarget: String?, startLine: Int?, endLine: Int?)
    case getSelection(bufferTarget: String?)
    case getCursor(bufferTarget: String?)
    case showPreview(client: IPCClientIdentity, reason: String, affectedFiles: [AffectedFilePayload])
    case executeLogo(client: IPCClientIdentity, script: String, mode: String?)
    case getHistory(limit: Int)
}

struct ZagoIPCParsedRequest {
    let id: JSONRPCId?
    let request: ZagoIPCRequest
}

enum JSONRPCParseResult {
    case success(ZagoIPCParsedRequest)
    case failure(JSONRPCResponse)
}

enum ZagoIPCResponse {
    case registered(clientId: String, clientName: String)
    case buffers([BufferInfo])
    case text(lines: [String], totalLines: Int)
    case selection(IPCSelectionInfo)
    case cursor(line: Int, column: Int, visualCol: Int, mode: String)
    case previewShown
    case logo(success: Bool, result: String, error: String?)
    case history([IPCHistoryEntry])
}

enum JSONRPCResponse {
    case success(id: JSONRPCId?, result: ZagoIPCResponse)
    case failure(id: JSONRPCId?, error: JSONRPCError)

    var error: JSONRPCError? {
        guard case .failure(_, let error) = self else { return nil }
        return error
    }

    func encodedData() throws -> Data {
        let encoder = JSONEncoder()
        switch self {
        case .failure(let id, let error):
            return try encoder.encode(JSONRPCFailureEnvelope(error: error, id: id))
        case .success(let id, let result):
            switch result {
            case .registered(let clientId, let clientName):
                return try encoder.encode(
                    JSONRPCSuccessEnvelope(
                        result: RegistrationResult(registered: true, clientId: clientId, clientName: clientName), id: id
                    ))
            case .buffers(let buffers):
                let result = BuffersResult(
                    buffers: buffers.map(BufferResult.init),
                    activeBufferId: buffers.first(where: \.isFocused)?.bufferId ?? ""
                )
                return try encoder.encode(JSONRPCSuccessEnvelope(result: result, id: id))
            case .text(let lines, let totalLines):
                return try encoder.encode(
                    JSONRPCSuccessEnvelope(result: TextResult(lines: lines, totalLines: totalLines), id: id))
            case .selection(let selection):
                return try encoder.encode(JSONRPCSuccessEnvelope(result: SelectionResult(selection), id: id))
            case .cursor(let line, let column, let visualCol, let mode):
                return try encoder.encode(
                    JSONRPCSuccessEnvelope(
                        result: CursorResult(line: line, column: column, canvasVisualColumn: visualCol, mode: mode),
                        id: id))
            case .previewShown:
                return try encoder.encode(
                    JSONRPCSuccessEnvelope(result: PreviewResult(success: true, previewActive: true), id: id))
            case .logo(let success, let result, let error):
                return try encoder.encode(
                    JSONRPCSuccessEnvelope(
                        result: LogoResult(success: success, lastResult: result, error: error), id: id))
            case .history(let entries):
                return try encoder.encode(JSONRPCSuccessEnvelope(result: HistoryResult(entries: entries), id: id))
            }
        }
    }
}

private struct RegistrationResult: Encodable {
    let registered: Bool
    let clientId: String
    let clientName: String
}
private struct BufferResult: Encodable {
    let bufferId: String
    let filePath: String?
    let fileName: String
    let isModified: Bool
    let isFocused: Bool

    init(_ buffer: BufferInfo) {
        bufferId = buffer.bufferId
        filePath = buffer.filePath
        fileName = buffer.fileName
        isModified = buffer.isModified
        isFocused = buffer.isFocused
    }
}
private struct BuffersResult: Encodable {
    let buffers: [BufferResult]
    let activeBufferId: String
}
private struct TextResult: Encodable {
    let lines: [String]
    let totalLines: Int
}
private struct SelectionResult: Encodable {
    let hasSelection: Bool
    let text: String
    let lines: [String]
    let startLine: Int?
    let startColumn: Int?
    let endLine: Int?
    let endColumn: Int?

    init(_ selection: IPCSelectionInfo) {
        self.hasSelection = selection.hasSelection
        self.text = selection.text
        self.lines = selection.lines
        self.startLine = selection.startLine
        self.startColumn = selection.startColumn
        self.endLine = selection.endLine
        self.endColumn = selection.endColumn
    }
}
private struct CursorResult: Encodable {
    let line: Int
    let column: Int
    let canvasVisualColumn: Int
    let mode: String
}
private struct PreviewResult: Encodable {
    let success: Bool
    let previewActive: Bool
}
private struct LogoResult: Encodable {
    let success: Bool
    let lastResult: String
    let error: String?
}
private struct HistoryResult: Encodable { let entries: [IPCHistoryEntry] }

final class JSONRPCParser {
    static let maxOverlayLines = 1_000
    static let maxScriptBytes = 1_048_576

    let sessionToken: String
    private var registeredClients: [String: IPCClientIdentity] = [:]
    private let lock = NSLock()

    init(sessionToken: String) {
        self.sessionToken = sessionToken
    }

    func parseMessage(_ data: Data, connectionId: String) -> JSONRPCParseResult {
        do {
            let decoder = JSONDecoder()
            let envelope = try decoder.decode(JSONRPCEnvelope.self, from: data)
            guard envelope.jsonrpc == "2.0" else {
                return .failure(failure(code: -32600, message: "Invalid Request: jsonrpc must be 2.0", id: envelope.id))
            }
            return try parse(envelope: envelope, data: data, connectionId: connectionId, decoder: decoder)
        } catch {
            return .failure(failure(code: -32600, message: "Invalid Request: \(error.localizedDescription)", id: nil))
        }
    }

    @discardableResult
    func unregisterClient(connectionId: String) -> IPCClientIdentity? {
        lock.lock()
        defer { lock.unlock() }
        return registeredClients.removeValue(forKey: connectionId)
    }

    func makeSuccessResponse(for request: ZagoIPCParsedRequest, response: ZagoIPCResponse) -> JSONRPCResponse {
        .success(id: request.id, result: response)
    }

    func makeFailureResponse(code: Int, message: String, request: ZagoIPCParsedRequest) -> JSONRPCResponse {
        failure(code: code, message: message, id: request.id)
    }

    private func parse(envelope: JSONRPCEnvelope, data: Data, connectionId: String, decoder: JSONDecoder) throws
        -> JSONRPCParseResult
    {
        switch envelope.method {
        case "zago.client.register":
            return parseRegister(
                try decoder.decode(JSONRPCRequest<ClientRegistrationParams>.self, from: data),
                connectionId: connectionId)
        case "zago.buffer.getBuffers":
            return requireRegistration(connectionId, id: envelope.id) { _ in
                .success(.init(id: envelope.id, request: .getBuffers))
            }
        case "zago.buffer.getText":
            let request = try decoder.decode(JSONRPCRequest<GetTextParams>.self, from: data)
            return requireRegistration(connectionId, id: request.id) { _ in
                let params = request.params
                return .success(
                    .init(
                        id: request.id,
                        request: .getText(
                            bufferTarget: params?.bufferTarget ?? params?.bufferId, startLine: params?.startLine,
                            endLine: params?.endLine)))
            }
        case "zago.buffer.getSelection":
            let request = try decoder.decode(JSONRPCRequest<GetSelectionParams>.self, from: data)
            return requireRegistration(connectionId, id: request.id) { _ in
                let params = request.params
                return .success(
                    .init(
                        id: request.id,
                        request: .getSelection(bufferTarget: params?.bufferTarget ?? params?.bufferId)))
            }
        case "zago.buffer.getCursor":
            let request = try decoder.decode(JSONRPCRequest<GetCursorParams>.self, from: data)
            return requireRegistration(connectionId, id: request.id) { _ in
                let params = request.params
                return .success(
                    .init(id: request.id, request: .getCursor(bufferTarget: params?.bufferTarget ?? params?.bufferId)))
            }
        case "zago.overlay.showPreview":
            return parseShowPreview(
                try decoder.decode(JSONRPCRequest<OverlayPreviewParams>.self, from: data), connectionId: connectionId)
        case "zago.buffer.executeLogo":
            return parseExecuteLogo(
                try decoder.decode(JSONRPCRequest<ExecuteLogoParams>.self, from: data), connectionId: connectionId)
        case "zago.history.getEntries":
            let request = try decoder.decode(JSONRPCRequest<HistoryParams>.self, from: data)
            return requireRegistration(connectionId, id: request.id) { _ in
                let limit = request.params?.limit ?? 20
                guard (1...100).contains(limit) else {
                    return .failure(
                        self.failure(code: -32602, message: "limit must be between 1 and 100", id: request.id))
                }
                return .success(.init(id: request.id, request: .getHistory(limit: limit)))
            }
        default:
            return .failure(failure(code: -32601, message: "Method not found: \(envelope.method)", id: envelope.id))
        }
    }

    private func parseRegister(_ request: JSONRPCRequest<ClientRegistrationParams>, connectionId: String)
        -> JSONRPCParseResult
    {
        guard let params = request.params,
            params.auth == sessionToken,
            (1...128).contains(params.clientId.utf8.count),
            (1...128).contains(params.clientName.utf8.count)
        else {
            return .failure(
                failure(
                    code: 401, message: "Unauthorized: valid auth, clientId, and clientName are required",
                    id: request.id))
        }
        let color = (params.color ?? "cyan").lowercased()
        guard ["cyan", "purple", "green", "magenta"].contains(color) else {
            return .failure(failure(code: -32602, message: "Unsupported client color", id: request.id))
        }
        let client = IPCClientIdentity(
            clientId: params.clientId, clientName: params.clientName, agentType: params.agentType, color: color)
        lock.lock()
        let alreadyConnected = registeredClients.contains {
            $0.key != connectionId && $0.value.clientId == client.clientId
        }
        guard !alreadyConnected else {
            lock.unlock()
            return .failure(
                failure(code: 409, message: "clientId is already registered on another connection", id: request.id))
        }
        registeredClients[connectionId] = client
        lock.unlock()
        return .success(.init(id: request.id, request: .register(client: client)))
    }

    private func parseShowPreview(_ request: JSONRPCRequest<OverlayPreviewParams>, connectionId: String)
        -> JSONRPCParseResult
    {
        requireRegistration(connectionId, id: request.id) { client in
            guard let params = request.params,
                params.clientId == client.clientId,
                !params.reason.isEmpty,
                params.reason.utf8.count <= 4_096,
                !params.affectedFiles.isEmpty
            else {
                return .failure(self.failure(code: -32602, message: "Invalid preview payload", id: request.id))
            }
            var lineCount = 0
            for file in params.affectedFiles {
                for chunk in file.chunks {
                    guard chunk.targetLine > 0, chunk.targetCol > 0 else {
                        return .failure(self.failure(code: -32602, message: "Invalid proposal chunk", id: request.id))
                    }
                    lineCount += chunk.lines.count
                    guard lineCount <= Self.maxOverlayLines else {
                        return .failure(
                            self.failure(code: 413, message: "Proposal exceeds maxOverlayLines", id: request.id))
                    }
                }
            }
            return .success(
                .init(
                    id: request.id,
                    request: .showPreview(client: client, reason: params.reason, affectedFiles: params.affectedFiles)))
        }
    }

    private func parseExecuteLogo(_ request: JSONRPCRequest<ExecuteLogoParams>, connectionId: String)
        -> JSONRPCParseResult
    {
        requireRegistration(connectionId, id: request.id) { client in
            guard let params = request.params else {
                return .failure(self.failure(code: -32602, message: "Missing script parameter", id: request.id))
            }
            guard params.script.utf8.count <= Self.maxScriptBytes else {
                return .failure(self.failure(code: 413, message: "Script exceeds maxPayloadBytes", id: request.id))
            }
            return .success(
                .init(id: request.id, request: .executeLogo(client: client, script: params.script, mode: params.mode)))
        }
    }

    private func requireRegistration(
        _ connectionId: String, id: JSONRPCId?, body: (IPCClientIdentity) -> JSONRPCParseResult
    ) -> JSONRPCParseResult {
        lock.lock()
        let client = registeredClients[connectionId]
        lock.unlock()
        guard let client else {
            return .failure(failure(code: 401, message: "Unauthorized: register this connection first", id: id))
        }
        return body(client)
    }

    private func failure(code: Int, message: String, id: JSONRPCId?) -> JSONRPCResponse {
        .failure(id: id, error: JSONRPCError(code: code, message: message))
    }
}
