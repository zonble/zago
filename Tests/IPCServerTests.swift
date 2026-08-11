import XCTest

@testable import Config
@testable import Drawing
@testable import Editor
@testable import IPCServer
@testable import LogoEngine
@testable import TextMetrics

final class IPCServerTests: XCTestCase {
    private final class TestIPCDelegate: ZagoIPCServerDelegate {
        private let editor: Editor

        init(editor: Editor) {
            self.editor = editor
        }

        func handleGetBuffers() -> [BufferInfo] {
            editor.externalGetBuffers().map {
                BufferInfo(
                    bufferId: $0.bufferId,
                    filePath: $0.filePath,
                    fileName: $0.fileName,
                    isModified: $0.isModified,
                    isFocused: $0.isFocused
                )
            }
        }

        func handleGetText(
            bufferTarget: String?,
            startLine: Int?,
            endLine: Int?
        ) -> (lines: [String], totalLines: Int)? {
            guard let result = editor.externalGetText(
                bufferTarget: bufferTarget,
                startLine: startLine,
                endLine: endLine
            ) else {
                return nil
            }
            return (lines: result.lines, totalLines: result.totalLines)
        }

        func handleGetCursor(bufferTarget: String?) -> (line: Int, column: Int, visualCol: Int, mode: String)? {
            guard let cursor = editor.externalGetCursor(bufferTarget: bufferTarget) else {
                return nil
            }
            return (line: cursor.line, column: cursor.column, visualCol: cursor.visualCol, mode: cursor.mode)
        }

        func handleShowPreview(clientId: String, reason: String, affectedFiles: [AffectedFilePayload]) -> Bool {
            true
        }

        func handleExecuteLogo(script: String, mode: String?) -> (success: Bool, result: String, error: String?) {
            let result = editor.externalExecuteLogo(script: script, mode: mode)
            return (success: result.success, result: result.result, error: result.error)
        }

        func handleGetHistory(limit: Int) -> [JSONValue] {
            []
        }
    }

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

    func testExternalEditorRequestRunsWhenEditorLoopDrains() {
        let editor = Editor()
        editor.isInteractiveMode = true
        defer {
            editor.isInteractiveMode = false
        }

        let requestCompleted = expectation(description: "external editor request completed")
        DispatchQueue.global(qos: .userInitiated).async {
            let result = editor.performOnEditorLoop {
                editor.buffer.lines[0] = "changed by ipc"
                return "ok"
            }
            XCTAssertEqual(result, "ok")
            requestCompleted.fulfill()
        }

        let deadline = Date().addingTimeInterval(1)
        while editor.buffer.lines[0] != "changed by ipc" && Date() < deadline {
            editor.drainExternalRequests()
            Thread.sleep(forTimeInterval: 0.01)
        }

        wait(for: [requestCompleted], timeout: 1)
        XCTAssertEqual(editor.buffer.lines[0], "changed by ipc")
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
                AffectedFileProposal(
                    filePath: "ARCHITECTURE.md",
                    chunks: [
                        ProposalChunk(
                            targetLine: 15, targetCol: 1, lines: ["┌───┐", "│ A │", "└───┘"], insertMode: .d2Overwrite)
                    ])
            ]
        )

        let proposal2 = AIProposal(
            clientId: "bot-2",
            clientName: "Table-Bot",
            reason: "Aligned Markdown table",
            affectedFiles: [
                AffectedFileProposal(
                    filePath: "README.md",
                    chunks: [
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

    func testIPCServerRegistrationAndAuthorization() {
        let token = "test-secret-token-12345"
        let server = PosixZagoIPCServer(sessionToken: token)

        // 1. Invalid Token Registration
        let invalidRegReq = JSONRPCRequest(
            method: "zago.client.register",
            params: .object([
                "auth": .string("wrong-token"),
                "clientId": .string("bot-1"),
                "clientName": .string("Bot"),
            ]),
            id: .int(1)
        )
        let resp1 = server.handleRequest(invalidRegReq, connectionId: "conn-1")
        XCTAssertNotNil(resp1.error)
        XCTAssertEqual(resp1.error?.code, 401)

        // 2. Valid Token Registration
        let validRegReq = JSONRPCRequest(
            method: "zago.client.register",
            params: .object([
                "auth": .string(token),
                "clientId": .string("bot-1"),
                "clientName": .string("Architect-Bot"),
                "color": .string("cyan"),
            ]),
            id: .int(2)
        )
        let resp2 = server.handleRequest(validRegReq, connectionId: "conn-1")
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
        let editor = Editor()
        let target = TestIPCDelegate(editor: editor)
        let server = PosixZagoIPCServer(sessionToken: "test-token")
        server.delegate = target
        let request = JSONRPCRequest(method: "zago.buffer.getBuffers", id: .int(1))
        let response = server.handleRequest(request, connectionId: "conn-1")
        XCTAssertNotNil(response.result)
    }
}
