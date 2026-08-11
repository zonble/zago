import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif os(Windows)
import WinSDK
#endif

public protocol ZagoIPCServer: AnyObject {
    var delegate: ZagoIPCServerDelegate? { get set }
    var isListening: Bool { get }
    var socketPath: String { get }
    var sessionToken: String { get }
    var tokenPath: String { get }

    func start() throws
    func stop()
}

public enum ZagoIPCServerFactory {
    public static func make(socketPath: String? = nil, sessionToken: String? = nil) -> any ZagoIPCServer {
        #if os(Windows)
        return WindowsZagoIPCServer(socketPath: socketPath, sessionToken: sessionToken)
        #else
        return PosixZagoIPCServer(socketPath: socketPath, sessionToken: sessionToken)
        #endif
    }
}

extension ZagoIPCServer {
    func handleMessage(_ data: Data, parser: JSONRPCParser) -> JSONRPCResponse {
        switch parser.parseMessage(data) {
        case .success(let request):
            return dispatch(request, parser: parser)
        case .failure(let response):
            return response
        }
    }

    func handleRequest(_ request: JSONRPCRequest, parser: JSONRPCParser) -> JSONRPCResponse {
        switch parser.normalize(request) {
        case .success(let request):
            return dispatch(request, parser: parser)
        case .failure(let response):
            return response
        }
    }

    private func dispatch(_ parsed: ZagoIPCParsedRequest, parser: JSONRPCParser) -> JSONRPCResponse {
        switch parsed.request {
        case .register(let clientId, let clientName):
            return parser.makeSuccessResponse(for: parsed, response: .registered(clientId: clientId, clientName: clientName))

        case .getBuffers:
            guard let buffers = delegate?.handleGetBuffers() else {
                return parser.makeFailureResponse(code: 500, message: "Target delegate unhandled", request: parsed)
            }
            return parser.makeSuccessResponse(for: parsed, response: .buffers(buffers))

        case .getText(let bufferTarget, let startLine, let endLine):
            guard let result = delegate?.handleGetText(
                bufferTarget: bufferTarget,
                startLine: startLine,
                endLine: endLine
            ) else {
                return parser.makeFailureResponse(code: 404, message: "Target buffer not found", request: parsed)
            }
            return parser.makeSuccessResponse(for: parsed, response: .text(lines: result.lines, totalLines: result.totalLines))

        case .getCursor(let bufferTarget):
            guard let cursor = delegate?.handleGetCursor(bufferTarget: bufferTarget) else {
                return parser.makeFailureResponse(code: 404, message: "Target buffer not found", request: parsed)
            }
            return parser.makeSuccessResponse(for: parsed, response: .cursor(
                line: cursor.line,
                column: cursor.column,
                visualCol: cursor.visualCol,
                mode: cursor.mode
            ))

        case .showPreview(let clientId, let reason, let affectedFiles):
            guard delegate?.handleShowPreview(clientId: clientId, reason: reason, affectedFiles: affectedFiles) == true else {
                return parser.makeFailureResponse(
                    code: 409,
                    message: "Failed to push proposal into queue or depth limit exceeded",
                    request: parsed
                )
            }
            return parser.makeSuccessResponse(for: parsed, response: .previewShown)

        case .executeLogo(let script, let mode):
            guard let result = delegate?.handleExecuteLogo(script: script, mode: mode) else {
                return parser.makeFailureResponse(code: 500, message: "Logo execution error", request: parsed)
            }
            return parser.makeSuccessResponse(for: parsed, response: .logo(
                success: result.success,
                result: result.result,
                error: result.error
            ))

        case .getHistory(let limit):
            let entries = delegate?.handleGetHistory(limit: limit) ?? []
            return parser.makeSuccessResponse(for: parsed, response: .history(entries))
        }
    }
}

#if os(Windows)
final class WindowsZagoIPCServer: ZagoIPCServer, @unchecked Sendable {
    weak var delegate: ZagoIPCServerDelegate?
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
        isListening = true
    }

    func stop() {
        isListening = false
    }

    func handleRequest(_ request: JSONRPCRequest, connectionId: String) -> JSONRPCResponse {
        handleRequest(request, parser: jsonRPCParser)
    }
}
#else
final class PosixZagoIPCServer: ZagoIPCServer, @unchecked Sendable {
    weak var delegate: ZagoIPCServerDelegate?
    private(set) var isListening: Bool = false
    let socketPath: String
    let sessionToken: String
    let tokenPath: String

    private var serverSocketFD: Int32 = -1
    private let queue = DispatchQueue(label: "org.zago.ipcserver", qos: .userInitiated, attributes: .concurrent)
    private var activeConnections: [String: Int32] = [:]
    private let lock = NSLock()
    private let jsonRPCParser: JSONRPCParser

    init(socketPath: String? = nil, sessionToken: String? = nil) {
        let pid = ProcessInfo.processInfo.processIdentifier
        if let socketPath {
            self.socketPath = socketPath
            self.tokenPath = socketPath + ".token"
        } else {
            self.socketPath = "/tmp/zago-\(pid).sock"
            self.tokenPath = "/tmp/zago-\(pid).token"
        }
        self.sessionToken = sessionToken ?? UUID().uuidString.replacingOccurrences(of: "-", with: "")
        self.jsonRPCParser = JSONRPCParser(sessionToken: self.sessionToken)
    }

    deinit {
        stop()
    }

    func start() throws {
        lock.lock()
        defer { lock.unlock() }

        guard !isListening else { return }

        unlink(socketPath)

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
            throw NSError(domain: "ZagoIPCServer", code: Int(errno), userInfo: [
                NSLocalizedDescriptionKey: "Failed to create UNIX domain socket"
            ])
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)

        let pathBytes = socketPath.utf8CString
        guard pathBytes.count <= MemoryLayout.size(ofValue: addr.sun_path) else {
            close(fd)
            throw NSError(domain: "ZagoIPCServer", code: 1, userInfo: [
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
            throw NSError(domain: "ZagoIPCServer", code: Int(errno), userInfo: [
                NSLocalizedDescriptionKey: "Failed to bind UNIX domain socket at \(socketPath)"
            ])
        }

        chmod(socketPath, S_IRUSR | S_IWUSR)
        try? sessionToken.write(toFile: tokenPath, atomically: true, encoding: .utf8)
        chmod(tokenPath, S_IRUSR | S_IWUSR)

        guard listen(fd, 16) == 0 else {
            close(fd)
            unlink(socketPath)
            throw NSError(domain: "ZagoIPCServer", code: Int(errno), userInfo: [
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
            jsonRPCParser.unregisterClient(connectionId: connectionId)
        }
        activeConnections.removeAll()
    }

    func handleRequest(_ request: JSONRPCRequest, connectionId: String) -> JSONRPCResponse {
        handleRequest(request, parser: jsonRPCParser)
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

            let connectionId = "conn-\(UUID().uuidString.prefix(8))"
            lock.lock()
            activeConnections[connectionId] = clientFD
            lock.unlock()

            queue.async { [weak self] in
                self?.handleClientConnection(clientFD: clientFD, connectionId: connectionId)
            }
        }
    }

    private func handleClientConnection(clientFD: Int32, connectionId: String) {
        defer {
            close(clientFD)
            lock.lock()
            activeConnections.removeValue(forKey: connectionId)
            lock.unlock()
            jsonRPCParser.unregisterClient(connectionId: connectionId)
        }

        var buffer = [UInt8](repeating: 0, count: 4096)
        var accumulatedData = Data()

        while isListening {
            let bytesRead = read(clientFD, &buffer, buffer.count)
            if bytesRead <= 0 {
                break
            }

            accumulatedData.append(buffer, count: bytesRead)

            while let newlineIndex = accumulatedData.firstIndex(of: UInt8(ascii: "\n")) {
                let lineData = accumulatedData.subdata(in: 0..<newlineIndex)
                accumulatedData.removeSubrange(0...newlineIndex)

                guard !lineData.isEmpty else { continue }

                let response = handleMessage(lineData, parser: jsonRPCParser)
                if let responseData = try? JSONEncoder().encode(response) {
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
}
#endif
