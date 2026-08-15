import Foundation

public struct AIHistoryEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let timestamp: Date
    public let clientId: String
    public let clientName: String
    public let reason: String
    public let affectedFiles: [AffectedFileProposal]
    public let decision: String // "accepted", "rejected", "undone"

    public init(
        id: String = "hist-\(UUID().uuidString.prefix(8))",
        timestamp: Date = Date(),
        clientId: String,
        clientName: String,
        reason: String,
        affectedFiles: [AffectedFileProposal],
        decision: String
    ) {
        self.id = id
        self.timestamp = timestamp
        self.clientId = clientId
        self.clientName = clientName
        self.reason = reason
        self.affectedFiles = affectedFiles
        self.decision = decision
    }
}

final class AIHistoryLogManager: @unchecked Sendable {
    static let shared = AIHistoryLogManager()

    private(set) var entries: [AIHistoryEntry] = []
    private let lock = NSLock()

    private init() {}

    func logDecision(proposal: AIProposal, decision: String) {
        lock.lock()
        defer { lock.unlock() }

        let entry = AIHistoryEntry(
            id: proposal.id,
            timestamp: Date(),
            clientId: proposal.clientId,
            clientName: proposal.clientName,
            reason: proposal.reason,
            affectedFiles: proposal.affectedFiles,
            decision: decision
        )
        entries.insert(entry, at: 0)
        if entries.count > 200 {
            entries.removeLast()
        }
    }

    func recentEntries(limit: Int = 20) -> [AIHistoryEntry] {
        lock.lock()
        defer { lock.unlock() }
        return Array(entries.prefix(limit))
    }
}
