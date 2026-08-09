import Foundation

public final class ProposalQueue: @unchecked Sendable {
    public private(set) var pendingProposals: [AIProposal] = []
    public private(set) var activeIndex: Int = 0
    public private(set) var activeChunkIndex: Int = 0
    private let lock = NSLock()

    public init() {}

    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return pendingProposals.count
    }

    public var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return pendingProposals.isEmpty
    }

    public var currentProposal: AIProposal? {
        lock.lock()
        defer { lock.unlock() }
        guard activeIndex >= 0 && activeIndex < pendingProposals.count else { return nil }
        return pendingProposals[activeIndex]
    }

    public func pushProposal(_ proposal: AIProposal) {
        lock.lock()
        defer { lock.unlock() }
        pendingProposals.append(proposal)
        if pendingProposals.count == 1 {
            activeIndex = 0
            activeChunkIndex = 0
        }
    }

    public func nextProposal() {
        lock.lock()
        defer { lock.unlock() }
        guard !pendingProposals.isEmpty else { return }
        activeIndex = (activeIndex + 1) % pendingProposals.count
        activeChunkIndex = 0
    }

    public func previousProposal() {
        lock.lock()
        defer { lock.unlock() }
        guard !pendingProposals.isEmpty else { return }
        activeIndex = (activeIndex - 1 + pendingProposals.count) % pendingProposals.count
        activeChunkIndex = 0
    }

    public func nextChunk() {
        lock.lock()
        defer { lock.unlock() }
        guard activeIndex >= 0 && activeIndex < pendingProposals.count else { return }
        let current = pendingProposals[activeIndex]
        let totalChunks = current.affectedFiles.flatMap { $0.chunks }.count
        guard totalChunks > 0 else { return }
        activeChunkIndex = (activeChunkIndex + 1) % totalChunks
    }

    public func previousChunk() {
        lock.lock()
        defer { lock.unlock() }
        guard activeIndex >= 0 && activeIndex < pendingProposals.count else { return }
        let current = pendingProposals[activeIndex]
        let totalChunks = current.affectedFiles.flatMap { $0.chunks }.count
        guard totalChunks > 0 else { return }
        activeChunkIndex = (activeChunkIndex - 1 + totalChunks) % totalChunks
    }

    @discardableResult
    public func rejectCurrent() -> AIProposal? {
        lock.lock()
        defer { lock.unlock() }
        guard activeIndex >= 0 && activeIndex < pendingProposals.count else { return nil }
        let rejected = pendingProposals.remove(at: activeIndex)
        if activeIndex >= pendingProposals.count {
            activeIndex = max(0, pendingProposals.count - 1)
        }
        activeChunkIndex = 0
        return rejected
    }

    public func rejectAll() {
        lock.lock()
        defer { lock.unlock() }
        pendingProposals.removeAll()
        activeIndex = 0
        activeChunkIndex = 0
    }

    /// Automatically shifts targetLine of pending proposals when user edits lines above proposal sites.
    public func adjustLineOffsets(aboveLine: Int, delta: Int) {
        lock.lock()
        defer { lock.unlock() }
        for pIndex in 0..<pendingProposals.count {
            for fIndex in 0..<pendingProposals[pIndex].affectedFiles.count {
                for cIndex in 0..<pendingProposals[pIndex].affectedFiles[fIndex].chunks.count {
                    let targetLine = pendingProposals[pIndex].affectedFiles[fIndex].chunks[cIndex].targetLine
                    if targetLine >= aboveLine {
                        pendingProposals[pIndex].affectedFiles[fIndex].chunks[cIndex].targetLine = max(1, targetLine + delta)
                    }
                }
            }
        }
    }
}
