import XCTest

@testable import Config
@testable import Drawing
@testable import Editor
@testable import IPCServer
@testable import LogoEngine
@testable import TextMetrics

final class IPCServerTests: XCTestCase {
    private struct TestRPCRequest<Params: Encodable>: Encodable {
        let jsonrpc = "2.0"
        let method: String
        let params: Params?
        let id: Int
    }

    private struct RegistrationParams: Encodable {
        let auth: String
        let clientId: String
        let clientName: String
        let color: String?
    }

    private struct NoParams: Encodable {}

    private struct ExecuteLogoTestParams: Encodable {
        let script: String
        let mode: String?
    }

    private func send<Params: Encodable>(
        _ server: any ZagoIPCMessageHandling,
        method: String,
        params: Params? = nil,
        id: Int,
        connectionId: String
    ) throws -> JSONRPCResponse {
        let data = try JSONEncoder().encode(TestRPCRequest(method: method, params: params, id: id))
        return server.handleMessage(data, connectionId: connectionId)
    }

    private func makeTestServer(
        socketPath: String? = nil,
        sessionToken: String
    ) -> any ZagoIPCMessageHandling {
        #if os(Windows)
            return WindowsZagoIPCServer(socketPath: socketPath, sessionToken: sessionToken)
        #else
            return PosixZagoIPCServer(socketPath: socketPath, sessionToken: sessionToken)
        #endif
    }

    private struct FixedSessionLocator: ZagoIPCSessionLocating {
        let locatedSessions: [ZagoIPCSession]

        func sessions() -> [ZagoIPCSession] {
            locatedSessions
        }
    }

    private final class TestIPCDelegate: ZagoIPCServerDataSource, ZagoIPCServerDelegate {
        private let editor: Editor

        init(editor: Editor) {
            self.editor = editor
        }

        func ipcServerGetBuffers(_ server: any ZagoIPCServer) throws -> [BufferInfo] {
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

        func ipcServer(
            _ server: any ZagoIPCServer,
            textFor bufferTarget: String?,
            startLine: Int?,
            endLine: Int?
        ) throws -> (lines: [String], totalLines: Int)? {
            guard
                let result = editor.externalGetText(
                    bufferTarget: bufferTarget,
                    startLine: startLine,
                    endLine: endLine
                )
            else {
                return nil
            }
            return (lines: result.lines, totalLines: result.totalLines)
        }

        func ipcServer(_ server: any ZagoIPCServer, cursorFor bufferTarget: String?) throws -> (
            line: Int, column: Int, visualCol: Int, mode: String
        )? {
            guard let cursor = editor.externalGetCursor(bufferTarget: bufferTarget) else {
                return nil
            }
            return (line: cursor.line, column: cursor.column, visualCol: cursor.visualCol, mode: cursor.mode)
        }

        func ipcServer(
            _ server: any ZagoIPCServer, showPreviewFor client: IPCClientIdentity, reason: String,
            affectedFiles: [AffectedFilePayload]
        ) throws -> Bool {
            true
        }

        func ipcServer(_ server: any ZagoIPCServer, executeLogoFor client: IPCClientIdentity, script: String, mode: String?) throws -> (
            success: Bool, result: String, error: String?
        ) {
            let result = editor.externalExecuteLogo(
                clientId: client.clientId,
                clientName: client.clientName,
                clientColor: client.color,
                script: script,
                mode: mode,
                viewportRows: 24,
                viewportCols: 80
            )
            return (success: result.success, result: result.result, error: result.error)
        }

        func ipcServer(_ server: any ZagoIPCServer, historyWithLimit limit: Int) throws -> [IPCHistoryEntry] {
            []
        }
    }

    private final class TimedOutDataSource: ZagoIPCServerDataSource {
        func ipcServerGetBuffers(_ server: any ZagoIPCServer) throws -> [BufferInfo] {
            throw IPCServerRequestError.timedOut
        }
        func ipcServer(_ server: any ZagoIPCServer, textFor bufferTarget: String?, startLine: Int?, endLine: Int?)
            throws -> (lines: [String], totalLines: Int)?
        { throw IPCServerRequestError.timedOut }
        func ipcServer(_ server: any ZagoIPCServer, cursorFor bufferTarget: String?) throws -> (
            line: Int, column: Int, visualCol: Int, mode: String
        )? { throw IPCServerRequestError.timedOut }
        func ipcServer(_ server: any ZagoIPCServer, historyWithLimit limit: Int) throws -> [IPCHistoryEntry] {
            throw IPCServerRequestError.timedOut
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
            let result = try? editor.performOnEditorLoop {
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

    func testEditorLoopRequestTimesOutBeforeDrain() {
        let editor = Editor()
        editor.isInteractiveMode = true
        defer { editor.isInteractiveMode = false }

        XCTAssertThrowsError(try editor.performOnEditorLoop(timeout: 0.01) { "late" }) { error in
            XCTAssertEqual(error as? EditorLoopRequestError, .timedOut)
        }
        editor.drainExternalRequests()
    }

    func testEditorTimeoutMapsToRPC408() throws {
        let server = makeTestServer(sessionToken: "test-token")
        let dataSource = TimedOutDataSource()
        server.dataSource = dataSource

        let registration = try send(
            server, method: "zago.client.register",
            params: RegistrationParams(auth: "test-token", clientId: "bot", clientName: "Bot", color: nil), id: 1,
            connectionId: "conn-1")
        XCTAssertNil(registration.error)

        let response = try send(
            server, method: "zago.buffer.getBuffers", params: Optional<NoParams>.none, id: 2, connectionId: "conn-1")
        XCTAssertEqual(response.error?.code, 408)
    }

    func testProposalQueueRejectsOverflow() {
        let queue = ProposalQueue(maxDepth: 1)
        let proposal = AIProposal(clientId: "bot", clientName: "Bot", reason: "test", affectedFiles: [])
        XCTAssertTrue(queue.pushProposal(proposal))
        XCTAssertFalse(queue.pushProposal(proposal))
        XCTAssertEqual(queue.count, 1)
    }

    func testIPCServerRegistrationAndAuthorization() {
        let token = "test-secret-token-12345"
        let server = makeTestServer(sessionToken: token)

        // 1. Invalid Token Registration
        let resp1 = try! send(
            server,
            method: "zago.client.register",
            params: RegistrationParams(auth: "wrong-token", clientId: "bot-1", clientName: "Bot", color: nil),
            id: 1,
            connectionId: "conn-1"
        )
        XCTAssertNotNil(resp1.error)
        XCTAssertEqual(resp1.error?.code, 401)

        // 2. Valid Token Registration
        let resp2 = try! send(
            server,
            method: "zago.client.register",
            params: RegistrationParams(auth: token, clientId: "bot-1", clientName: "Architect-Bot", color: "cyan"),
            id: 2,
            connectionId: "conn-1"
        )
        XCTAssertNil(resp2.error)

        let unregisteredRead = try! send(
            server,
            method: "zago.buffer.getBuffers",
            params: Optional<NoParams>.none,
            id: 3,
            connectionId: "conn-2"
        )
        XCTAssertEqual(unregisteredRead.error?.code, 401)

        let registeredRead = try! send(
            server,
            method: "zago.buffer.getBuffers",
            params: Optional<NoParams>.none,
            id: 4,
            connectionId: "conn-1"
        )
        XCTAssertNotEqual(registeredRead.error?.code, 401)

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
        let server = makeTestServer(sessionToken: "test-token")
        server.delegate = target
        server.dataSource = target
        let registration = try! send(
            server,
            method: "zago.client.register",
            params: RegistrationParams(
                auth: "test-token", clientId: "buffer-test", clientName: "Buffer Test", color: nil),
            id: 0,
            connectionId: "conn-1"
        )
        XCTAssertNil(registration.error)
        let response = try! send(
            server, method: "zago.buffer.getBuffers", params: Optional<NoParams>.none, id: 1, connectionId: "conn-1")
        XCTAssertNil(response.error)
    }

    func testIPCExecuteLogoCreatesProposalWithoutMutatingBuffer() throws {
        let editor = Editor()
        editor.buffer.lines = ["alpha", "beta"]
        editor.buffer.lineIndex = 1
        editor.buffer.columnIndex = 0
        let target = TestIPCDelegate(editor: editor)
        let server = makeTestServer(sessionToken: "test-token")
        server.delegate = target
        server.dataSource = target

        let registration = try send(
            server,
            method: "zago.client.register",
            params: RegistrationParams(auth: "test-token", clientId: "ipc-agent", clientName: "IPC Agent", color: nil),
            id: 0,
            connectionId: "conn-logo"
        )
        XCTAssertNil(registration.error)

        let response = try send(
            server,
            method: "zago.buffer.executeLogo",
            params: ExecuteLogoTestParams(script: "TYPE \"inserted\"", mode: "headful"),
            id: 1,
            connectionId: "conn-logo"
        )

        XCTAssertNil(response.error)
        XCTAssertEqual(editor.buffer.lines, ["alpha", "beta"])
        XCTAssertEqual(editor.proposalQueue.count, 1)
        XCTAssertEqual(editor.proposalQueue.currentProposal?.clientId, "ipc-agent")
        XCTAssertEqual(editor.proposalQueue.currentProposal?.clientName, "IPC Agent")
        XCTAssertEqual(editor.proposalQueue.currentProposal?.affectedFiles.first?.chunks.first?.targetLine, 2)
        XCTAssertEqual(editor.proposalQueue.currentProposal?.affectedFiles.first?.chunks.first?.lines, ["inserted"])
    }

    func testZagoMCPServerMethods() throws {
        let offlineServer = ZagoMCPServer(
            sessionLocator: FixedSessionLocator(locatedSessions: [])
        )
        let initializeLine =
            "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2024-11-05\"}}"
        let initializeResponse = try XCTUnwrap(offlineServer.handleLine(initializeLine))
        let initializeJSON = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(initializeResponse.utf8)) as? [String: Any]
        )
        let initializeResult = try XCTUnwrap(initializeJSON["result"] as? [String: Any])
        let serverInfo = try XCTUnwrap(initializeResult["serverInfo"] as? [String: Any])
        XCTAssertEqual(serverInfo["name"] as? String, "zago")
        XCTAssertEqual(initializeResult["protocolVersion"] as? String, "2024-11-05")
        XCTAssertNil(
            offlineServer.handleLine(
                "{\"jsonrpc\":\"2.0\",\"method\":\"notifications/initialized\"}"
            )
        )

        let toolsResponse = try XCTUnwrap(
            offlineServer.handleLine("{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/list\"}")
        )
        let toolsJSON = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(toolsResponse.utf8)) as? [String: Any]
        )
        let toolsResult = try XCTUnwrap(toolsJSON["result"] as? [String: Any])
        let tools = try XCTUnwrap(toolsResult["tools"] as? [[String: Any]])
        XCTAssertEqual(tools.count, 7)
        let toolNames = Set(tools.compactMap { $0["name"] as? String })
        XCTAssertEqual(
            toolNames,
            [
                "zago_list_instances",
                "zago_select_instance",
                "zago_overlay_preview",
                "zago_execute_logo",
                "zago_get_buffers",
                "zago_get_text",
                "zago_get_cursor",
            ]
        )
        let getBuffersTool = try XCTUnwrap(
            tools.first { $0["name"] as? String == "zago_get_buffers" }
        )
        let annotations = try XCTUnwrap(getBuffersTool["annotations"] as? [String: Any])
        XCTAssertEqual(annotations["readOnlyHint"] as? Bool, true)
        XCTAssertEqual(annotations["openWorldHint"] as? Bool, false)

        let offlineCall = try XCTUnwrap(
            offlineServer.handleLine(
                "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"zago_get_buffers\",\"arguments\":{}}}"
            )
        )
        let offlineJSON = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(offlineCall.utf8)) as? [String: Any]
        )
        let offlineResult = try XCTUnwrap(offlineJSON["result"] as? [String: Any])
        XCTAssertEqual(offlineResult["isError"] as? Bool, true)

        #if !os(Windows)
            let socketPath = FileManager.default.temporaryDirectory
                .appendingPathComponent("zmcp-\(UUID().uuidString.prefix(8)).sock").path
            let editor = Editor()
            let ipcDelegate = TestIPCDelegate(editor: editor)
            let ipcServer = makeTestServer(
                socketPath: socketPath,
                sessionToken: "mcp-test-token"
            )
            ipcServer.delegate = ipcDelegate
            ipcServer.dataSource = ipcDelegate
            try ipcServer.start()
            defer { ipcServer.stop() }

            let session = ZagoIPCSession(
                instanceId: "zago-mcp-test",
                endpointPath: ipcServer.socketPath,
                tokenPath: ipcServer.tokenPath
            )
            let liveServer = ZagoMCPServer(
                sessionLocator: FixedSessionLocator(locatedSessions: [session])
            )
            _ = liveServer.handleLine(initializeLine)
            _ = liveServer.handleLine(
                "{\"jsonrpc\":\"2.0\",\"method\":\"notifications/initialized\"}"
            )

            let selectResponse = try XCTUnwrap(
                liveServer.handleLine(
                    "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"tools/call\",\"params\":{\"name\":\"zago_select_instance\",\"arguments\":{\"instanceId\":\"zago-mcp-test\"}}}"
                )
            )
            XCTAssertTrue(selectResponse.contains("Selected zago instance"))

            let buffersResponse = try XCTUnwrap(
                liveServer.handleLine(
                    "{\"jsonrpc\":\"2.0\",\"id\":5,\"method\":\"tools/call\",\"params\":{\"name\":\"zago_get_buffers\",\"arguments\":{}}}"
                )
            )
            let buffersJSON = try XCTUnwrap(
                JSONSerialization.jsonObject(with: Data(buffersResponse.utf8)) as? [String: Any]
            )
            let buffersResult = try XCTUnwrap(buffersJSON["result"] as? [String: Any])
            XCTAssertNil(buffersResult["isError"])
            let content = try XCTUnwrap(buffersResult["content"] as? [[String: Any]])
            let text = try XCTUnwrap(content.first?["text"] as? String)
            XCTAssertTrue(text.contains("activeBufferId"))

            let previewResponse = try XCTUnwrap(
                liveServer.handleLine(
                    "{\"jsonrpc\":\"2.0\",\"id\":6,\"method\":\"tools/call\",\"params\":{\"name\":\"zago_overlay_preview\",\"arguments\":{\"lines\":[\"hello\"]}}}"
                )
            )
            let previewJSON = try XCTUnwrap(
                JSONSerialization.jsonObject(with: Data(previewResponse.utf8)) as? [String: Any]
            )
            let previewResult = try XCTUnwrap(previewJSON["result"] as? [String: Any])
            XCTAssertNil(previewResult["isError"])
        #endif
    }

    func testZagoSkillCLIInstallerMethods() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            "zago-installer-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let (skillPaths, mcpPaths) = try ZagoSkillCLIInstaller.installSkillAndMCP(customHomePath: tempDir.path)
        XCTAssertGreaterThan(skillPaths.count, 0)
        XCTAssertGreaterThan(mcpPaths.count, 0)

        for path in skillPaths {
            XCTAssertTrue(FileManager.default.fileExists(atPath: path))
        }

        for path in mcpPaths {
            XCTAssertTrue(FileManager.default.fileExists(atPath: path))
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            let mcpServers = json?["mcpServers"] as? [String: Any]
            let zagoConfig = mcpServers?["zago"] as? [String: Any]
            XCTAssertEqual(zagoConfig?["command"] as? String, "zago")
            XCTAssertEqual(zagoConfig?["args"] as? [String], ["--mcp"])
        }

        let preservedSkillFile =
            tempDir
            .appendingPathComponent(".agents/skills/zago/notes.txt")
        try "keep me".write(to: preservedSkillFile, atomically: true, encoding: .utf8)

        let preservedMCPServer: [String: Any] = [
            "command": "other-server",
            "args": ["serve"],
        ]
        for path in mcpPaths {
            let url = URL(fileURLWithPath: path)
            let data = try Data(contentsOf: url)
            var json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            var servers = try XCTUnwrap(json["mcpServers"] as? [String: Any])
            servers["other"] = preservedMCPServer
            json["mcpServers"] = servers
            try JSONSerialization.data(withJSONObject: json).write(to: url)
        }

        let removedSkillPaths = try ZagoSkillCLIInstaller.uninstallSkill(
            customHomePath: tempDir.path
        )
        XCTAssertEqual(Set(removedSkillPaths), Set(skillPaths))
        for path in skillPaths {
            XCTAssertFalse(FileManager.default.fileExists(atPath: path))
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: preservedSkillFile.path))

        let updatedMCPPaths = try ZagoSkillCLIInstaller.uninstallMCP(
            customHomePath: tempDir.path
        )
        XCTAssertEqual(Set(updatedMCPPaths), Set(mcpPaths))
        for path in mcpPaths {
            XCTAssertTrue(FileManager.default.fileExists(atPath: path))
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            let mcpServers = try XCTUnwrap(json["mcpServers"] as? [String: Any])
            XCTAssertNil(mcpServers["zago"])
            XCTAssertNotNil(mcpServers["other"])
        }

        XCTAssertTrue(
            try ZagoSkillCLIInstaller.uninstallSkill(customHomePath: tempDir.path).isEmpty
        )
        XCTAssertTrue(
            try ZagoSkillCLIInstaller.uninstallMCP(customHomePath: tempDir.path).isEmpty
        )
    }
}
