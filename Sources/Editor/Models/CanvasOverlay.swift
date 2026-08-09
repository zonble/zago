import Foundation

public enum OverlayInsertMode: String, Codable, Equatable, Sendable {
    case d1Insert = "1d_insert"
    case d1Overwrite = "1d_overwrite"
    case d2Insert = "2d_insert"
    case d2Overwrite = "2d_overwrite"
    case d2Transparent = "2d_transparent"
    case d2FuseCorners = "2d_fuse_corners"

    public static func parse(_ raw: String?) -> OverlayInsertMode {
        guard let raw else { return .d2Overwrite }
        switch raw.lowercased() {
        case "1d_insert", "insert": return .d1Insert
        case "1d_overwrite": return .d1Overwrite
        case "2d_insert": return .d2Insert
        case "2d_overwrite", "overwrite": return .d2Overwrite
        case "2d_transparent", "transparent": return .d2Transparent
        case "2d_fuse_corners", "fuse_corners": return .d2FuseCorners
        default: return .d2Overwrite
        }
    }
}

public struct ProposalChunk: Codable, Equatable, Sendable {
    public var targetLine: Int
    public var targetCol: Int
    public var lines: [String]
    public var insertMode: OverlayInsertMode

    public init(targetLine: Int, targetCol: Int, lines: [String], insertMode: OverlayInsertMode = .d2Overwrite) {
        self.targetLine = targetLine
        self.targetCol = targetCol
        self.lines = lines
        self.insertMode = insertMode
    }
}

public struct AffectedFileProposal: Codable, Equatable, Sendable {
    public var filePath: String?
    public var bufferId: String?
    public var chunks: [ProposalChunk]

    public init(filePath: String? = nil, bufferId: String? = nil, chunks: [ProposalChunk]) {
        self.filePath = filePath
        self.bufferId = bufferId
        self.chunks = chunks
    }
}

public struct AIProposal: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let clientId: String
    public let clientName: String
    public let clientColor: String
    public let reason: String
    public var affectedFiles: [AffectedFileProposal]
    public let timestamp: Date

    public init(
        id: String = "prop-\(UUID().uuidString.prefix(8))",
        clientId: String,
        clientName: String,
        clientColor: String = "cyan",
        reason: String,
        affectedFiles: [AffectedFileProposal],
        timestamp: Date = Date()
    ) {
        self.id = id
        self.clientId = clientId
        self.clientName = clientName
        self.clientColor = clientColor
        self.reason = reason
        self.affectedFiles = affectedFiles
        self.timestamp = timestamp
    }
}

public struct CanvasOverlay: Equatable, Sendable {
    public var activeProposal: AIProposal?
    public var currentChunkIndex: Int = 0

    public init(activeProposal: AIProposal? = nil, currentChunkIndex: Int = 0) {
        self.activeProposal = activeProposal
        self.currentChunkIndex = currentChunkIndex
    }

    public var isVisible: Bool {
        activeProposal != nil
    }
}
