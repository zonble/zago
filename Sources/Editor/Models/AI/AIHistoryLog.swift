import Foundation

public enum AIProposalDecision: String, Codable, Equatable, Sendable, CaseIterable {
    case accepted
    case rejected
    case undone
}

public struct AIHistoryEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let timestamp: Date
    public let clientId: String
    public let clientName: String
    public let reason: String
    public let affectedFiles: [AffectedFileProposal]
    public let decision: AIProposalDecision

    public var decisionString: String {
        decision.rawValue
    }

    public init(
        id: String = "hist-\(UUID().uuidString.prefix(8))",
        timestamp: Date = Date(),
        clientId: String,
        clientName: String,
        reason: String,
        affectedFiles: [AffectedFileProposal],
        decision: AIProposalDecision
    ) {
        self.id = id
        self.timestamp = timestamp
        self.clientId = clientId
        self.clientName = clientName
        self.reason = reason
        self.affectedFiles = affectedFiles
        self.decision = decision
    }

    public init(
        id: String = "hist-\(UUID().uuidString.prefix(8))",
        timestamp: Date = Date(),
        clientId: String,
        clientName: String,
        reason: String,
        affectedFiles: [AffectedFileProposal],
        decision: String
    ) {
        self.init(
            id: id,
            timestamp: timestamp,
            clientId: clientId,
            clientName: clientName,
            reason: reason,
            affectedFiles: affectedFiles,
            decision: AIProposalDecision(rawValue: decision) ?? .undone
        )
    }
}

public protocol AIHistoryStoring: AnyObject, Sendable {
    var entries: [AIHistoryEntry] { get }
    func logDecision(proposal: AIProposal, decision: AIProposalDecision)
    func logDecision(proposal: AIProposal, decision: String)
    func recentEntries(limit: Int) -> [AIHistoryEntry]
    func clear()
}

public final class InMemoryAIHistoryStore: AIHistoryStoring, @unchecked Sendable {
    public private(set) var entries: [AIHistoryEntry] = []
    private let lock = NSLock()
    private let maxEntries: Int

    public init(maxEntries: Int = 200) {
        self.maxEntries = maxEntries
    }

    public func logDecision(proposal: AIProposal, decision: AIProposalDecision) {
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
        if entries.count > maxEntries {
            entries.removeLast()
        }
    }

    public func logDecision(proposal: AIProposal, decision: String) {
        logDecision(proposal: proposal, decision: AIProposalDecision(rawValue: decision) ?? .undone)
    }

    public func recentEntries(limit: Int = 20) -> [AIHistoryEntry] {
        lock.lock()
        defer { lock.unlock() }
        return Array(entries.prefix(limit))
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        entries.removeAll()
    }
}

public typealias AIHistoryStore = InMemoryAIHistoryStore
public typealias AIHistoryLogManager = InMemoryAIHistoryStore
