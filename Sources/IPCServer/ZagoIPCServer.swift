import Foundation

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif os(Windows)
    import WinSDK
#endif

public struct IPCServerLimits: Sendable {
    public let maxConnections: Int
    public let maxPayloadBytes: Int
    public let clientIdleTimeout: TimeInterval
    public let clientWriteTimeout: TimeInterval

    public init(
        maxConnections: Int = 16, maxPayloadBytes: Int = 1_048_576, clientIdleTimeout: TimeInterval = 30,
        clientWriteTimeout: TimeInterval = 5
    ) {
        self.maxConnections = max(1, maxConnections)
        self.maxPayloadBytes = max(1, maxPayloadBytes)
        self.clientIdleTimeout = max(1, clientIdleTimeout)
        self.clientWriteTimeout = max(1, clientWriteTimeout)
    }
}

public protocol ZagoIPCServer: AnyObject {
    var delegate: ZagoIPCServerDelegate? { get set }
    var dataSource: ZagoIPCServerDataSource? { get set }
    var isListening: Bool { get }
    var socketPath: String { get }
    var sessionToken: String { get }
    var tokenPath: String { get }

    func start() throws
    func stop()
}

protocol ZagoIPCMessageHandling: ZagoIPCServer {
    func handleMessage(_ data: Data, connectionId: String) -> JSONRPCResponse
}

public enum ZagoIPCServerFactory {
    public static func make(socketPath: String? = nil, sessionToken: String? = nil, limits: IPCServerLimits = .init())
        -> any ZagoIPCServer
    {
        #if os(Windows)
            return WindowsZagoIPCServer(socketPath: socketPath, sessionToken: sessionToken)
        #else
            return PosixZagoIPCServer(socketPath: socketPath, sessionToken: sessionToken, limits: limits)
        #endif
    }
}

extension ZagoIPCServer {
    func handleMessage(_ data: Data, connectionId: String, parser: JSONRPCParser) -> JSONRPCResponse {
        switch parser.parseMessage(data, connectionId: connectionId) {
        case .success(let request):
            return dispatch(request, parser: parser)
        case .failure(let response):
            return response
        }
    }

    private func dispatch(_ parsed: ZagoIPCParsedRequest, parser: JSONRPCParser) -> JSONRPCResponse {
        switch parsed.request {
        case .register(let client):
            return parser.makeSuccessResponse(
                for: parsed, response: .registered(clientId: client.clientId, clientName: client.clientName))

        case .getBuffers:
            guard let dataSource else {
                return parser.makeFailureResponse(code: 500, message: "Target data source unhandled", request: parsed)
            }
            do {
                return parser.makeSuccessResponse(
                    for: parsed, response: .buffers(try dataSource.ipcServerGetBuffers(self)))
            } catch { return requestFailure(error, parser: parser, request: parsed) }

        case .getText(let bufferTarget, let startLine, let endLine):
            guard let dataSource else {
                return parser.makeFailureResponse(code: 500, message: "Target data source unhandled", request: parsed)
            }
            do {
                guard
                    let result = try dataSource.ipcServer(
                        self, textFor: bufferTarget, startLine: startLine, endLine: endLine)
                else {
                    return parser.makeFailureResponse(code: 404, message: "Target buffer not found", request: parsed)
                }
                return parser.makeSuccessResponse(
                    for: parsed, response: .text(lines: result.lines, totalLines: result.totalLines))
            } catch { return requestFailure(error, parser: parser, request: parsed) }

        case .getCursor(let bufferTarget):
            guard let dataSource else {
                return parser.makeFailureResponse(code: 500, message: "Target data source unhandled", request: parsed)
            }
            do {
                guard let cursor = try dataSource.ipcServer(self, cursorFor: bufferTarget) else {
                    return parser.makeFailureResponse(code: 404, message: "Target buffer not found", request: parsed)
                }
                return parser.makeSuccessResponse(
                    for: parsed,
                    response: .cursor(
                        line: cursor.line, column: cursor.column, visualCol: cursor.visualCol, mode: cursor.mode))
            } catch { return requestFailure(error, parser: parser, request: parsed) }

        case .showPreview(let client, let reason, let affectedFiles):
            guard let delegate else {
                return parser.makeFailureResponse(code: 500, message: "Target delegate unhandled", request: parsed)
            }
            do {
                guard try delegate.ipcServer(self, showPreviewFor: client, reason: reason, affectedFiles: affectedFiles)
                else {
                    return parser.makeFailureResponse(
                        code: 409, message: "Failed to push proposal into queue or depth limit exceeded",
                        request: parsed)
                }
                return parser.makeSuccessResponse(for: parsed, response: .previewShown)
            } catch { return requestFailure(error, parser: parser, request: parsed) }

        case .executeLogo(let client, let script, let mode):
            guard let delegate else {
                return parser.makeFailureResponse(code: 500, message: "Target delegate unhandled", request: parsed)
            }
            do {
                let result = try delegate.ipcServer(self, executeLogoFor: client, script: script, mode: mode)
                return parser.makeSuccessResponse(
                    for: parsed, response: .logo(success: result.success, result: result.result, error: result.error))
            } catch { return requestFailure(error, parser: parser, request: parsed) }

        case .getHistory(let limit):
            guard let dataSource else {
                return parser.makeFailureResponse(code: 500, message: "Target data source unhandled", request: parsed)
            }
            do {
                return parser.makeSuccessResponse(
                    for: parsed, response: .history(try dataSource.ipcServer(self, historyWithLimit: limit)))
            } catch { return requestFailure(error, parser: parser, request: parsed) }
        }
    }

    private func requestFailure(_ error: Error, parser: JSONRPCParser, request: ZagoIPCParsedRequest) -> JSONRPCResponse
    {
        switch error as? IPCServerRequestError {
        case .timedOut:
            return parser.makeFailureResponse(code: 408, message: "Editor request timed out", request: request)
        case .unavailable: return parser.makeFailureResponse(code: 503, message: "Editor unavailable", request: request)
        case nil: return parser.makeFailureResponse(code: 500, message: "IPC request failed", request: request)
        }
    }
}

#if os(Windows)
    final class WindowsZagoIPCServer: ZagoIPCMessageHandling, @unchecked Sendable {
        weak var delegate: ZagoIPCServerDelegate?
        weak var dataSource: ZagoIPCServerDataSource?
        private(set) var isListening: Bool = false
        let socketPath: String
        let sessionToken: String
        let tokenPath: String
        private let jsonRPCParser: JSONRPCParser

        init(socketPath: String? = nil, sessionToken: String? = nil) {
            let pid = ProcessInfo.processInfo.processIdentifier
            self.socketPath = socketPath ?? #"\\.\pipe\zago-\#(pid)"#
            self.tokenPath = self.socketPath + ".token"
            self.sessionToken = sessionToken ?? UUID().uuidString.replacingOccurrences(of: "-", with: "")
            self.jsonRPCParser = JSONRPCParser(sessionToken: self.sessionToken)
        }

        deinit {
            stop()
        }

        func start() throws {
            throw NSError(
                domain: "ZagoIPCServer", code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey: "Windows named-pipe IPC is not implemented yet"
                ])
        }

        func stop() {
            isListening = false
        }

        func handleMessage(_ data: Data, connectionId: String) -> JSONRPCResponse {
            handleMessage(data, connectionId: connectionId, parser: jsonRPCParser)
        }

    }
#else
    final class PosixZagoIPCServer: ZagoIPCMessageHandling, @unchecked Sendable {
        weak var delegate: ZagoIPCServerDelegate?
        weak var dataSource: ZagoIPCServerDataSource?
        private(set) var isListening: Bool = false
        let socketPath: String
        let sessionToken: String
        let tokenPath: String
        let limits: IPCServerLimits

        private var serverSocketFD: Int32 = -1
        private let queue = DispatchQueue(label: "org.zago.ipcserver", qos: .userInitiated, attributes: .concurrent)
        private var activeConnections: [String: Int32] = [:]
        private let lock = NSLock()
        private let jsonRPCParser: JSONRPCParser
        private let connectionSlots: DispatchSemaphore

        init(socketPath: String? = nil, sessionToken: String? = nil, limits: IPCServerLimits = .init()) {
            let pid = ProcessInfo.processInfo.processIdentifier
            if let socketPath {
                self.socketPath = socketPath
                self.tokenPath = socketPath + ".token"
            } else {
                let nonce = UUID().uuidString.lowercased()
                let paths = ZagoIPCSessionPaths.generatedSessionPaths(pid: pid, nonce: nonce)
                self.socketPath = paths.socketPath
                self.tokenPath = paths.tokenPath
            }
            self.sessionToken = sessionToken ?? UUID().uuidString.replacingOccurrences(of: "-", with: "")
            self.limits = limits
            self.jsonRPCParser = JSONRPCParser(sessionToken: self.sessionToken)
            self.connectionSlots = DispatchSemaphore(value: limits.maxConnections)
        }

        deinit {
            stop()
        }

        func start() throws {
            lock.lock()
            defer { lock.unlock() }

            guard !isListening else { return }

            #if canImport(Glibc)
                let sockType = Int32(SOCK_STREAM.rawValue)
            #elseif canImport(Musl)
                let sockType = Int32(SOCK_STREAM.rawValue)
            #elseif os(Linux) || os(Android)
                let sockType = Int32(SOCK_STREAM.rawValue)
            #else
                let sockType = Int32(SOCK_STREAM)
            #endif
            let fd = socket(Int32(AF_UNIX), sockType, 0)
            guard fd >= 0 else {
                throw NSError(
                    domain: "ZagoIPCServer", code: Int(errno),
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to create UNIX domain socket"
                    ])
            }

            var addr = sockaddr_un()
            addr.sun_family = sa_family_t(AF_UNIX)

            let pathBytes = socketPath.utf8CString
            guard pathBytes.count <= MemoryLayout.size(ofValue: addr.sun_path) else {
                close(fd)
                throw NSError(
                    domain: "ZagoIPCServer", code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Socket path exceeds sun_path buffer size"
                    ])
            }

            withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
                let rawPtr = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: CChar.self)
                for (index, byte) in pathBytes.enumerated() {
                    rawPtr[index] = byte
                }
            }

            let addrLen = socklen_t(MemoryLayout<sockaddr_un>.size)
            let bindResult = withUnsafePointer(to: &addr) { ptr in
                ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
                    bind(fd, saPtr, addrLen)
                }
            }

            guard bindResult == 0 else {
                close(fd)
                throw NSError(
                    domain: "ZagoIPCServer", code: Int(errno),
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to bind UNIX domain socket at \(socketPath)"
                    ])
            }

            chmod(socketPath, S_IRUSR | S_IWUSR)
            let tokenCreated = FileManager.default.createFile(
                atPath: tokenPath,
                contents: sessionToken.data(using: .utf8),
                attributes: [.posixPermissions: 0o600]
            )
            guard tokenCreated else {
                close(fd)
                unlink(socketPath)
                throw NSError(
                    domain: "ZagoIPCServer", code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to securely create IPC session token"
                    ])
            }

            guard listen(fd, Int32(limits.maxConnections)) == 0 else {
                close(fd)
                unlink(socketPath)
                throw NSError(
                    domain: "ZagoIPCServer", code: Int(errno),
                    userInfo: [
                        NSLocalizedDescriptionKey: "Failed to listen on socket"
                    ])
            }

            serverSocketFD = fd
            isListening = true

            queue.async { [weak self] in
                self?.acceptLoop()
            }
        }

        func stop() {
            lock.lock()
            defer { lock.unlock() }

            guard isListening else { return }
            isListening = false

            if serverSocketFD >= 0 {
                close(serverSocketFD)
                serverSocketFD = -1
            }
            unlink(socketPath)
            unlink(tokenPath)

            for (connectionId, clientFD) in activeConnections {
                close(clientFD)
                if let client = jsonRPCParser.unregisterClient(connectionId: connectionId) {
                    delegate?.ipcServer(self, clientDidDisconnect: client)
                }
            }
            activeConnections.removeAll()
        }

        func handleMessage(_ data: Data, connectionId: String) -> JSONRPCResponse {
            handleMessage(data, connectionId: connectionId, parser: jsonRPCParser)
        }

        private func acceptLoop() {
            while isListening && serverSocketFD >= 0 {
                var clientAddr = sockaddr_un()
                var clientAddrLen = socklen_t(MemoryLayout<sockaddr_un>.size)

                let clientFD = withUnsafeMutablePointer(to: &clientAddr) { ptr in
                    ptr.withMemoryRebound(to: sockaddr.self, capacity: 1) { saPtr in
                        accept(serverSocketFD, saPtr, &clientAddrLen)
                    }
                }

                guard clientFD >= 0 else {
                    if !isListening { break }
                    usleep(10_000)
                    continue
                }

                guard connectionSlots.wait(timeout: .now()) == .success else {
                    close(clientFD)
                    continue
                }
                configureClientSocket(clientFD)

                let connectionId = "conn-\(UUID().uuidString.prefix(8))"
                lock.lock()
                activeConnections[connectionId] = clientFD
                lock.unlock()

                queue.async { [weak self] in
                    defer { self?.connectionSlots.signal() }
                    self?.handleClientConnection(clientFD: clientFD, connectionId: connectionId)
                }
            }
        }

        private func handleClientConnection(clientFD: Int32, connectionId: String) {
            defer {
                lock.lock()
                let ownsDescriptor = activeConnections[connectionId] == clientFD
                if ownsDescriptor {
                    activeConnections.removeValue(forKey: connectionId)
                }
                lock.unlock()
                if ownsDescriptor {
                    close(clientFD)
                }
                if let client = jsonRPCParser.unregisterClient(connectionId: connectionId) {
                    delegate?.ipcServer(self, clientDidDisconnect: client)
                }
            }

            var buffer = [UInt8](repeating: 0, count: 4096)
            var accumulatedData = Data()

            while isListening {
                let bytesRead = read(clientFD, &buffer, buffer.count)
                if bytesRead <= 0 {
                    break
                }

                accumulatedData.append(buffer, count: bytesRead)

                guard accumulatedData.count <= limits.maxPayloadBytes else {
                    let response = JSONRPCResponse.failure(
                        id: nil, error: JSONRPCError(code: 413, message: "Request exceeds maxPayloadBytes"))
                    if let responseData = try? response.encodedData() {
                        writeResponse(responseData, to: clientFD)
                    }
                    break
                }

                while let newlineIndex = accumulatedData.firstIndex(of: UInt8(ascii: "\n")) {
                    let lineData = accumulatedData.subdata(in: 0..<newlineIndex)
                    accumulatedData.removeSubrange(0...newlineIndex)

                    guard !lineData.isEmpty else { continue }

                    guard lineData.count <= limits.maxPayloadBytes else {
                        let response = JSONRPCResponse.failure(
                            id: nil, error: JSONRPCError(code: 413, message: "Request exceeds maxPayloadBytes"))
                        if let responseData = try? response.encodedData() {
                            writeResponse(responseData, to: clientFD)
                        }
                        break
                    }

                    let response = handleMessage(lineData, connectionId: connectionId, parser: jsonRPCParser)
                    if let responseData = try? response.encodedData() {
                        writeResponse(responseData, to: clientFD)
                    }
                }
            }
        }

        private func writeResponse(_ responseData: Data, to clientFD: Int32) {
            var output = responseData
            output.append(UInt8(ascii: "\n"))
            output.withUnsafeBytes { ptr in
                guard let rawPtr = ptr.baseAddress else { return }
                var totalWritten = 0
                let totalSize = output.count
                while totalWritten < totalSize {
                    let written = write(clientFD, rawPtr.advanced(by: totalWritten), totalSize - totalWritten)
                    if written <= 0 {
                        break
                    }
                    totalWritten += written
                }
            }
        }

        private func configureClientSocket(_ clientFD: Int32) {
            var readTimeout = timeval(tv_sec: Int(limits.clientIdleTimeout), tv_usec: 0)
            var writeTimeout = timeval(tv_sec: Int(limits.clientWriteTimeout), tv_usec: 0)
            _ = withUnsafePointer(to: &readTimeout) {
                setsockopt(clientFD, SOL_SOCKET, SO_RCVTIMEO, $0, socklen_t(MemoryLayout<timeval>.size))
            }
            _ = withUnsafePointer(to: &writeTimeout) {
                setsockopt(clientFD, SOL_SOCKET, SO_SNDTIMEO, $0, socklen_t(MemoryLayout<timeval>.size))
            }
        }
    }
#endif
