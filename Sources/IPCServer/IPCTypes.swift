import Foundation

// MARK: - JSON-RPC envelopes

struct JSONRPCEnvelope: Decodable {
    let jsonrpc: String?
    let method: String
    let id: JSONRPCId?
}

struct JSONRPCRequest<Params: Decodable>: Decodable {
    let jsonrpc: String?
    let method: String
    let params: Params?
    let id: JSONRPCId?
}

struct JSONRPCSuccessEnvelope<Result: Encodable>: Encodable {
    let jsonrpc = "2.0"
    let result: Result
    let id: JSONRPCId?
}

struct JSONRPCFailureEnvelope: Encodable {
    let jsonrpc = "2.0"
    let error: JSONRPCError
    let id: JSONRPCId?
}

struct JSONRPCError: Codable, Error {
    let code: Int
    let message: String
}

enum JSONRPCId: Codable, Equatable, Hashable {
    case string(String)
    case int(Int)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid JSON-RPC id")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        }
    }
}

// MARK: - Method payloads

struct EmptyParams: Decodable {}

struct ClientRegistrationParams: Decodable {
    let auth: String
    let clientId: String
    let clientName: String
    let agentType: String?
    let color: String?
}

struct GetTextParams: Decodable {
    let bufferTarget: String?
    let bufferId: String?
    let startLine: Int?
    let endLine: Int?
}

struct GetCursorParams: Decodable {
    let bufferTarget: String?
    let bufferId: String?
}

public struct ProposalChunkPayload: Codable, Sendable {
    public let targetLine: Int
    public let targetCol: Int
    public let lines: [String]
    public let insertMode: String?
    public let type: String?

    public init(targetLine: Int, targetCol: Int, lines: [String], insertMode: String? = nil, type: String? = nil) {
        self.targetLine = targetLine
        self.targetCol = targetCol
        self.lines = lines
        self.insertMode = insertMode
        self.type = type
    }
}

public struct AffectedFilePayload: Codable, Sendable {
    public let filePath: String?
    public let bufferId: String?
    public let chunks: [ProposalChunkPayload]

    public init(filePath: String? = nil, bufferId: String? = nil, chunks: [ProposalChunkPayload]) {
        self.filePath = filePath
        self.bufferId = bufferId
        self.chunks = chunks
    }
}

struct OverlayPreviewParams: Decodable {
    let clientId: String
    let reason: String
    let affectedFiles: [AffectedFilePayload]
}

struct ExecuteLogoParams: Decodable {
    let script: String
    let mode: String?
}

struct HistoryParams: Decodable {
    let limit: Int?
}
