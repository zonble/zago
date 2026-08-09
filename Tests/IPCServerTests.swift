import XCTest
@testable import Config
@testable import Drawing
@testable import Editor
@testable import IPCServer
@testable import LogoEngine
@testable import TextMetrics

final class IPCServerTests: XCTestCase {

    func testOverlayInsertModeParsing() {
        XCTAssertEqual(OverlayInsertMode.parse("1d_insert"), .d1Insert)
        XCTAssertEqual(OverlayInsertMode.parse("insert"), .d1Insert)
        XCTAssertEqual(OverlayInsertMode.parse("1d_overwrite"), .d1Overwrite)
        XCTAssertEqual(OverlayInsertMode.parse("2d_insert"), .d2Insert)
        XCTAssertEqual(OverlayInsertMode.parse("2d_overwrite"), .d2Overwrite)
        XCTAssertEqual(OverlayInsertMode.parse("overwrite"), .d2Overwrite)
        XCTAssertEqual(OverlayInsertMode.parse("2d_transparent"), .d2Transparent)
        XCTAssertEqual(OverlayInsertMode.parse("transparent"), .d2Transparent)
        XCTAssertEqual(OverlayInsertMode.parse("2d_fuse_corners"), .d2FuseCorners)
        XCTAssertEqual(OverlayInsertMode.parse("fuse_corners"), .d2FuseCorners)
        XCTAssertEqual(OverlayInsertMode.parse("invalid"), .d2Overwrite)
    }

    func testActionAuthorInUndoSnapshot() {
        let textBuffer = TextBuffer()
        textBuffer.lines = ["First line", "Second line"]
        textBuffer.saveUndoSnapshot(author: .user)

        textBuffer.lines[0] = "Modified first line"
        let aiAuthor = ActionAuthor.aiAgent(id: "agent-01", name: "Architect-Bot", reason: "Drafted payment flow")
        textBuffer.saveUndoSnapshot(author: aiAuthor)

        XCTAssertEqual(textBuffer.undoStack.count, 2)
        XCTAssertEqual(textBuffer.undoStack.last?.author, aiAuthor)

        let popped = textBuffer.performUndo()
        XCTAssertNotNil(popped)
        XCTAssertEqual(textBuffer.lines[0], "Modified first line")
    }

    func testProposalQueueNavigationAndLineOffsetAdjustment() {
        let queue = ProposalQueue()
        XCTAssertTrue(queue.isEmpty)
        XCTAssertEqual(queue.count, 0)

        let proposal1 = AIProposal(
            clientId: "bot-1",
            clientName: "Architect-Bot",
            reason: "Drafted 3-step flowchart",
            affectedFiles: [
                AffectedFileProposal(filePath: "ARCHITECTURE.md", chunks: [
                    ProposalChunk(targetLine: 15, targetCol: 1, lines: ["┌───┐", "│ A │", "└───┘"], insertMode: .d2Overwrite)
                ])
            ]
        )

        let proposal2 = AIProposal(
            clientId: "bot-2",
            clientName: "Table-Bot",
            reason: "Aligned Markdown table",
            affectedFiles: [
                AffectedFileProposal(filePath: "README.md", chunks: [
                    ProposalChunk(targetLine: 30, targetCol: 1, lines: ["| ID | Name |"], insertMode: .d1Insert)
                ])
            ]
        )

        queue.pushProposal(proposal1)
        queue.pushProposal(proposal2)

        XCTAssertEqual(queue.count, 2)
        // Newly pushed proposal2 (Table-Bot) is automatically activated
        XCTAssertEqual(queue.currentProposal?.clientName, "Table-Bot")

        queue.previousProposal()
        XCTAssertEqual(queue.currentProposal?.clientName, "Architect-Bot")

        // Test Dynamic Ghost Line Offset Auto-Adjustment
        // User inserts 2 lines at Line 10 (above proposal1's Line 15 and proposal2's Line 30)
        queue.adjustLineOffsets(aboveLine: 10, delta: 2)

        XCTAssertEqual(queue.pendingProposals[0].affectedFiles[0].chunks[0].targetLine, 17)
        XCTAssertEqual(queue.pendingProposals[1].affectedFiles[0].chunks[0].targetLine, 32)
    }

    func testJSONRPCHandlerRegistrationAndAuthorization() {
        let token = "test-secret-token-12345"
        let handler = JSONRPCHandler(sessionToken: token)

        // 1. Invalid Token Registration
        let invalidRegReq = JSONRPCRequest(
            method: "zago.client.register",
            params: .object([
                "auth": .string("wrong-token"),
                "clientId": .string("bot-1"),
                "clientName": .string("Bot")
            ]),
            id: .int(1)
        )
        let resp1 = handler.handleRequest(invalidRegReq, connectionId: "conn-1")
        XCTAssertNotNil(resp1.error)
        XCTAssertEqual(resp1.error?.code, 401)

        // 2. Valid Token Registration
        let validRegReq = JSONRPCRequest(
            method: "zago.client.register",
            params: .object([
                "auth": .string(token),
                "clientId": .string("bot-1"),
                "clientName": .string("Architect-Bot"),
                "color": .string("cyan")
            ]),
            id: .int(2)
        )
        let resp2 = handler.handleRequest(validRegReq, connectionId: "conn-1")
        XCTAssertNil(resp2.error)
        XCTAssertEqual(resp2.result?.objectValue?["registered"]?.boolValue, true)
    }

    func testAIHistoryLogManager() {
        let manager = AIHistoryLogManager.shared
        let proposal = AIProposal(
            clientId: "bot-1",
            clientName: "Architect-Bot",
            reason: "Drafted payment flow",
            affectedFiles: []
        )

        manager.logDecision(proposal: proposal, decision: "accepted")
        let recent = manager.recentEntries(limit: 5)
        XCTAssertGreaterThan(recent.count, 0)
        XCTAssertEqual(recent.first?.clientName, "Architect-Bot")
        XCTAssertEqual(recent.first?.decision, "accepted")
    }

    func testBufferUUIDAndGetBuffersAPI() {
        let handler = JSONRPCHandler(sessionToken: "test-token")
        let request = JSONRPCRequest(method: "zago.buffer.getBuffers", id: .int(1))
        let response = handler.handleRequest(request, connectionId: "conn-1")
        XCTAssertNotNil(response.result)
    }
}
