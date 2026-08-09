import Foundation

// MARK: - JSON-RPC 2.0 Core DTOs

public struct JSONRPCRequest: Codable {
    public let jsonrpc: String?
    public let method: String
    public let params: JSONValue?
    public let id: JSONRPCId?

    public init(method: String, params: JSONValue? = nil, id: JSONRPCId? = nil) {
        self.jsonrpc = "2.0"
        self.method = method
        self.params = params
        self.id = id
    }
}

public struct JSONRPCResponse: Codable {
    public let jsonrpc: String
    public let result: JSONValue?
    public let error: JSONRPCError?
    public let id: JSONRPCId?

    public init(result: JSONValue? = nil, error: JSONRPCError? = nil, id: JSONRPCId? = nil) {
        self.jsonrpc = "2.0"
        self.result = result
        self.error = error
        self.id = id
    }

    public static func success(result: JSONValue, id: JSONRPCId?) -> JSONRPCResponse {
        JSONRPCResponse(result: result, error: nil, id: id)
    }

    public static func failure(code: Int, message: String, data: JSONValue? = nil, id: JSONRPCId?) -> JSONRPCResponse {
        JSONRPCResponse(result: nil, error: JSONRPCError(code: code, message: message, data: data), id: id)
    }
}

public struct JSONRPCError: Codable, Error {
    public let code: Int
    public let message: String
    public let data: JSONValue?

    public init(code: Int, message: String, data: JSONValue? = nil) {
        self.code = code
        self.message = message
        self.data = data
    }
}

public enum JSONRPCId: Codable, Equatable, Hashable {
    case string(String)
    case int(Int)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let val = try? container.decode(Int.self) {
            self = .int(val)
        } else if let val = try? container.decode(String.self) {
            self = .string(val)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid JSONRPCId")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let val): try container.encode(val)
        case .int(let val): try container.encode(val)
        }
    }
}

// MARK: - Dynamic JSON Value

public indirect enum JSONValue: Codable, Equatable {
    case null
    case bool(Bool)
    case number(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let val = try? container.decode(Bool.self) {
            self = .bool(val)
        } else if let val = try? container.decode(Double.self) {
            self = .number(val)
        } else if let val = try? container.decode(String.self) {
            self = .string(val)
        } else if let val = try? container.decode([JSONValue].self) {
            self = .array(val)
        } else if let val = try? container.decode([String: JSONValue].self) {
            self = .object(val)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid JSONValue")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let val): try container.encode(val)
        case .number(let val): try container.encode(val)
        case .string(let val): try container.encode(val)
        case .array(let val): try container.encode(val)
        case .object(let val): try container.encode(val)
        }
    }

    public var stringValue: String? {
        if case .string(let str) = self { return str }
        return nil
    }

    public var intValue: Int? {
        if case .number(let num) = self { return Int(num) }
        return nil
    }

    public var boolValue: Bool? {
        if case .bool(let b) = self { return b }
        return nil
    }

    public var objectValue: [String: JSONValue]? {
        if case .object(let dict) = self { return dict }
        return nil
    }

    public var arrayValue: [JSONValue]? {
        if case .array(let arr) = self { return arr }
        return nil
    }
}

// MARK: - Method Payload DTOs

public struct ClientRegistrationParams: Codable {
    public let auth: String?
    public let clientId: String
    public let clientName: String
    public let agentType: String?
    public let color: String?
}

public struct ProposalChunkPayload: Codable {
    public let targetLine: Int
    public let targetCol: Int
    public let lines: [String]
    public let insertMode: String? // "1d_insert", "1d_overwrite", "2d_insert", "2d_overwrite", "2d_transparent", "2d_fuse_corners"
}

public struct AffectedFilePayload: Codable {
    public let filePath: String
    public let chunks: [ProposalChunkPayload]
}

public struct OverlayPreviewParams: Codable {
    public let auth: String?
    public let clientId: String
    public let reason: String
    public let affectedFiles: [AffectedFilePayload]
}
