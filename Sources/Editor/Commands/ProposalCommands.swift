import Foundation

public struct AcceptProposalCommand: Command {
    public let id: CommandID = .proposalAccept
    public let name = "Accept AI Proposal"
    public let description = "Accept current AI proposal and apply changes to text buffer"
    public let keys: [Key] = [.alt("a")]
    public var commandBarAliases: [String] { ["accept", "proposal.accept", ":accept"] }

    public init() {}

    public func execute(on editor: Editor) {
        guard !editor.buffer.isReadOnly && !editor.buffer.isDirectoryBuffer else {
            editor.setStatusMessage(editor.l10n["ai.proposal.readonly_cannot_modify"])
            return
        }

        guard let current = editor.proposalQueue.currentProposal else {
            editor.setStatusMessage(editor.l10n["ai.proposal.no_pending_accept"])
            return
        }

        // Clear selection mark to prevent mark position conflicts
        editor.clearActiveMark()

        for file in current.affectedFiles {
            let targetBuffer: TextBuffer?
            if let bId = file.bufferId, let matched = editor.buffers.first(where: { $0.id == bId }) {
                targetBuffer = matched
            } else if let fPath = file.filePath, fPath != "active", let matched = editor.buffers.first(where: { $0.filePath == fPath || ($0.filePath != nil && NSString(string: $0.filePath!).lastPathComponent == fPath) }) {
                targetBuffer = matched
            } else {
                targetBuffer = editor.buffer
            }

            if let targetBuf = targetBuffer {
                targetBuf.saveUndoSnapshot()
                for chunk in file.chunks {
                    let insertLineIdx = max(0, min(chunk.targetLine - 1, targetBuf.lines.count))
                    targetBuf.lines.insert(contentsOf: chunk.lines, at: insertLineIdx)
                }
                targetBuf.isModified = true
            }
        }

        if editor.isTableModeActive {
            let detector = TableCellDetector()
            let currentLine = max(0, min(editor.buffer.lineIndex, editor.buffer.lines.count - 1))
            let currentCol = max(0, editor.buffer.columnIndex)

            var tableBroken = false
            if let cell = editor.currentTableCell {
                if cell.minLine < 0 || cell.maxLine >= editor.buffer.lines.count {
                    tableBroken = true
                } else if let newCell = detector.detectCell(in: editor.buffer.lines, line: currentLine, col: currentCol) {
                    if newCell.minLine != cell.minLine || newCell.maxLine != cell.maxLine ||
                       newCell.minCol != cell.minCol || newCell.maxCol != cell.maxCol {
                        tableBroken = true
                    }
                } else {
                    tableBroken = true
                }
            } else {
                tableBroken = true
            }

            if tableBroken {
                editor.isTableModeActive = false
                editor.currentTableCell = nil
                editor.overlayMode = .none
            }
        }

        AIHistoryLogManager.shared.logDecision(proposal: current, decision: "accepted")
        editor.proposalQueue.rejectCurrent()
        if editor.isTableModeActive {
            editor.setStatusMessage(editor.l10n["ai.proposal.accepted_table_exited"])
        } else {
            editor.setStatusMessage(String(format: editor.l10n["ai.proposal.accepted"], current.clientName))
        }
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
            editor.setStatusMessage(editor.l10n["ai.proposal.no_pending_reject"])
            return
        }

        AIHistoryLogManager.shared.logDecision(proposal: current, decision: "rejected")
        editor.proposalQueue.rejectCurrent()
        editor.setStatusMessage(String(format: editor.l10n["ai.proposal.rejected"], current.clientName))
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
            editor.setStatusMessage(editor.l10n["ai.proposal.queue_empty"])
            return
        }
        editor.proposalQueue.nextProposal()
        if let current = editor.proposalQueue.currentProposal {
            editor.setStatusMessage(String(format: editor.l10n["ai.proposal.preview_item"], editor.proposalQueue.activeIndex + 1, editor.proposalQueue.count, current.reason))
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
            editor.setStatusMessage(editor.l10n["ai.proposal.queue_empty"])
            return
        }
        editor.proposalQueue.previousProposal()
        if let current = editor.proposalQueue.currentProposal {
            editor.setStatusMessage(String(format: editor.l10n["ai.proposal.preview_item"], editor.proposalQueue.activeIndex + 1, editor.proposalQueue.count, current.reason))
        }
        editor.renderer.invalidateScreenCache()
    }
}

public struct MockAISuggestionCommand: Command {
    public let id: CommandID = .proposalMockAI
    public let name = "Mock AI Suggestion"
    public let description = "Generate a mock AI proposal overlay for testing AI interactions"
    public let keys: [Key] = []
    public var commandBarAliases: [String] { ["mock-ai", "mock-ai-suggestion", "ai-mock", ":mock-ai", ":mock-ai-suggestion"] }

    public init() {}

    public func execute(on editor: Editor) {
        guard !editor.buffer.isReadOnly && !editor.buffer.isDirectoryBuffer else {
            editor.setStatusMessage(editor.l10n["ai.proposal.readonly_cannot_generate"])
            return
        }

        let args = editor.promptInputText.trimmingCharacters(in: .whitespaces)

        let proposalLines: [String]
        let reason: String

        if !args.isEmpty {
            let lines = args.components(separatedBy: "\\n").flatMap { $0.components(separatedBy: "\n") }
            proposalLines = lines
            reason = "Mock AI proposal: '\(args)'"
        } else {
            proposalLines = [
                "┌──────────────────┐",
                "│ Mock AI Proposal │",
                "└──────────────────┘"
            ]
            reason = "Mock AI Proposal"
        }

        let lineIdx = max(1, editor.buffer.lineIndex + 1)
        let chunk = ProposalChunk(
            targetLine: lineIdx,
            targetCol: 1,
            lines: proposalLines,
            insertMode: .d1Insert,
            type: .text
        )

        let fileProposal = AffectedFileProposal(
            filePath: editor.buffer.filePath ?? "active",
            bufferId: editor.buffer.id,
            chunks: [chunk]
        )

        let proposal = AIProposal(
            clientId: "mock-ai",
            clientName: "Mock-AI",
            reason: reason,
            affectedFiles: [fileProposal]
        )

        editor.proposalQueue.pushProposal(proposal)
        editor.setStatusMessage(String(format: editor.l10n["ai.proposal.mock_generated"], reason))
        editor.renderer.invalidateScreenCache()
    }
}
