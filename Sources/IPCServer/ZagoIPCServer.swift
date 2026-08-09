import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif os(Windows)
import WinSDK
#endif

public protocol ZagoIPCServerDelegate: AnyObject {
    func ipcServer(_ server: ZagoIPCServer, didReceiveRequest request: JSONRPCRequest, connectionId: String) -> JSONRPCResponse
    func ipcServer(_ server: ZagoIPCServer, clientDidDisconnect connectionId: String)
}

public final class ZagoIPCServer: @unchecked Sendable {
    public weak var delegate: ZagoIPCServerDelegate?
    public private(set) var isListening: Bool = false
    public let socketPath: String
    public let sessionToken: String

    private var serverSocketFD: Int32 = -1
    private let queue = DispatchQueue(label: "org.zago.ipcserver", qos: .userInitiated, attributes: .concurrent)
    private var activeConnections: [String: Int32] = [:]
    private let lock = NSLock()

    public let tokenPath: String

    public init(socketPath: String? = nil, sessionToken: String? = nil) {
        let pid = ProcessInfo.processInfo.processIdentifier
        if let customPath = socketPath {
            self.socketPath = customPath
            self.tokenPath = customPath + ".token"
        } else {
            #if os(Windows)
            self.socketPath = #"\\.\pipe\zago-\#(pid)"#
            self.tokenPath = #"\\.\pipe\zago-\#(pid).token"#
            #else
            self.socketPath = "/tmp/zago-\(pid).sock"
            self.tokenPath = "/tmp/zago-\(pid).token"
            #endif
        }

        if let customToken = sessionToken {
            self.sessionToken = customToken
        } else {
            self.sessionToken = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        }
    }

    deinit {
        stop()
    }

    public func start() throws {
        lock.lock()
        defer { lock.unlock() }

        guard !isListening else { return }

        #if !os(Windows)
        // 1. Remove existing socket file if present
        unlink(socketPath)

        // 2. Create UNIX Domain Socket
        let fd = socket(AF_UNIX, SOCK_STREAM, 0)
        guard fd >= 0 else {
            throw NSError(domain: "ZagoIPCServer", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Failed to create UNIX domain socket"])
        }

        var addr = sockaddr_un()
        addr.sun_family = sa_family_t(AF_UNIX)
        
        let pathBytes = socketPath.utf8CString
        guard pathBytes.count <= MemoryLayout.size(ofValue: addr.sun_path) else {
            close(fd)
            throw NSError(domain: "ZagoIPCServer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Socket path exceeds sun_path buffer size"])
        }

        withUnsafeMutablePointer(to: &addr.sun_path) { ptr in
            let rawPtr = UnsafeMutableRawPointer(ptr).assumingMemoryBound(to: CChar.self)
            for (i, byte) in pathBytes.enumerated() {
                rawPtr[i] = byte
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
            throw NSError(domain: "ZagoIPCServer", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Failed to bind UNIX domain socket at \(socketPath)"])
        }

        // 3. Set strict POSIX 0600 permissions (Owner Read/Write only)
        chmod(socketPath, S_IRUSR | S_IWUSR)
        try? sessionToken.write(toFile: tokenPath, atomically: true, encoding: .utf8)
        chmod(tokenPath, S_IRUSR | S_IWUSR)

        // 4. Start listening (backlog: 16)
        guard listen(fd, 16) == 0 else {
            close(fd)
            unlink(socketPath)
            throw NSError(domain: "ZagoIPCServer", code: Int(errno), userInfo: [NSLocalizedDescriptionKey: "Failed to listen on socket"])
        }

        self.serverSocketFD = fd
        self.isListening = true

        queue.async { [weak self] in
            self?.acceptLoop()
        }
        #else
        // Windows Named Pipe Placeholder
        self.isListening = true
        #endif
    }

    public func stop() {
        lock.lock()
        defer { lock.unlock() }

        guard isListening else { return }
        isListening = false

        #if !os(Windows)
        if serverSocketFD >= 0 {
            close(serverSocketFD)
            serverSocketFD = -1
        }
        unlink(socketPath)
        unlink(tokenPath)

        for (connId, clientFD) in activeConnections {
            close(clientFD)
            delegate?.ipcServer(self, clientDidDisconnect: connId)
        }
        activeConnections.removeAll()
        #endif
    }

    #if !os(Windows)
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
            delegate?.ipcServer(self, clientDidDisconnect: connectionId)
        }

        var buffer = [UInt8](repeating: 0, count: 4096)
        var accumulatedData = Data()

        while isListening {
            let bytesRead = read(clientFD, &buffer, buffer.count)
            if bytesRead <= 0 {
                break
            }

            accumulatedData.append(buffer, count: bytesRead)

            // Line-delimited JSON-RPC messages
            while let newlineIndex = accumulatedData.firstIndex(of: UInt8(ascii: "\n")) {
                let lineData = accumulatedData.subdata(in: 0..<newlineIndex)
                accumulatedData.removeSubrange(0...newlineIndex)

                guard !lineData.isEmpty else { continue }

                let response = parseAndHandleMessage(lineData, connectionId: connectionId)
                if let responseData = try? JSONEncoder().encode(response) {
                    var outData = responseData
                    outData.append(UInt8(ascii: "\n"))
                    outData.withUnsafeBytes { ptr in
                        if let rawPtr = ptr.baseAddress {
                            var totalWritten = 0
                            let totalSize = outData.count
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
            }
        }
    }
    #endif

    private func parseAndHandleMessage(_ data: Data, connectionId: String) -> JSONRPCResponse {
        do {
            let request = try JSONDecoder().decode(JSONRPCRequest.self, from: data)
            if let delegate = delegate {
                return delegate.ipcServer(self, didReceiveRequest: request, connectionId: connectionId)
            } else {
                return JSONRPCResponse.failure(code: -32603, message: "Internal Error: No IPC delegate registered", id: request.id)
            }
        } catch {
            return JSONRPCResponse.failure(code: -32700, message: "Parse error: \(error.localizedDescription)", id: nil)
        }
    }
}
