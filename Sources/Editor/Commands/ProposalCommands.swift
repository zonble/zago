import Foundation

public struct AcceptProposalCommand: Command {
    public let id: CommandID = .proposalAccept
    public let name = "Accept AI Proposal"
    public let description = "Accept current AI proposal and apply changes to text buffer"
    public let keys: [Key] = [.alt("a")]
    public var commandBarAliases: [String] { ["accept", "proposal.accept", ":accept"] }

    public init() {}

    public func execute(on editor: Editor) {
        guard let current = editor.proposalQueue.currentProposal else {
            editor.setStatusMessage("[AI Proposal] No pending proposal to accept")
            return
        }

        let currentFileName = editor.buffer.filePath.map { NSString(string: $0).lastPathComponent } ?? ""

        for file in current.affectedFiles {
            let bufferMatch = file.filePath == "active" ||
                              file.filePath == editor.buffer.filePath ||
                              (!currentFileName.isEmpty && file.filePath.hasSuffix(currentFileName)) ||
                              (!currentFileName.isEmpty && file.filePath == currentFileName) ||
                              (!currentFileName.isEmpty && currentFileName.hasSuffix(file.filePath)) ||
                              editor.buffer.filePath == nil

            if bufferMatch {
                for chunk in file.chunks {
                    let startLineIdx = max(0, chunk.targetLine - 1)

                    for (offset, line) in chunk.lines.enumerated() {
                        let targetLineIdx = startLineIdx + offset
                        if targetLineIdx < editor.buffer.lines.count {
                            editor.buffer.lines[targetLineIdx] = line
                        } else {
                            editor.buffer.lines.append(line)
                        }
                    }
                }
                editor.buffer.isModified = true
            }
        }

        AIHistoryLogManager.shared.logDecision(proposal: current, decision: "accepted")
        editor.proposalQueue.rejectCurrent()
        editor.setStatusMessage("[AI Proposal] Accepted changes from \(current.clientName)")
        editor.renderer.invalidateScreenCache()
    }
}

public struct RejectProposalCommand: Command {
    public let id: CommandID = .proposalReject
    public let name = "Reject AI Proposal"
    public let description = "Reject and dismiss current AI proposal"
    public let keys: [Key] = [.alt("r")]
    public var commandBarAliases: [String] { ["reject", "proposal.reject", ":reject"] }

    public init() {}

    public func execute(on editor: Editor) {
        guard let current = editor.proposalQueue.currentProposal else {
            editor.setStatusMessage("[AI Proposal] No pending proposal to reject")
            return
        }

        AIHistoryLogManager.shared.logDecision(proposal: current, decision: "rejected")
        editor.proposalQueue.rejectCurrent()
        editor.setStatusMessage("[AI Proposal] Rejected proposal from \(current.clientName)")
        editor.renderer.invalidateScreenCache()
    }
}

public struct NextProposalCommand: Command {
    public let id: CommandID = .proposalNext
    public let name = "Next AI Proposal"
    public let description = "Preview next AI proposal in queue"
    public let keys: [Key] = [.alt("p")]
    public var commandBarAliases: [String] { ["nextproposal", "proposal.next", ":nextproposal"] }

    public init() {}

    public func execute(on editor: Editor) {
        guard !editor.proposalQueue.isEmpty else {
            editor.setStatusMessage("[AI Proposal] Queue is empty")
            return
        }
        editor.proposalQueue.nextProposal()
        if let current = editor.proposalQueue.currentProposal {
            editor.setStatusMessage("[AI Proposal] (\(editor.proposalQueue.activeIndex + 1)/\(editor.proposalQueue.count)) '\(current.reason)'")
        }
        editor.renderer.invalidateScreenCache()
    }
}

public struct PreviousProposalCommand: Command {
    public let id: CommandID = .proposalPrev
    public let name = "Previous AI Proposal"
    public let description = "Preview previous AI proposal in queue"
    public let keys: [Key] = [.alt("P")]
    public var commandBarAliases: [String] { ["prevproposal", "proposal.prev", ":prevproposal"] }

    public init() {}

    public func execute(on editor: Editor) {
        guard !editor.proposalQueue.isEmpty else {
            editor.setStatusMessage("[AI Proposal] Queue is empty")
            return
        }
        editor.proposalQueue.previousProposal()
        if let current = editor.proposalQueue.currentProposal {
            editor.setStatusMessage("[AI Proposal] (\(editor.proposalQueue.activeIndex + 1)/\(editor.proposalQueue.count)) '\(current.reason)'")
        }
        editor.renderer.invalidateScreenCache()
    }
}
