import Foundation
import Config
import Drawing
import LogoEngine
import TextMetrics

public protocol JSONRPCDelegateTarget: AnyObject {
    func handleGetText(bufferTarget: String?, startLine: Int?, endLine: Int?) -> (lines: [String], totalLines: Int)?
    func handleGetCursor(bufferTarget: String?) -> (line: Int, column: Int, visualCol: Int, mode: String)?
    func handleShowPreview(clientId: String, reason: String, affectedFiles: [AffectedFilePayload]) -> Bool
    func handleExecuteLogo(script: String, mode: String?) -> (success: Bool, result: String, error: String?)
    func handleGetHistory(limit: Int) -> [JSONValue]
}

public final class JSONRPCHandler {
    public weak var target: JSONRPCDelegateTarget?
    public let sessionToken: String
    private var registeredClients: [String: ClientRegistrationParams] = [:]
    private let lock = NSLock()

    public init(sessionToken: String, target: JSONRPCDelegateTarget? = nil) {
        self.sessionToken = sessionToken
        self.target = target
    }

    public func handleRequest(_ request: JSONRPCRequest, connectionId: String) -> JSONRPCResponse {
        lock.lock()
        defer { lock.unlock() }

        switch request.method {
        case "zago.client.register":
            return processRegister(request)

        case "zago.buffer.getText":
            return processGetText(request)

        case "zago.buffer.getCursor":
            return processGetCursor(request)

        case "zago.overlay.showPreview":
            return processShowPreview(request)

        case "zago.buffer.executeLogo":
            return processExecuteLogo(request)

        case "zago.history.getEntries":
            return processGetHistory(request)

        default:
            return JSONRPCResponse.failure(code: -32601, message: "Method not found: \(request.method)", id: request.id)
        }
    }

    private func isAuthValid(_ auth: String?) -> Bool {
        if let auth = auth, !auth.isEmpty {
            return auth == sessionToken
        }
        return true
    }

    public func unregisterClient(connectionId: String) {
        lock.lock()
        defer { lock.unlock() }
        registeredClients.removeValue(forKey: connectionId)
    }

    // MARK: - Method Handlers

    private func processRegister(_ request: JSONRPCRequest) -> JSONRPCResponse {
        guard let paramsObj = request.params?.objectValue else {
            return JSONRPCResponse.failure(code: -32602, message: "Invalid params for zago.client.register", id: request.id)
        }

        let auth = paramsObj["auth"]?.stringValue
        guard isAuthValid(auth) else {
            return JSONRPCResponse.failure(code: 401, message: "Unauthorized: Invalid auth token", id: request.id)
        }

        guard let clientId = paramsObj["clientId"]?.stringValue,
              let clientName = paramsObj["clientName"]?.stringValue else {
            return JSONRPCResponse.failure(code: -32602, message: "Missing clientId or clientName", id: request.id)
        }

        let registration = ClientRegistrationParams(
            auth: auth,
            clientId: clientId,
            clientName: clientName,
            agentType: paramsObj["agentType"]?.stringValue,
            color: paramsObj["color"]?.stringValue ?? "cyan"
        )
        registeredClients[clientId] = registration

        let resObj: [String: JSONValue] = [
            "registered": .bool(true),
            "clientId": .string(clientId),
            "clientName": .string(clientName)
        ]
        return JSONRPCResponse.success(result: .object(resObj), id: request.id)
    }

    private func processGetText(_ request: JSONRPCRequest) -> JSONRPCResponse {
        let paramsObj = request.params?.objectValue
        let bufferTarget = paramsObj?["bufferTarget"]?.stringValue
        let startLine = paramsObj?["startLine"]?.intValue
        let endLine = paramsObj?["endLine"]?.intValue

        guard let result = target?.handleGetText(bufferTarget: bufferTarget, startLine: startLine, endLine: endLine) else {
            return JSONRPCResponse.failure(code: 404, message: "Target buffer not found", id: request.id)
        }

        let resObj: [String: JSONValue] = [
            "lines": .array(result.lines.map { .string($0) }),
            "totalLines": .number(Double(result.totalLines))
        ]
        return JSONRPCResponse.success(result: .object(resObj), id: request.id)
    }

    private func processGetCursor(_ request: JSONRPCRequest) -> JSONRPCResponse {
        let paramsObj = request.params?.objectValue
        let bufferTarget = paramsObj?["bufferTarget"]?.stringValue

        guard let cursor = target?.handleGetCursor(bufferTarget: bufferTarget) else {
            return JSONRPCResponse.failure(code: 404, message: "Target buffer not found", id: request.id)
        }

        let resObj: [String: JSONValue] = [
            "line": .number(Double(cursor.line)),
            "column": .number(Double(cursor.column)),
            "canvasVisualColumn": .number(Double(cursor.visualCol)),
            "mode": .string(cursor.mode)
        ]
        return JSONRPCResponse.success(result: .object(resObj), id: request.id)
    }

    private func processShowPreview(_ request: JSONRPCRequest) -> JSONRPCResponse {
        guard let paramsObj = request.params?.objectValue else {
            return JSONRPCResponse.failure(code: -32602, message: "Invalid params for zago.overlay.showPreview", id: request.id)
        }

        let auth = paramsObj["auth"]?.stringValue
        guard isAuthValid(auth) else {
            return JSONRPCResponse.failure(code: 401, message: "Unauthorized: Invalid auth token", id: request.id)
        }

        guard let clientId = paramsObj["clientId"]?.stringValue,
              let reason = paramsObj["reason"]?.stringValue,
              let affectedFilesArr = paramsObj["affectedFiles"]?.arrayValue else {
            return JSONRPCResponse.failure(code: -32602, message: "Missing required fields: clientId, reason, or affectedFiles", id: request.id)
        }

        var affectedFiles: [AffectedFilePayload] = []
        for fileVal in affectedFilesArr {
            guard let fileObj = fileVal.objectValue,
                  let filePath = fileObj["filePath"]?.stringValue,
                  let chunksArr = fileObj["chunks"]?.arrayValue else {
                continue
            }

            var chunks: [ProposalChunkPayload] = []
            for chunkVal in chunksArr {
                guard let chunkObj = chunkVal.objectValue,
                      let targetLine = chunkObj["targetLine"]?.intValue,
                      let targetCol = chunkObj["targetCol"]?.intValue,
                      let linesArr = chunkObj["lines"]?.arrayValue else {
                    continue
                }
                let lines = linesArr.compactMap { $0.stringValue }
                let insertMode = chunkObj["insertMode"]?.stringValue
                chunks.append(ProposalChunkPayload(targetLine: targetLine, targetCol: targetCol, lines: lines, insertMode: insertMode))
            }
            affectedFiles.append(AffectedFilePayload(filePath: filePath, chunks: chunks))
        }

        guard let success = target?.handleShowPreview(clientId: clientId, reason: reason, affectedFiles: affectedFiles), success else {
            return JSONRPCResponse.failure(code: 409, message: "Failed to push proposal into queue or depth limit exceeded", id: request.id)
        }

        let resObj: [String: JSONValue] = [
            "success": .bool(true),
            "previewActive": .bool(true)
        ]
        return JSONRPCResponse.success(result: .object(resObj), id: request.id)
    }

    private func processExecuteLogo(_ request: JSONRPCRequest) -> JSONRPCResponse {
        guard let paramsObj = request.params?.objectValue,
              let script = paramsObj["script"]?.stringValue else {
            return JSONRPCResponse.failure(code: -32602, message: "Missing script parameter", id: request.id)
        }

        let auth = paramsObj["auth"]?.stringValue
        guard isAuthValid(auth) else {
            return JSONRPCResponse.failure(code: 401, message: "Unauthorized: Invalid auth token", id: request.id)
        }

        let mode = paramsObj["mode"]?.stringValue
        guard let res = target?.handleExecuteLogo(script: script, mode: mode) else {
            return JSONRPCResponse.failure(code: 500, message: "Logo execution error", id: request.id)
        }

        var resObj: [String: JSONValue] = [
            "success": .bool(res.success),
            "lastResult": .string(res.result)
        ]
        if let err = res.error {
            resObj["error"] = .string(err)
        }

        return JSONRPCResponse.success(result: .object(resObj), id: request.id)
    }

    private func processGetHistory(_ request: JSONRPCRequest) -> JSONRPCResponse {
        let paramsObj = request.params?.objectValue
        let limit = paramsObj?["limit"]?.intValue ?? 20

        let entries = target?.handleGetHistory(limit: limit) ?? []
        let resObj: [String: JSONValue] = [
            "entries": .array(entries)
        ]
        return JSONRPCResponse.success(result: .object(resObj), id: request.id)
    }
}

extension JSONRPCHandler: ZagoIPCServerDelegate {
    public func ipcServer(_ server: ZagoIPCServer, didReceiveRequest request: JSONRPCRequest, connectionId: String) -> JSONRPCResponse {
        handleRequest(request, connectionId: connectionId)
    }

    public func ipcServer(_ server: ZagoIPCServer, clientDidDisconnect connectionId: String) {
        unregisterClient(connectionId: connectionId)
    }
}
