import Config
import Foundation

public final class ZagoMCPServer {
    private enum State {
        case awaitingInitialize
        case awaitingInitializedNotification
        case ready
    }

    private enum Method: String {
        case initialize
        case initialized = "notifications/initialized"
        case ping
        case toolsList = "tools/list"
        case toolsCall = "tools/call"
    }

    private enum ToolName: String, Codable {
        case listInstances = "zago_list_instances"
        case selectInstance = "zago_select_instance"
        case overlayPreview = "zago_overlay_preview"
        case executeLogo = "zago_execute_logo"
        case getBuffers = "zago_get_buffers"
        case getText = "zago_get_text"
        case getCursor = "zago_get_cursor"
    }

    private struct RequestEnvelope: Decodable {
        let jsonrpc: String?
        let method: String
        let id: JSONRPCId?
    }

    private struct Request<Params: Decodable>: Decodable {
        let params: Params?
    }

    private struct InitializeParams: Decodable {
        let protocolVersion: String?
    }

    private struct ToolCallHeader: Decodable {
        struct Params: Decodable {
            let name: String
        }

        let params: Params
    }

    private struct ToolCall<Arguments: Decodable>: Decodable {
        struct Params: Decodable {
            let name: ToolName
            let arguments: Arguments?
        }

        let params: Params
    }

    private struct SelectInstanceArguments: Codable {
        let instanceId: String
    }

    private struct PreviewArguments: Codable {
        let lines: [String]
        let targetLine: Int?
        let targetCol: Int?
        let reason: String?
        let insertMode: String?
    }

    private struct ExecuteLogoArguments: Codable {
        let script: String
    }

    private struct GetTextArguments: Codable {
        let bufferTarget: String?
        let startLine: Int?
        let endLine: Int?
    }

    private struct GetCursorArguments: Codable {
        let bufferTarget: String?
    }

    private struct EmptyArguments: Codable {}

    private struct Response<Result: Encodable>: Encodable {
        let jsonrpc = "2.0"
        let result: Result
        let id: JSONRPCId?
    }

    private struct FailureResponse: Encodable {
        struct Failure: Encodable {
            let code: Int
            let message: String
        }

        let jsonrpc = "2.0"
        let error: Failure
        let id: JSONRPCId?
    }

    private struct EmptyResult: Codable {}

    private struct InitializeResult: Encodable {
        struct Capabilities: Encodable {
            let tools = EmptyResult()
        }

        struct ServerInfo: Encodable {
            let name: String
            let version: String
        }

        let protocolVersion: String
        let capabilities = Capabilities()
        let serverInfo = ServerInfo(name: "zago", version: ZagoVersion.current)
    }

    private enum SchemaType: String, Encodable {
        case object
        case string
        case integer
        case array
    }

    private struct ArrayItemSchema: Encodable {
        let type: SchemaType
    }

    private struct PropertySchema: Encodable {
        let type: SchemaType
        let description: String
        let items: ArrayItemSchema?
        let allowedValues: [String]?

        enum CodingKeys: String, CodingKey {
            case type
            case description
            case items
            case allowedValues = "enum"
        }

        init(
            type: SchemaType,
            description: String,
            items: ArrayItemSchema? = nil,
            allowedValues: [String]? = nil
        ) {
            self.type = type
            self.description = description
            self.items = items
            self.allowedValues = allowedValues
        }
    }

    private struct InputSchema: Encodable {
        let type = SchemaType.object
        let properties: [String: PropertySchema]
        let required: [String]?

        init(properties: [String: PropertySchema] = [:], required: [String]? = nil) {
            self.properties = properties
            self.required = required
        }
    }

    private struct ToolAnnotations: Encodable {
        let readOnlyHint: Bool
        let destructiveHint: Bool
        let idempotentHint: Bool
        let openWorldHint = false
    }

    private struct Tool: Encodable {
        let name: ToolName
        let description: String
        let inputSchema: InputSchema
        let annotations: ToolAnnotations
    }

    private struct ToolListResult: Encodable {
        let tools: [Tool]
    }

    private struct ToolResult: Encodable {
        struct Content: Encodable {
            let type = "text"
            let text: String
        }

        let content: [Content]
        let isError: Bool?

        init(text: String, isError: Bool) {
            content = [Content(text: text)]
            self.isError = isError ? true : nil
        }
    }

    private struct InstanceDescription: Encodable {
        let instanceId: String
        let endpointPath: String
        let isSelected: Bool
        let buffers: IPCBuffersResult
    }

    private static let supportedProtocolVersions = [
        "2025-11-25",
        "2025-06-18",
        "2025-03-26",
        "2024-11-05",
    ]

    private static let tools: [Tool] = [
        Tool(
            name: .listInstances,
            description: "List running zago editor instances and their open buffers.",
            inputSchema: InputSchema(),
            annotations: ToolAnnotations(
                readOnlyHint: true,
                destructiveHint: false,
                idempotentHint: true
            )
        ),
        Tool(
            name: .selectInstance,
            description: "Select the exact zago editor instance targeted by later calls.",
            inputSchema: InputSchema(
                properties: [
                    "instanceId": PropertySchema(
                        type: .string,
                        description: "An instance ID returned by zago_list_instances."
                    )
                ],
                required: ["instanceId"]
            ),
            annotations: ToolAnnotations(
                readOnlyHint: false,
                destructiveHint: false,
                idempotentHint: true
            )
        ),
        Tool(
            name: .overlayPreview,
            description: "Show a ghost-text proposal in the active zago buffer.",
            inputSchema: InputSchema(
                properties: [
                    "lines": PropertySchema(
                        type: .array,
                        description: "Text lines to preview.",
                        items: ArrayItemSchema(type: .string)
                    ),
                    "targetLine": PropertySchema(
                        type: .integer,
                        description: "One-based target line. Defaults to 1."
                    ),
                    "targetCol": PropertySchema(
                        type: .integer,
                        description: "One-based target column. Defaults to 1."
                    ),
                    "reason": PropertySchema(
                        type: .string,
                        description: "Short explanation shown with the proposal."
                    ),
                    "insertMode": PropertySchema(
                        type: .string,
                        description: "How the proposal is applied.",
                        allowedValues: [
                            "1d_insert",
                            "1d_overwrite",
                            "2d_insert",
                            "2d_overwrite",
                            "2d_transparent",
                            "2d_fuse_corners",
                        ]
                    ),
                ],
                required: ["lines"]
            ),
            annotations: ToolAnnotations(
                readOnlyHint: false,
                destructiveHint: false,
                idempotentHint: false
            )
        ),
        Tool(
            name: .executeLogo,
            description: "Execute Editor LOGO in the active zago buffer.",
            inputSchema: InputSchema(
                properties: [
                    "script": PropertySchema(
                        type: .string,
                        description: "Editor LOGO source code to execute."
                    )
                ],
                required: ["script"]
            ),
            annotations: ToolAnnotations(
                readOnlyHint: false,
                destructiveHint: true,
                idempotentHint: false
            )
        ),
        Tool(
            name: .getBuffers,
            description: "Get all open buffers in the selected zago editor.",
            inputSchema: InputSchema(),
            annotations: ToolAnnotations(
                readOnlyHint: true,
                destructiveHint: false,
                idempotentHint: true
            )
        ),
        Tool(
            name: .getText,
            description: "Get text from the active or specified zago buffer.",
            inputSchema: InputSchema(
                properties: [
                    "bufferTarget": PropertySchema(
                        type: .string,
                        description: "Buffer ID or path. Defaults to the active buffer."
                    ),
                    "startLine": PropertySchema(
                        type: .integer,
                        description: "Optional one-based first line."
                    ),
                    "endLine": PropertySchema(
                        type: .integer,
                        description: "Optional one-based last line."
                    ),
                ]
            ),
            annotations: ToolAnnotations(
                readOnlyHint: true,
                destructiveHint: false,
                idempotentHint: true
            )
        ),
        Tool(
            name: .getCursor,
            description: "Get the cursor position in the active or specified zago buffer.",
            inputSchema: InputSchema(
                properties: [
                    "bufferTarget": PropertySchema(
                        type: .string,
                        description: "Buffer ID or path. Defaults to the active buffer."
                    )
                ]
            ),
            annotations: ToolAnnotations(
                readOnlyHint: true,
                destructiveHint: false,
                idempotentHint: true
            )
        ),
    ]

    private let sessionLocator: any ZagoIPCSessionLocating
    private let ipcClient: ZagoIPCClient
    private var state = State.awaitingInitialize
    private var selectedInstanceId: String?

    public convenience init() {
        self.init(
            sessionLocator: DefaultZagoIPCSessionLocator(),
            ipcClient: ZagoIPCClient()
        )
    }

    init(
        sessionLocator: any ZagoIPCSessionLocating,
        ipcClient: ZagoIPCClient = ZagoIPCClient()
    ) {
        self.sessionLocator = sessionLocator
        self.ipcClient = ipcClient
    }

    public func runStdioServer() {
        while let line = readLine() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if let response = handleLine(trimmed) {
                print(response)
                fflush(stdout)
            }
        }
    }

    public func handleLine(_ line: String) -> String? {
        guard let data = line.data(using: .utf8) else {
            return failure(id: nil, code: -32700, message: "Parse error")
        }

        let envelope: RequestEnvelope
        do {
            envelope = try JSONDecoder().decode(RequestEnvelope.self, from: data)
        } catch {
            return failure(id: nil, code: -32700, message: "Parse error")
        }
        guard envelope.jsonrpc == "2.0" else {
            return failure(id: envelope.id, code: -32600, message: "Invalid Request")
        }
        guard let method = Method(rawValue: envelope.method) else {
            return failure(
                id: envelope.id,
                code: -32601,
                message: "Method not found: \(envelope.method)"
            )
        }

        switch method {
        case .initialize:
            let params = try? JSONDecoder().decode(Request<InitializeParams>.self, from: data).params
            let requestedVersion = params?.protocolVersion
            let protocolVersion = requestedVersion.flatMap {
                Self.supportedProtocolVersions.contains($0) ? $0 : nil
            } ?? Self.supportedProtocolVersions[0]
            state = .awaitingInitializedNotification
            return success(
                id: envelope.id,
                result: InitializeResult(protocolVersion: protocolVersion)
            )

        case .initialized:
            if state == .awaitingInitializedNotification {
                state = .ready
            }
            return nil

        case .ping:
            return success(id: envelope.id, result: EmptyResult())

        case .toolsList:
            guard state == .ready else { return notInitialized(id: envelope.id) }
            return success(id: envelope.id, result: ToolListResult(tools: Self.tools))

        case .toolsCall:
            guard state == .ready else { return notInitialized(id: envelope.id) }
            return handleToolCall(data: data, id: envelope.id)
        }
    }

    private func handleToolCall(data: Data, id: JSONRPCId?) -> String {
        let header: ToolCallHeader
        do {
            header = try JSONDecoder().decode(ToolCallHeader.self, from: data)
        } catch {
            return failure(id: id, code: -32602, message: "Invalid tools/call params")
        }
        guard let toolName = ToolName(rawValue: header.params.name) else {
            return failure(id: id, code: -32602, message: "Unknown tool: \(header.params.name)")
        }

        do {
            switch toolName {
            case .listInstances:
                _ = try decodeArguments(EmptyArguments.self, from: data)
                return try listInstances(id: id)

            case .selectInstance:
                let arguments = try decodeArguments(SelectInstanceArguments.self, from: data)
                return try selectInstance(arguments.instanceId, id: id)

            case .overlayPreview:
                let arguments = try decodeArguments(PreviewArguments.self, from: data)
                let chunk = ProposalChunkPayload(
                    targetLine: arguments.targetLine ?? 1,
                    targetCol: arguments.targetCol ?? 1,
                    lines: arguments.lines,
                    insertMode: arguments.insertMode ?? "2d_insert"
                )
                let result = try ipcClient.showPreview(
                    reason: arguments.reason ?? "AI proposal overlay",
                    affectedFiles: [AffectedFilePayload(filePath: "active", chunks: [chunk])],
                    in: try activeSession()
                )
                return toolSuccess(id: id, value: result)

            case .executeLogo:
                let arguments = try decodeArguments(ExecuteLogoArguments.self, from: data)
                let result = try ipcClient.executeLogo(
                    script: arguments.script,
                    in: try activeSession()
                )
                return toolSuccess(id: id, value: result)

            case .getBuffers:
                _ = try decodeArguments(EmptyArguments.self, from: data)
                return toolSuccess(
                    id: id,
                    value: try ipcClient.getBuffers(in: try activeSession())
                )

            case .getText:
                let arguments = try decodeArguments(GetTextArguments.self, from: data)
                let result = try ipcClient.getText(
                    bufferTarget: arguments.bufferTarget,
                    startLine: arguments.startLine,
                    endLine: arguments.endLine,
                    in: try activeSession()
                )
                return toolSuccess(id: id, value: result)

            case .getCursor:
                let arguments = try decodeArguments(GetCursorArguments.self, from: data)
                let result = try ipcClient.getCursor(
                    bufferTarget: arguments.bufferTarget,
                    in: try activeSession()
                )
                return toolSuccess(id: id, value: result)
            }
        } catch let error as DecodingError {
            return failure(
                id: id,
                code: -32602,
                message: "Invalid arguments for \(toolName.rawValue): \(error.localizedDescription)"
            )
        } catch {
            return toolFailure(id: id, error: error)
        }
    }

    private func decodeArguments<Arguments: Decodable>(
        _ type: Arguments.Type,
        from data: Data
    ) throws -> Arguments {
        let request = try JSONDecoder().decode(ToolCall<Arguments>.self, from: data)
        if let arguments = request.params.arguments {
            return arguments
        }
        return try JSONDecoder().decode(Arguments.self, from: Data("{}".utf8))
    }

    private func listInstances(id: JSONRPCId?) throws -> String {
        let descriptions = sessionLocator.sessions().compactMap { session -> InstanceDescription? in
            guard let buffers = try? ipcClient.getBuffers(in: session) else { return nil }
            return InstanceDescription(
                instanceId: session.instanceId,
                endpointPath: session.endpointPath,
                isSelected: selectedInstanceId == session.instanceId,
                buffers: buffers
            )
        }
        guard !descriptions.isEmpty else {
            throw ZagoIPCClientError.noActiveSession
        }
        return toolSuccess(id: id, value: descriptions)
    }

    private func selectInstance(_ instanceId: String, id: JSONRPCId?) throws -> String {
        guard sessionLocator.sessions().contains(where: { $0.instanceId == instanceId }) else {
            throw ZagoIPCClientError.selectedSessionUnavailable(instanceId)
        }
        selectedInstanceId = instanceId
        return success(
            id: id,
            result: ToolResult(text: "Selected zago instance '\(instanceId)'.", isError: false)
        )
    }

    private func activeSession() throws -> ZagoIPCSession {
        let sessions = sessionLocator.sessions()
        if let selectedInstanceId {
            guard let selected = sessions.first(where: { $0.instanceId == selectedInstanceId })
            else {
                throw ZagoIPCClientError.selectedSessionUnavailable(selectedInstanceId)
            }
            return selected
        }
        guard let session = sessions.first else {
            throw ZagoIPCClientError.noActiveSession
        }
        return session
    }

    private func toolSuccess<Value: Encodable>(id: JSONRPCId?, value: Value) -> String {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(value)
            guard let text = String(data: data, encoding: .utf8) else {
                throw ZagoIPCClientError.invalidResponse
            }
            return success(id: id, result: ToolResult(text: text, isError: false))
        } catch {
            return toolFailure(id: id, error: error)
        }
    }

    private func toolFailure(id: JSONRPCId?, error: Error) -> String {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        return success(id: id, result: ToolResult(text: message, isError: true))
    }

    private func notInitialized(id: JSONRPCId?) -> String {
        failure(id: id, code: -32002, message: "Server is not initialized")
    }

    private func success<Result: Encodable>(id: JSONRPCId?, result: Result) -> String {
        encode(Response(result: result, id: id))
    }

    private func failure(id: JSONRPCId?, code: Int, message: String) -> String {
        encode(FailureResponse(error: .init(code: code, message: message), id: id))
    }

    private func encode<Value: Encodable>(_ value: Value) -> String {
        do {
            let data = try JSONEncoder().encode(value)
            return String(data: data, encoding: .utf8)
                ?? #"{"jsonrpc":"2.0","error":{"code":-32603,"message":"Internal error"}}"#
        } catch {
            return #"{"jsonrpc":"2.0","error":{"code":-32603,"message":"Internal error"}}"#
        }
    }
}
