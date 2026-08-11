import Foundation

public struct BufferInfo {
    public let bufferId: String
    public let filePath: String?
    public let fileName: String
    public let isModified: Bool
    public let isFocused: Bool

    public init(bufferId: String, filePath: String?, fileName: String, isModified: Bool, isFocused: Bool) {
        self.bufferId = bufferId
        self.filePath = filePath
        self.fileName = fileName
        self.isModified = isModified
        self.isFocused = isFocused
    }
}

public protocol ZagoIPCServerDelegate: AnyObject {
    func handleGetBuffers() -> [BufferInfo]
    func handleGetText(bufferTarget: String?, startLine: Int?, endLine: Int?) -> (lines: [String], totalLines: Int)?
    func handleGetCursor(bufferTarget: String?) -> (line: Int, column: Int, visualCol: Int, mode: String)?
    func handleShowPreview(clientId: String, reason: String, affectedFiles: [AffectedFilePayload]) -> Bool
    func handleExecuteLogo(script: String, mode: String?) -> (success: Bool, result: String, error: String?)
    func handleGetHistory(limit: Int) -> [JSONValue]
}

enum ZagoIPCRequest {
    case register(clientId: String, clientName: String)
    case getBuffers
    case getText(bufferTarget: String?, startLine: Int?, endLine: Int?)
    case getCursor(bufferTarget: String?)
    case showPreview(clientId: String, reason: String, affectedFiles: [AffectedFilePayload])
    case executeLogo(script: String, mode: String?)
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
    case cursor(line: Int, column: Int, visualCol: Int, mode: String)
    case previewShown
    case logo(success: Bool, result: String, error: String?)
    case history([JSONValue])
}

final class JSONRPCParser {
    let sessionToken: String
    private var registeredClients: [String: ClientRegistrationParams] = [:]
    private let lock = NSLock()

    init(sessionToken: String) {
        self.sessionToken = sessionToken
    }

    func parseMessage(_ data: Data) -> JSONRPCParseResult {
        do {
            let request = try JSONDecoder().decode(JSONRPCRequest.self, from: data)
            return normalize(request)
        } catch {
            return .failure(JSONRPCResponse.failure(code: -32700, message: "Parse error: \(error.localizedDescription)", id: nil))
        }
    }

    func normalize(_ request: JSONRPCRequest) -> JSONRPCParseResult {
        switch request.method {
        case "zago.client.register":
            return parseRegister(request)

        case "zago.buffer.getBuffers":
            return .success(ZagoIPCParsedRequest(id: request.id, request: .getBuffers))

        case "zago.buffer.getText":
            let paramsObj = request.params?.objectValue
            let bufferTarget = paramsObj?["bufferTarget"]?.stringValue ?? paramsObj?["bufferId"]?.stringValue
            let startLine = paramsObj?["startLine"]?.intValue
            let endLine = paramsObj?["endLine"]?.intValue
            return .success(ZagoIPCParsedRequest(
                id: request.id,
                request: .getText(bufferTarget: bufferTarget, startLine: startLine, endLine: endLine)
            ))

        case "zago.buffer.getCursor":
            let paramsObj = request.params?.objectValue
            let bufferTarget = paramsObj?["bufferTarget"]?.stringValue ?? paramsObj?["bufferId"]?.stringValue
            return .success(ZagoIPCParsedRequest(id: request.id, request: .getCursor(bufferTarget: bufferTarget)))

        case "zago.overlay.showPreview":
            return parseShowPreview(request)

        case "zago.buffer.executeLogo":
            return parseExecuteLogo(request)

        case "zago.history.getEntries":
            let paramsObj = request.params?.objectValue
            let limit = paramsObj?["limit"]?.intValue ?? 20
            return .success(ZagoIPCParsedRequest(id: request.id, request: .getHistory(limit: limit)))

        default:
            return .failure(JSONRPCResponse.failure(
                code: -32601,
                message: "Method not found: \(request.method)",
                id: request.id
            ))
        }
    }

    func makeSuccessResponse(for request: ZagoIPCParsedRequest, response: ZagoIPCResponse) -> JSONRPCResponse {
        switch response {
        case .registered(let clientId, let clientName):
            return JSONRPCResponse.success(result: .object([
                "registered": .bool(true),
                "clientId": .string(clientId),
                "clientName": .string(clientName),
            ]), id: request.id)

        case .buffers(let buffers):
            let activeId = buffers.first(where: { $0.isFocused })?.bufferId ?? ""
            let bufferValues: [JSONValue] = buffers.map { buffer in
                var object: [String: JSONValue] = [
                    "bufferId": .string(buffer.bufferId),
                    "fileName": .string(buffer.fileName),
                    "isModified": .bool(buffer.isModified),
                    "isFocused": .bool(buffer.isFocused),
                ]
                if let path = buffer.filePath {
                    object["filePath"] = .string(path)
                }
                return .object(object)
            }
            return JSONRPCResponse.success(result: .object([
                "buffers": .array(bufferValues),
                "activeBufferId": .string(activeId),
            ]), id: request.id)

        case .text(let lines, let totalLines):
            return JSONRPCResponse.success(result: .object([
                "lines": .array(lines.map { .string($0) }),
                "totalLines": .number(Double(totalLines)),
            ]), id: request.id)

        case .cursor(let line, let column, let visualCol, let mode):
            return JSONRPCResponse.success(result: .object([
                "line": .number(Double(line)),
                "column": .number(Double(column)),
                "canvasVisualColumn": .number(Double(visualCol)),
                "mode": .string(mode),
            ]), id: request.id)

        case .previewShown:
            return JSONRPCResponse.success(result: .object([
                "success": .bool(true),
                "previewActive": .bool(true),
            ]), id: request.id)

        case .logo(let success, let result, let error):
            var object: [String: JSONValue] = [
                "success": .bool(success),
                "lastResult": .string(result),
            ]
            if let error {
                object["error"] = .string(error)
            }
            return JSONRPCResponse.success(result: .object(object), id: request.id)

        case .history(let entries):
            return JSONRPCResponse.success(result: .object([
                "entries": .array(entries)
            ]), id: request.id)
        }
    }

    func makeFailureResponse(code: Int, message: String, request: ZagoIPCParsedRequest) -> JSONRPCResponse {
        JSONRPCResponse.failure(code: code, message: message, id: request.id)
    }

    func unregisterClient(connectionId: String) {
        lock.lock()
        defer { lock.unlock() }
        registeredClients.removeValue(forKey: connectionId)
    }

    private func parseRegister(_ request: JSONRPCRequest) -> JSONRPCParseResult {
        lock.lock()
        defer { lock.unlock() }

        guard let paramsObj = request.params?.objectValue else {
            return .failure(JSONRPCResponse.failure(
                code: -32602,
                message: "Invalid params for zago.client.register",
                id: request.id
            ))
        }

        let auth = paramsObj["auth"]?.stringValue
        guard isAuthValid(auth) else {
            return .failure(JSONRPCResponse.failure(code: 401, message: "Unauthorized: Invalid auth token", id: request.id))
        }

        guard let clientId = paramsObj["clientId"]?.stringValue,
              let clientName = paramsObj["clientName"]?.stringValue else {
            return .failure(JSONRPCResponse.failure(
                code: -32602,
                message: "Missing clientId or clientName",
                id: request.id
            ))
        }

        let registration = ClientRegistrationParams(
            auth: auth,
            clientId: clientId,
            clientName: clientName,
            agentType: paramsObj["agentType"]?.stringValue,
            color: paramsObj["color"]?.stringValue ?? "cyan"
        )
        registeredClients[clientId] = registration

        return .success(ZagoIPCParsedRequest(id: request.id, request: .register(
            clientId: clientId,
            clientName: clientName
        )))
    }

    private func parseShowPreview(_ request: JSONRPCRequest) -> JSONRPCParseResult {
        guard let paramsObj = request.params?.objectValue else {
            return .failure(JSONRPCResponse.failure(
                code: -32602,
                message: "Invalid params for zago.overlay.showPreview",
                id: request.id
            ))
        }

        let auth = paramsObj["auth"]?.stringValue
        guard isAuthValid(auth) else {
            return .failure(JSONRPCResponse.failure(code: 401, message: "Unauthorized: Invalid auth token", id: request.id))
        }

        guard let clientId = paramsObj["clientId"]?.stringValue,
              let reason = paramsObj["reason"]?.stringValue,
              let affectedFilesArr = paramsObj["affectedFiles"]?.arrayValue else {
            return .failure(JSONRPCResponse.failure(
                code: -32602,
                message: "Missing required fields: clientId, reason, or affectedFiles",
                id: request.id
            ))
        }

        var affectedFiles: [AffectedFilePayload] = []
        for fileValue in affectedFilesArr {
            guard let fileObject = fileValue.objectValue,
                  let chunksArray = fileObject["chunks"]?.arrayValue else {
                continue
            }
            let filePath = fileObject["filePath"]?.stringValue
            let bufferId = fileObject["bufferId"]?.stringValue

            var chunks: [ProposalChunkPayload] = []
            for chunkValue in chunksArray {
                guard let chunkObject = chunkValue.objectValue,
                      let targetLine = chunkObject["targetLine"]?.intValue,
                      let targetCol = chunkObject["targetCol"]?.intValue,
                      let linesArray = chunkObject["lines"]?.arrayValue else {
                    continue
                }
                let lines = linesArray.compactMap { $0.stringValue }
                let insertMode = chunkObject["insertMode"]?.stringValue
                let type = chunkObject["type"]?.stringValue
                    ?? chunkObject["chunkType"]?.stringValue
                    ?? chunkObject["contentType"]?.stringValue
                chunks.append(ProposalChunkPayload(
                    targetLine: targetLine,
                    targetCol: targetCol,
                    lines: lines,
                    insertMode: insertMode,
                    type: type
                ))
            }
            affectedFiles.append(AffectedFilePayload(filePath: filePath, bufferId: bufferId, chunks: chunks))
        }

        return .success(ZagoIPCParsedRequest(
            id: request.id,
            request: .showPreview(clientId: clientId, reason: reason, affectedFiles: affectedFiles)
        ))
    }

    private func parseExecuteLogo(_ request: JSONRPCRequest) -> JSONRPCParseResult {
        guard let paramsObj = request.params?.objectValue,
              let script = paramsObj["script"]?.stringValue else {
            return .failure(JSONRPCResponse.failure(
                code: -32602,
                message: "Missing script parameter",
                id: request.id
            ))
        }

        let auth = paramsObj["auth"]?.stringValue
        guard isAuthValid(auth) else {
            return .failure(JSONRPCResponse.failure(code: 401, message: "Unauthorized: Invalid auth token", id: request.id))
        }

        return .success(ZagoIPCParsedRequest(
            id: request.id,
            request: .executeLogo(script: script, mode: paramsObj["mode"]?.stringValue)
        ))
    }

    private func isAuthValid(_ auth: String?) -> Bool {
        if let auth, !auth.isEmpty {
            return auth == sessionToken
        }
        return true
    }
}
