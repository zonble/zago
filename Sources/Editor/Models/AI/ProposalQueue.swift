import Foundation

final class ProposalQueue: @unchecked Sendable {
    static let defaultMaxDepth = 50
    private(set) var pendingProposals: [AIProposal] = []
    private(set) var activeIndex: Int = 0
    private(set) var activeChunkIndex: Int = 0
    private let lock = NSLock()
    let maxDepth: Int

    init(maxDepth: Int = ProposalQueue.defaultMaxDepth) {
        self.maxDepth = max(1, maxDepth)
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return pendingProposals.count
    }

    var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return pendingProposals.isEmpty
    }

    var currentProposal: AIProposal? {
        lock.lock()
        defer { lock.unlock() }
        guard activeIndex >= 0 && activeIndex < pendingProposals.count else { return nil }
        return pendingProposals[activeIndex]
    }

    @discardableResult
    func pushProposal(_ proposal: AIProposal) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard pendingProposals.count < maxDepth else { return false }
        pendingProposals.append(proposal)
        activeIndex = pendingProposals.count - 1
        activeChunkIndex = 0
        return true
    }

    func nextProposal() {
        lock.lock()
        defer { lock.unlock() }
        guard !pendingProposals.isEmpty else { return }
        activeIndex = (activeIndex + 1) % pendingProposals.count
        activeChunkIndex = 0
    }

    func previousProposal() {
        lock.lock()
        defer { lock.unlock() }
        guard !pendingProposals.isEmpty else { return }
        activeIndex = (activeIndex - 1 + pendingProposals.count) % pendingProposals.count
        activeChunkIndex = 0
    }

    func nextChunk() {
        lock.lock()
        defer { lock.unlock() }
        guard activeIndex >= 0 && activeIndex < pendingProposals.count else { return }
        let current = pendingProposals[activeIndex]
        let totalChunks = current.affectedFiles.flatMap { $0.chunks }.count
        guard totalChunks > 0 else { return }
        activeChunkIndex = (activeChunkIndex + 1) % totalChunks
    }

    func previousChunk() {
        lock.lock()
        defer { lock.unlock() }
        guard activeIndex >= 0 && activeIndex < pendingProposals.count else { return }
        let current = pendingProposals[activeIndex]
        let totalChunks = current.affectedFiles.flatMap { $0.chunks }.count
        guard totalChunks > 0 else { return }
        activeChunkIndex = (activeChunkIndex - 1 + totalChunks) % totalChunks
    }

    @discardableResult
    func rejectCurrent() -> AIProposal? {
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

    func rejectAll() {
        lock.lock()
        defer { lock.unlock() }
        pendingProposals.removeAll()
        activeIndex = 0
        activeChunkIndex = 0
    }

    /// Removes previews whose originating IPC connection has gone away.
    @discardableResult
    func removeProposals(clientId: String) -> Int {
        lock.lock()
        defer { lock.unlock() }
        let originalCount = pendingProposals.count
        pendingProposals.removeAll { $0.clientId == clientId }
        activeIndex = pendingProposals.isEmpty ? 0 : min(activeIndex, pendingProposals.count - 1)
        activeChunkIndex = 0
        return originalCount - pendingProposals.count
    }

    /// Automatically shifts targetLine of pending proposals when user edits lines above proposal sites.
    func adjustLineOffsets(aboveLine: Int, delta: Int) {
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
