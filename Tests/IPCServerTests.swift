import Foundation
import Testing

@testable import Config
@testable import Drawing
@testable import Editor
@testable import IPCServer
@testable import LogoEngine
@testable import TextMetrics

@Suite(.serialized)
struct IPCServerTests {
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

    private final class WakeupTrackingTerminal: EditorTerminal, @unchecked Sendable {
        private let lock = NSLock()
        private(set) var wakeupCount = 0
        var onWakeup: (@Sendable () -> Void)?
        private var woke = false

        func enableRawMode() throws {}
        func disableRawMode() {}
        func getWindowSize() -> (rows: Int, cols: Int) { (24, 80) }
        func readKey() -> Key {
            while true {
                lock.lock()
                let shouldReturn = woke
                if shouldReturn {
                    woke = false
                }
                lock.unlock()
                if shouldReturn {
                    return .ctrl("X")
                }
                Thread.sleep(forTimeInterval: 0.005)
            }
        }
        func readPendingText(firstChar: Character) -> String { String(firstChar) }
        func write(_ text: String) {}
        func hideCursor() {}
        func showCursor() {}
        func clearScreen() {}

        func wakeup() {
            lock.lock()
            wakeupCount += 1
            woke = true
            let callback = onWakeup
            lock.unlock()
            callback?()
        }
    }

    private final class TestIPCDelegate: ZagoIPCServerDataSource, ZagoIPCServerDelegate, @unchecked Sendable {
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

        func ipcServer(_ server: any ZagoIPCServer, selectionFor bufferTarget: String?) throws -> IPCSelectionInfo? {
            guard let result = editor.externalGetSelection(bufferTarget: bufferTarget) else {
                return nil
            }
            return IPCSelectionInfo(
                hasSelection: result.hasSelection,
                text: result.text,
                lines: result.lines,
                startLine: result.startLine,
                startColumn: result.startColumn,
                endLine: result.endLine,
                endColumn: result.endColumn
            )
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

        func ipcServer(
            _ server: any ZagoIPCServer, executeLogoFor client: IPCClientIdentity, script: String, mode: String?
        ) throws -> (
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

    private final class TimedOutDataSource: ZagoIPCServerDataSource, @unchecked Sendable {
        func ipcServerGetBuffers(_ server: any ZagoIPCServer) throws -> [BufferInfo] {
            throw IPCServerRequestError.timedOut
        }
        func ipcServer(_ server: any ZagoIPCServer, textFor bufferTarget: String?, startLine: Int?, endLine: Int?)
            throws -> (lines: [String], totalLines: Int)?
        { throw IPCServerRequestError.timedOut }
        func ipcServer(_ server: any ZagoIPCServer, selectionFor bufferTarget: String?) throws -> IPCSelectionInfo? {
            throw IPCServerRequestError.timedOut
        }
        func ipcServer(_ server: any ZagoIPCServer, cursorFor bufferTarget: String?) throws -> (
            line: Int, column: Int, visualCol: Int, mode: String
        )? { throw IPCServerRequestError.timedOut }
        func ipcServer(_ server: any ZagoIPCServer, historyWithLimit limit: Int) throws -> [IPCHistoryEntry] {
            throw IPCServerRequestError.timedOut
        }
    }

    @Test func testOverlayInsertModeParsing() {
        #expect(OverlayInsertMode.parse("1d_insert") == .d1Insert)
        #expect(OverlayInsertMode.parse("insert") == .d1Insert)
        #expect(OverlayInsertMode.parse("1d_overwrite") == .d1Overwrite)
        #expect(OverlayInsertMode.parse("2d_insert") == .d2Insert)
        #expect(OverlayInsertMode.parse("2d_overwrite") == .d2Overwrite)
        #expect(OverlayInsertMode.parse("overwrite") == .d2Overwrite)
        #expect(OverlayInsertMode.parse("2d_transparent") == .d2Transparent)
        #expect(OverlayInsertMode.parse("transparent") == .d2Transparent)
        #expect(OverlayInsertMode.parse("2d_fuse_corners") == .d2FuseCorners)
        #expect(OverlayInsertMode.parse("fuse_corners") == .d2FuseCorners)
        #expect(OverlayInsertMode.parse("invalid") == .d2Overwrite)
    }

    @Test func testActionAuthorInUndoSnapshot() {
        let textBuffer = TextBuffer()
        textBuffer.lines = ["First line", "Second line"]
        textBuffer.saveUndoSnapshot(author: .user)

        textBuffer.lines[0] = "Modified first line"
        let aiAuthor = ActionAuthor.aiAgent(id: "agent-01", name: "Architect-Bot", reason: "Drafted payment flow")
        textBuffer.saveUndoSnapshot(author: aiAuthor)

        #expect(textBuffer.undoStack.count == 2)
        #expect(textBuffer.undoStack.last?.author == aiAuthor)

        let popped = textBuffer.performUndo()
        #expect(popped != nil)
        #expect(textBuffer.lines[0] == "Modified first line")
    }

    @Test func testExternalEditorRequestRunsWhenEditorLoopDrains() async throws {
        let editor = Editor()
        editor.isInteractiveMode = true
        defer {
            editor.isInteractiveMode = false
        }

        let task = Task.detached {
            try editor.performOnEditorLoop {
                editor.buffer.lines[0] = "changed by ipc"
                return "ok"
            }
        }

        let start = Date()
        while editor.buffer.lines[0] != "changed by ipc" && Date().timeIntervalSince(start) < 2 {
            editor.drainExternalRequests()
            try await Task.sleep(nanoseconds: 10_000_000)
        }

        let result = try await task.value
        #expect(result == "ok")
        #expect(editor.buffer.lines[0] == "changed by ipc")
    }

    @Test func testExternalEditorRequestWakesBlockedTerminal() async throws {
        let terminal = WakeupTrackingTerminal()
        let editor = Editor(
            options: EditorOptions(language: .en),
            dependencies: EditorDependencies(fileIOStrategy: TestLocalEditorFileIOStrategy.shared, terminal: terminal),
            initialVariables: [:]
        )

        let editorTask = Task.detached {
            editor.run()
        }

        try await Task.sleep(nanoseconds: 50_000_000)

        let requestTask = Task.detached {
            try editor.performOnEditorLoop(timeout: 2) {
                editor.buffer.lines[0] = "changed after wakeup"
                return "ok"
            }
        }

        let result = try await requestTask.value
        #expect(result == "ok")
        #expect(terminal.wakeupCount >= 1)
        _ = await editorTask.result
        #expect(editor.buffer.lines[0] == "changed after wakeup")
    }

    @Test func testProposalQueueNavigationAndLineOffsetAdjustment() {
        let queue = ProposalQueue()
        #expect(queue.isEmpty)
        #expect(queue.count == 0)

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

        #expect(queue.count == 2)
        // Newly pushed proposal2 (Table-Bot) is automatically activated
        #expect(queue.currentProposal?.clientName == "Table-Bot")

        queue.previousProposal()
        #expect(queue.currentProposal?.clientName == "Architect-Bot")

        // Test Dynamic Ghost Line Offset Auto-Adjustment
        // User inserts 2 lines at Line 10 (above proposal1's Line 15 and proposal2's Line 30)
        queue.adjustLineOffsets(aboveLine: 10, delta: 2)

        #expect(queue.pendingProposals[0].affectedFiles[0].chunks[0].targetLine == 17)
        #expect(queue.pendingProposals[1].affectedFiles[0].chunks[0].targetLine == 32)
    }

    @Test func testEditorLoopRequestTimesOutBeforeDrain() {
        let editor = Editor()
        editor.isInteractiveMode = true
        defer { editor.isInteractiveMode = false }

        #expect(throws: EditorLoopRequestError.timedOut) {
            try editor.performOnEditorLoop(timeout: 0.01) { "late" }
        }
        editor.drainExternalRequests()
    }

    @Test func testEditorTimeoutMapsToRPC408() throws {
        let server = makeTestServer(sessionToken: "test-token")
        let dataSource = TimedOutDataSource()
        server.dataSource = dataSource

        let registration = try send(
            server, method: "zago.client.register",
            params: RegistrationParams(auth: "test-token", clientId: "bot", clientName: "Bot", color: nil), id: 1,
            connectionId: "conn-1")
        #expect(registration.error == nil)

        let response = try send(
            server, method: "zago.buffer.getBuffers", params: Optional<NoParams>.none, id: 2, connectionId: "conn-1")
        #expect(response.error?.code == 408)
    }

    @Test func testProposalQueueRejectsOverflow() {
        let queue = ProposalQueue(maxDepth: 1)
        let proposal = AIProposal(clientId: "bot", clientName: "Bot", reason: "test", affectedFiles: [])
        #expect(queue.pushProposal(proposal))
        #expect(!queue.pushProposal(proposal))
        #expect(queue.count == 1)
    }

    @Test func testIPCServerRegistrationAndAuthorization() throws {
        let token = "test-secret-token-12345"
        let server = makeTestServer(sessionToken: token)

        // 1. Invalid Token Registration
        let resp1 = try send(
            server,
            method: "zago.client.register",
            params: RegistrationParams(auth: "wrong-token", clientId: "bot-1", clientName: "Bot", color: nil),
            id: 1,
            connectionId: "conn-1"
        )
        #expect(resp1.error != nil)
        #expect(resp1.error?.code == 401)

        // 2. Valid Token Registration
        let resp2 = try send(
            server,
            method: "zago.client.register",
            params: RegistrationParams(auth: token, clientId: "bot-1", clientName: "Architect-Bot", color: "cyan"),
            id: 2,
            connectionId: "conn-1"
        )
        #expect(resp2.error == nil)

        let unregisteredRead = try send(
            server,
            method: "zago.buffer.getBuffers",
            params: Optional<NoParams>.none,
            id: 3,
            connectionId: "conn-2"
        )
        #expect(unregisteredRead.error?.code == 401)

        let registeredRead = try send(
            server,
            method: "zago.buffer.getBuffers",
            params: Optional<NoParams>.none,
            id: 4,
            connectionId: "conn-1"
        )
        #expect(registeredRead.error?.code != 401)
    }

    @Test func testAIHistoryLogManager() {
        let manager = AIHistoryLogManager.shared
        let proposal = AIProposal(
            clientId: "bot-1",
            clientName: "Architect-Bot",
            reason: "Drafted payment flow",
            affectedFiles: []
        )

        manager.logDecision(proposal: proposal, decision: "accepted")
        let recent = manager.recentEntries(limit: 5)
        #expect(recent.count > 0)
        #expect(recent.first?.clientName == "Architect-Bot")
        #expect(recent.first?.decision == "accepted")
    }

    @Test func testBufferUUIDAndGetBuffersAPI() throws {
        let editor = Editor()
        let target = TestIPCDelegate(editor: editor)
        let server = makeTestServer(sessionToken: "test-token")
        server.delegate = target
        server.dataSource = target
        let registration = try send(
            server,
            method: "zago.client.register",
            params: RegistrationParams(
                auth: "test-token", clientId: "buffer-test", clientName: "Buffer Test", color: nil),
            id: 0,
            connectionId: "conn-1"
        )
        #expect(registration.error == nil)
        let response = try send(
            server, method: "zago.buffer.getBuffers", params: Optional<NoParams>.none, id: 1, connectionId: "conn-1")
        #expect(response.error == nil)
    }

    @Test func testIPCClientConnectsToLiveServerAndFetchesBuffers() throws {
        #if os(Windows)
            let server = makeTestServer(sessionToken: "live-token")
        #else
            let socketPath = FileManager.default.temporaryDirectory
                .appendingPathComponent("zago-live-\(UUID().uuidString.prefix(8)).sock").path
            let server = makeTestServer(socketPath: socketPath, sessionToken: "live-token")
        #endif
        let editor = Editor()
        editor.buffer.lines = ["alpha", "beta"]
        let target = TestIPCDelegate(editor: editor)
        server.delegate = target
        server.dataSource = target

        try server.start()
        defer { server.stop() }

        let session = ZagoIPCSession(
            instanceId: "zago-live-test",
            endpointPath: server.socketPath,
            tokenPath: server.tokenPath
        )
        let client = ZagoIPCClient(clientId: "zago-test-client", clientName: "zago test")

        let result = try client.getBuffers(in: session)

        #expect(result.buffers.count == 1)
        #expect(result.buffers.first?.bufferId == result.activeBufferId)
        #expect(result.buffers.first?.fileName == editor.l10n["buffer.untitled"])
        #expect(result.buffers.first?.isFocused == true)
    }

    @Test func testIPCGetSelectionReturnsSelectedTextAndRange() throws {
        let editor = Editor()
        editor.buffer.lines = ["alpha", "beta", "gamma"]
        editor.buffer.selectionMark = (line: 0, column: 2)
        editor.buffer.lineIndex = 1
        editor.buffer.columnIndex = 2
        let target = TestIPCDelegate(editor: editor)
        let server = makeTestServer(sessionToken: "test-token")
        server.delegate = target
        server.dataSource = target

        let registration = try send(
            server,
            method: "zago.client.register",
            params: RegistrationParams(
                auth: "test-token", clientId: "selection-test", clientName: "Selection Test", color: nil),
            id: 0,
            connectionId: "conn-selection"
        )
        #expect(registration.error == nil)

        let response = try send(
            server,
            method: "zago.buffer.getSelection",
            params: Optional<NoParams>.none,
            id: 1,
            connectionId: "conn-selection"
        )
        #expect(response.error == nil)

        guard let responseJSON = try JSONSerialization.jsonObject(with: try response.encodedData()) as? [String: Any],
            let result = responseJSON["result"] as? [String: Any]
        else {
            Issue.record("Failed to decode response JSON")
            return
        }
        #expect(result["hasSelection"] as? Bool == true)
        #expect(result["text"] as? String == "pha\nbe")
        #expect(result["lines"] as? [String] == ["pha", "be"])
        #expect(result["startLine"] as? Int == 1)
        #expect(result["startColumn"] as? Int == 3)
        #expect(result["endLine"] as? Int == 2)
        #expect(result["endColumn"] as? Int == 3)
    }

    @Test func testIPCExecuteLogoCreatesProposalWithoutMutatingBuffer() throws {
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
        #expect(registration.error == nil)

        let response = try send(
            server,
            method: "zago.buffer.executeLogo",
            params: ExecuteLogoTestParams(script: "TYPE \"inserted\"", mode: "headful"),
            id: 1,
            connectionId: "conn-logo"
        )

        #expect(response.error == nil)
        #expect(editor.buffer.lines == ["alpha", "beta"])
        #expect(editor.proposalQueue.count == 1)
        #expect(editor.proposalQueue.currentProposal?.clientId == "ipc-agent")
        #expect(editor.proposalQueue.currentProposal?.clientName == "IPC Agent")
        #expect(editor.proposalQueue.currentProposal?.affectedFiles.first?.chunks.first?.targetLine == 2)
        #expect(editor.proposalQueue.currentProposal?.affectedFiles.first?.chunks.first?.lines == ["inserted"])
    }

    @Test func testZagoMCPServerMethods() throws {
        let offlineServer = ZagoMCPServer(
            sessionLocator: FixedSessionLocator(locatedSessions: [])
        )
        let initializeLine =
            "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"initialize\",\"params\":{\"protocolVersion\":\"2024-11-05\"}}"
        guard let initializeResponse = offlineServer.handleLine(initializeLine),
            let initializeJSON = try JSONSerialization.jsonObject(with: Data(initializeResponse.utf8)) as? [String: Any],
            let initializeResult = initializeJSON["result"] as? [String: Any],
            let serverInfo = initializeResult["serverInfo"] as? [String: Any]
        else {
            Issue.record("Failed to parse initialize response")
            return
        }
        #expect(serverInfo["name"] as? String == "zago")
        #expect(initializeResult["protocolVersion"] as? String == "2024-11-05")
        #expect(
            offlineServer.handleLine(
                "{\"jsonrpc\":\"2.0\",\"method\":\"notifications/initialized\"}"
            ) == nil
        )

        guard let toolsResponse = offlineServer.handleLine("{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"tools/list\"}"),
            let toolsJSON = try JSONSerialization.jsonObject(with: Data(toolsResponse.utf8)) as? [String: Any],
            let toolsResult = toolsJSON["result"] as? [String: Any],
            let tools = toolsResult["tools"] as? [[String: Any]]
        else {
            Issue.record("Failed to parse tools/list response")
            return
        }
        #expect(tools.count == 8)
        let toolNames = Set(tools.compactMap { $0["name"] as? String })
        #expect(
            toolNames
                == [
                    "zago_list_instances",
                    "zago_select_instance",
                    "zago_overlay_preview",
                    "zago_execute_logo",
                    "zago_get_buffers",
                    "zago_get_text",
                    "zago_get_selection",
                    "zago_get_cursor",
                ]
        )
        guard let getBuffersTool = tools.first(where: { $0["name"] as? String == "zago_get_buffers" }),
            let annotations = getBuffersTool["annotations"] as? [String: Any]
        else {
            Issue.record("Failed to find zago_get_buffers annotations")
            return
        }
        #expect(annotations["readOnlyHint"] as? Bool == true)
        #expect(annotations["openWorldHint"] as? Bool == false)

        guard let offlineCall = offlineServer.handleLine(
            "{\"jsonrpc\":\"2.0\",\"id\":3,\"method\":\"tools/call\",\"params\":{\"name\":\"zago_get_buffers\",\"arguments\":{}}}"
        ),
            let offlineJSON = try JSONSerialization.jsonObject(with: Data(offlineCall.utf8)) as? [String: Any],
            let offlineResult = offlineJSON["result"] as? [String: Any]
        else {
            Issue.record("Failed to parse offline tools/call response")
            return
        }
        #expect(offlineResult["isError"] as? Bool == true)

        #if os(Windows)
            let editor = Editor()
            editor.buffer.lines = ["alpha", "beta"]
            editor.buffer.selectionMark = (line: 0, column: 2)
            editor.buffer.lineIndex = 1
            editor.buffer.columnIndex = 2
            let ipcDelegate = TestIPCDelegate(editor: editor)
            let ipcServer = makeTestServer(
                sessionToken: "mcp-test-token"
            )
        #else
            let socketPath = FileManager.default.temporaryDirectory
                .appendingPathComponent("zmcp-\(UUID().uuidString.prefix(8)).sock").path
            let editor = Editor()
            editor.buffer.lines = ["alpha", "beta"]
            editor.buffer.selectionMark = (line: 0, column: 2)
            editor.buffer.lineIndex = 1
            editor.buffer.columnIndex = 2
            let ipcDelegate = TestIPCDelegate(editor: editor)
            let ipcServer = makeTestServer(
                socketPath: socketPath,
                sessionToken: "mcp-test-token"
            )
        #endif
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

        guard let selectResponse = liveServer.handleLine(
            "{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"tools/call\",\"params\":{\"name\":\"zago_select_instance\",\"arguments\":{\"instanceId\":\"zago-mcp-test\"}}}"
        ) else {
            Issue.record("Failed to get selectResponse")
            return
        }
        #expect(selectResponse.contains("Selected zago instance"))

        guard let buffersResponse = liveServer.handleLine(
            "{\"jsonrpc\":\"2.0\",\"id\":5,\"method\":\"tools/call\",\"params\":{\"name\":\"zago_get_buffers\",\"arguments\":{}}}"
        ),
            let buffersJSON = try JSONSerialization.jsonObject(with: Data(buffersResponse.utf8)) as? [String: Any],
            let buffersResult = buffersJSON["result"] as? [String: Any]
        else {
            Issue.record("Failed to parse buffersResponse")
            return
        }
        #expect(buffersResult["isError"] == nil)
        guard let content = buffersResult["content"] as? [[String: Any]],
            let text = content.first?["text"] as? String
        else {
            Issue.record("Failed to parse content in buffersResponse")
            return
        }
        #expect(text.contains("activeBufferId"))

        guard let previewResponse = liveServer.handleLine(
            "{\"jsonrpc\":\"2.0\",\"id\":6,\"method\":\"tools/call\",\"params\":{\"name\":\"zago_overlay_preview\",\"arguments\":{\"lines\":[\"hello\"]}}}"
        ),
            let previewJSON = try JSONSerialization.jsonObject(with: Data(previewResponse.utf8)) as? [String: Any],
            let previewResult = previewJSON["result"] as? [String: Any]
        else {
            Issue.record("Failed to parse previewResponse")
            return
        }
        #expect(previewResult["isError"] == nil)

        guard let selectionResponse = liveServer.handleLine(
            "{\"jsonrpc\":\"2.0\",\"id\":7,\"method\":\"tools/call\",\"params\":{\"name\":\"zago_get_selection\",\"arguments\":{}}}"
        ),
            let selectionJSON = try JSONSerialization.jsonObject(with: Data(selectionResponse.utf8)) as? [String: Any],
            let selectionResult = selectionJSON["result"] as? [String: Any]
        else {
            Issue.record("Failed to parse selectionResponse")
            return
        }
        #expect(selectionResult["isError"] == nil)
        guard let selectionContent = selectionResult["content"] as? [[String: Any]],
            let selectionText = selectionContent.first?["text"] as? String
        else {
            Issue.record("Failed to parse selectionContent")
            return
        }
        #expect(selectionText.contains("\"hasSelection\" : true"))
        #expect(selectionText.contains("\"text\" : \"pha\\nbe\""))
    }

    @Test func testDefaultPosixIPCServerUsesShortSocketPath() throws {
        #if !os(Windows)
            let server = makeTestServer(sessionToken: "short-path-token")
            #expect(
                server.socketPath.utf8CString.count
                    <= ZagoIPCSessionPaths.unixSocketPathByteLimit
            )
            #expect(server.socketPath.hasPrefix("/tmp/") || server.socketPath.hasPrefix("/private/tmp/"))
        #endif
    }

    @Test func testDefaultSessionLocatorSkipsOverlongSocketPath() throws {
        #if !os(Windows)
            let tempRoot = FileManager.default.temporaryDirectory
                .appendingPathComponent("zago-overlong-\(UUID().uuidString)")
            let longDirectory = tempRoot.appendingPathComponent(String(repeating: "x", count: 120))
            try FileManager.default.createDirectory(at: longDirectory, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempRoot) }

            let socketURL = longDirectory.appendingPathComponent("zago-test.sock")
            let tokenURL = longDirectory.appendingPathComponent("zago-test.token")
            #expect(FileManager.default.createFile(atPath: socketURL.path, contents: Data()))
            #expect(FileManager.default.createFile(atPath: tokenURL.path, contents: Data("token".utf8)))

            #expect(
                socketURL.path.utf8CString.count
                    > ZagoIPCSessionPaths.unixSocketPathByteLimit
            )
            #expect(DefaultZagoIPCSessionLocator(temporaryDirectory: longDirectory).sessions().isEmpty)
        #endif
    }

    @Test func testWindowsSessionLocatorFindsNamedPipeTokenFiles() throws {
        #if os(Windows)
            let tempRoot = FileManager.default.temporaryDirectory
                .appendingPathComponent("zago-windows-locator-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempRoot) }

            let tokenURL = tempRoot.appendingPathComponent("zago-1234-test.token")
            #expect(FileManager.default.createFile(atPath: tokenURL.path, contents: Data("token".utf8)))

            let sessions = WindowsZagoIPCSessionLocator(temporaryDirectory: tempRoot).sessions()
            #expect(sessions.count == 1)
            #expect(sessions[0].instanceId == "zago-1234-test")
            #expect(sessions[0].endpointPath == #"\\.\pipe\zago-1234-test"#)
            #expect(sessions[0].tokenPath == tokenURL.path)
        #endif
    }

    @Test func testZagoSkillCLIInstallerMethods() throws {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
            "zago-installer-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let (skillPaths, mcpPaths) = try ZagoSkillCLIInstaller.installSkillAndMCP(customHomePath: tempDir.path)
        #expect(skillPaths.count > 0)
        #expect(mcpPaths.count > 0)
        #expect(
            skillPaths.contains(
                tempDir.appendingPathComponent(".codex/skills/zago/SKILL.md").path
            )
        )

        for path in skillPaths {
            #expect(FileManager.default.fileExists(atPath: path))
        }

        for path in mcpPaths {
            #expect(FileManager.default.fileExists(atPath: path))
            if path.hasSuffix(".toml") {
                let toml = try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
                #expect(toml.contains("[mcp_servers.zago]"))
                #expect(toml.contains("command = \"zago\""))
                #expect(toml.contains("args = [\"--mcp\"]"))
            } else {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let mcpServers = json?["mcpServers"] as? [String: Any]
                let zagoConfig = mcpServers?["zago"] as? [String: Any]
                #expect(zagoConfig?["command"] as? String == "zago")
                #expect(zagoConfig?["args"] as? [String] == ["--mcp"])
            }
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
            if path.hasSuffix(".toml") {
                var toml = try String(contentsOf: url, encoding: .utf8)
                toml += "\n[mcp_servers.zago.env]\nZAGO_TEST = \"1\"\n"
                toml += "\n[mcp_servers.other]\ncommand = \"other-server\"\nargs = [\"serve\"]\n"
                try toml.write(to: url, atomically: true, encoding: .utf8)
            } else {
                let data = try Data(contentsOf: url)
                guard var json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    var servers = json["mcpServers"] as? [String: Any]
                else {
                    Issue.record("Failed to parse json mcpServers")
                    continue
                }
                servers["other"] = preservedMCPServer
                json["mcpServers"] = servers
                try JSONSerialization.data(withJSONObject: json).write(to: url)
            }
        }

        let removedSkillPaths = try ZagoSkillCLIInstaller.uninstallSkill(
            customHomePath: tempDir.path
        )
        #expect(Set(removedSkillPaths) == Set(skillPaths))
        for path in skillPaths {
            #expect(!FileManager.default.fileExists(atPath: path))
        }
        #expect(FileManager.default.fileExists(atPath: preservedSkillFile.path))

        let updatedMCPPaths = try ZagoSkillCLIInstaller.uninstallMCP(
            customHomePath: tempDir.path
        )
        #expect(Set(updatedMCPPaths) == Set(mcpPaths))
        for path in mcpPaths {
            #expect(FileManager.default.fileExists(atPath: path))
            if path.hasSuffix(".toml") {
                let toml = try String(contentsOf: URL(fileURLWithPath: path), encoding: .utf8)
                #expect(!toml.contains("[mcp_servers.zago]"))
                #expect(!toml.contains("[mcp_servers.zago.env]"))
                #expect(toml.contains("[mcp_servers.other]"))
            } else {
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let mcpServers = json["mcpServers"] as? [String: Any]
                else {
                    Issue.record("Failed to parse json after uninstall")
                    continue
                }
                #expect(mcpServers["zago"] == nil)
                #expect(mcpServers["other"] != nil)
            }
        }

        #expect(
            try ZagoSkillCLIInstaller.uninstallSkill(customHomePath: tempDir.path).isEmpty
        )
        #expect(
            try ZagoSkillCLIInstaller.uninstallMCP(customHomePath: tempDir.path).isEmpty
        )
    }
}
