import Foundation

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

struct ZagoIPCSession: Codable, Equatable, Sendable {
    let instanceId: String
    let endpointPath: String
    let tokenPath: String
}

protocol ZagoIPCSessionLocating {
    func sessions() -> [ZagoIPCSession]
}

struct DefaultZagoIPCSessionLocator: ZagoIPCSessionLocating {
    let temporaryDirectories: [URL]

    init(temporaryDirectory: URL? = nil) {
        if let temporaryDirectory {
            self.temporaryDirectories = [temporaryDirectory]
        } else {
            self.temporaryDirectories = ZagoIPCSessionPaths.candidateTemporaryDirectories()
        }
    }

    func sessions() -> [ZagoIPCSession] {
        #if os(Windows)
            return []
        #else
            let fileManager = FileManager.default

            return
                temporaryDirectories
                .flatMap { temporaryDirectory -> [URL] in
                    (try? fileManager.contentsOfDirectory(
                        at: temporaryDirectory,
                        includingPropertiesForKeys: [.contentModificationDateKey],
                        options: [.skipsHiddenFiles]
                    )) ?? []
                }
                .filter { $0.lastPathComponent.hasPrefix("zago-") && $0.pathExtension == "sock" }
                .filter { $0.path.utf8CString.count <= ZagoIPCSessionPaths.unixSocketPathByteLimit }
                .compactMap { socketURL -> (ZagoIPCSession, Date)? in
                    let standardTokenURL = socketURL.deletingPathExtension().appendingPathExtension("token")
                    let explicitPathTokenURL = URL(fileURLWithPath: socketURL.path + ".token")
                    let tokenURL: URL
                    if fileManager.fileExists(atPath: standardTokenURL.path) {
                        tokenURL = standardTokenURL
                    } else if fileManager.fileExists(atPath: explicitPathTokenURL.path) {
                        tokenURL = explicitPathTokenURL
                    } else {
                        return nil
                    }

                    let resourceValues = try? socketURL.resourceValues(forKeys: [.contentModificationDateKey])
                    let instanceId = socketURL.deletingPathExtension().lastPathComponent
                    return (
                        ZagoIPCSession(
                            instanceId: instanceId,
                            endpointPath: socketURL.path,
                            tokenPath: tokenURL.path
                        ),
                        resourceValues?.contentModificationDate ?? .distantPast
                    )
                }
                .sorted { lhs, rhs in
                    if lhs.1 == rhs.1 {
                        return lhs.0.instanceId < rhs.0.instanceId
                    }
                    return lhs.1 > rhs.1
                }
                .map(\.0)
        #endif
    }
}

enum ZagoIPCClientError: LocalizedError {
    case noActiveSession
    case selectedSessionUnavailable(String)
    case unsupportedPlatform
    case invalidToken(String)
    case endpointPathTooLong(String)
    case connectionFailed(String)
    case writeFailed
    case responseTooLarge
    case disconnected
    case invalidResponse
    case rpc(code: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .noActiveSession:
            "No active zago editor session was found. Start zago with IPC enabled."
        case .selectedSessionUnavailable(let instanceId):
            "The selected zago instance '\(instanceId)' is no longer available."
        case .unsupportedPlatform:
            "The zago MCP bridge cannot connect on this platform because Windows named-pipe IPC is not implemented yet."
        case .invalidToken(let path):
            "The zago IPC session token could not be read at \(path)."
        case .endpointPathTooLong(let path):
            "The zago IPC endpoint path is too long: \(path)"
        case .connectionFailed(let path):
            "Could not connect to the zago IPC endpoint at \(path)."
        case .writeFailed:
            "Could not write a request to the zago IPC connection."
        case .responseTooLarge:
            "The zago IPC response exceeded the maximum supported size."
        case .disconnected:
            "The zago IPC connection closed before returning a complete response."
        case .invalidResponse:
            "The zago IPC server returned an invalid response."
        case .rpc(let code, let message):
            "zago IPC error [\(code)]: \(message)"
        }
    }
}

struct IPCBufferResult: Codable, Sendable {
    let bufferId: String
    let filePath: String?
    let fileName: String
    let isModified: Bool
    let isFocused: Bool
}

struct IPCBuffersResult: Codable, Sendable {
    let buffers: [IPCBufferResult]
    let activeBufferId: String
}

struct IPCTextResult: Codable, Sendable {
    let lines: [String]
    let totalLines: Int
}

struct IPCSelectionResult: Codable, Sendable {
    let hasSelection: Bool
    let text: String
    let lines: [String]
    let startLine: Int?
    let startColumn: Int?
    let endLine: Int?
    let endColumn: Int?
}

struct IPCCursorResult: Codable, Sendable {
    let line: Int
    let column: Int
    let canvasVisualColumn: Int
    let mode: String
}

struct IPCPreviewResult: Codable, Sendable {
    let success: Bool
    let previewActive: Bool
}

struct IPCLogoResult: Codable, Sendable {
    let success: Bool
    let lastResult: String
    let error: String?
}

final class ZagoIPCClient {
    private struct OutboundRequest<Params: Encodable>: Encodable {
        let jsonrpc = "2.0"
        let method: String
        let params: Params
        let id: JSONRPCId
    }

    private struct InboundResponse<Result: Decodable>: Decodable {
        let result: Result?
        let error: JSONRPCError?
    }

    private struct RegistrationResult: Decodable {
        let registered: Bool
    }

    private let clientIdPrefix: String
    private let clientName: String
    private let maxResponseBytes: Int

    init(
        clientId: String = "zago-mcp-\(UUID().uuidString.lowercased())",
        clientName: String = "zago MCP",
        maxResponseBytes: Int = 1_048_576
    ) {
        self.clientIdPrefix = clientId
        self.clientName = clientName
        self.maxResponseBytes = maxResponseBytes
    }

    func getBuffers(in session: ZagoIPCSession) throws -> IPCBuffersResult {
        try call(method: "zago.buffer.getBuffers", params: EmptyParams(), in: session)
    }

    func getText(
        bufferTarget: String?,
        startLine: Int?,
        endLine: Int?,
        in session: ZagoIPCSession
    ) throws -> IPCTextResult {
        try call(
            method: "zago.buffer.getText",
            params: GetTextParams(
                bufferTarget: bufferTarget,
                bufferId: nil,
                startLine: startLine,
                endLine: endLine
            ),
            in: session
        )
    }

    func getCursor(bufferTarget: String?, in session: ZagoIPCSession) throws -> IPCCursorResult {
        try call(
            method: "zago.buffer.getCursor",
            params: GetCursorParams(bufferTarget: bufferTarget, bufferId: nil),
            in: session
        )
    }

    func getSelection(bufferTarget: String?, in session: ZagoIPCSession) throws -> IPCSelectionResult {
        try call(
            method: "zago.buffer.getSelection",
            params: GetSelectionParams(bufferTarget: bufferTarget, bufferId: nil),
            in: session
        )
    }

    func showPreview(
        reason: String,
        affectedFiles: [AffectedFilePayload],
        in session: ZagoIPCSession
    ) throws -> IPCPreviewResult {
        let clientId = makeClientId()
        let result: IPCPreviewResult = try call(
            method: "zago.overlay.showPreview",
            params: OverlayPreviewParams(
                clientId: clientId,
                reason: reason,
                affectedFiles: affectedFiles
            ),
            in: session,
            clientId: clientId
        )
        return result
    }

    func executeLogo(script: String, in session: ZagoIPCSession) throws -> IPCLogoResult {
        let result: IPCLogoResult = try call(
            method: "zago.buffer.executeLogo",
            params: ExecuteLogoParams(script: script, mode: "headful"),
            in: session
        )
        return result
    }

    private func call<Params: Encodable, Result: Decodable>(
        method: String,
        params: Params,
        in session: ZagoIPCSession,
        clientId: String? = nil
    ) throws -> Result {
        #if os(Windows)
            throw ZagoIPCClientError.unsupportedPlatform
        #else
            let tokenData: Data
            do {
                tokenData = try Data(contentsOf: URL(fileURLWithPath: session.tokenPath))
            } catch {
                throw ZagoIPCClientError.invalidToken(session.tokenPath)
            }
            guard
                let token = String(data: tokenData, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                !token.isEmpty
            else {
                throw ZagoIPCClientError.invalidToken(session.tokenPath)
            }

            let fileDescriptor = try connect(to: session.endpointPath)
            defer { close(fileDescriptor) }

            let connectionClientId = clientId ?? makeClientId()
            let registration: RegistrationResult = try exchange(
                OutboundRequest(
                    method: "zago.client.register",
                    params: ClientRegistrationParams(
                        auth: token,
                        clientId: connectionClientId,
                        clientName: clientName,
                        agentType: "mcp",
                        color: "cyan"
                    ),
                    id: .int(1)
                ),
                on: fileDescriptor
            )
            guard registration.registered else {
                throw ZagoIPCClientError.invalidResponse
            }

            return try exchange(
                OutboundRequest(method: method, params: params, id: .int(2)),
                on: fileDescriptor
            )
        #endif
    }

    private func makeClientId() -> String {
        "\(clientIdPrefix)-\(UUID().uuidString.lowercased())"
    }

    #if !os(Windows)
        private func connect(to path: String) throws -> Int32 {
            #if canImport(Glibc)
                let socketType = Int32(SOCK_STREAM.rawValue)
            #else
                let socketType = Int32(SOCK_STREAM)
            #endif
            let fileDescriptor = socket(AF_UNIX, socketType, 0)
            guard fileDescriptor >= 0 else {
                throw ZagoIPCClientError.connectionFailed(path)
            }

            var address = sockaddr_un()
            address.sun_family = sa_family_t(AF_UNIX)
            let pathBytes = path.utf8CString
            guard pathBytes.count <= MemoryLayout.size(ofValue: address.sun_path) else {
                close(fileDescriptor)
                throw ZagoIPCClientError.endpointPathTooLong(path)
            }

            withUnsafeMutablePointer(to: &address.sun_path) { pointer in
                let bytes = UnsafeMutableRawPointer(pointer).assumingMemoryBound(to: CChar.self)
                for (index, byte) in pathBytes.enumerated() {
                    bytes[index] = byte
                }
            }

            var timeout = timeval(tv_sec: 5, tv_usec: 0)
            _ = withUnsafePointer(to: &timeout) {
                setsockopt(
                    fileDescriptor,
                    SOL_SOCKET,
                    SO_RCVTIMEO,
                    $0,
                    socklen_t(MemoryLayout<timeval>.size)
                )
            }
            _ = withUnsafePointer(to: &timeout) {
                setsockopt(
                    fileDescriptor,
                    SOL_SOCKET,
                    SO_SNDTIMEO,
                    $0,
                    socklen_t(MemoryLayout<timeval>.size)
                )
            }

            let result = withUnsafePointer(to: &address) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    DarwinOrGlibc.connect(
                        fileDescriptor,
                        $0,
                        socklen_t(MemoryLayout<sockaddr_un>.size)
                    )
                }
            }
            guard result == 0 else {
                close(fileDescriptor)
                throw ZagoIPCClientError.connectionFailed(path)
            }
            return fileDescriptor
        }

        private func exchange<Request: Encodable, Result: Decodable>(
            _ request: Request,
            on fileDescriptor: Int32
        ) throws -> Result {
            var requestData = try JSONEncoder().encode(request)
            requestData.append(UInt8(ascii: "\n"))
            try writeAll(requestData, to: fileDescriptor)

            let responseData = try readLine(from: fileDescriptor)
            let response: InboundResponse<Result>
            do {
                response = try JSONDecoder().decode(InboundResponse<Result>.self, from: responseData)
            } catch {
                throw ZagoIPCClientError.invalidResponse
            }
            if let error = response.error {
                throw ZagoIPCClientError.rpc(code: error.code, message: error.message)
            }
            guard let result = response.result else {
                throw ZagoIPCClientError.invalidResponse
            }
            return result
        }

        private func writeAll(_ data: Data, to fileDescriptor: Int32) throws {
            var offset = 0
            while offset < data.count {
                let written = data.withUnsafeBytes { bytes -> Int in
                    guard let baseAddress = bytes.baseAddress else { return -1 }
                    return write(
                        fileDescriptor,
                        baseAddress.advanced(by: offset),
                        data.count - offset
                    )
                }
                if written < 0 && errno == EINTR { continue }
                guard written > 0 else { throw ZagoIPCClientError.writeFailed }
                offset += written
            }
        }

        private func readLine(from fileDescriptor: Int32) throws -> Data {
            var accumulated = Data()
            var buffer = [UInt8](repeating: 0, count: 4_096)

            while accumulated.count <= maxResponseBytes {
                let count = read(fileDescriptor, &buffer, buffer.count)
                if count < 0 && errno == EINTR { continue }
                guard count > 0 else { throw ZagoIPCClientError.disconnected }
                accumulated.append(buffer, count: count)

                if let newlineIndex = accumulated.firstIndex(of: UInt8(ascii: "\n")) {
                    return accumulated.prefix(upTo: newlineIndex)
                }
            }
            throw ZagoIPCClientError.responseTooLarge
        }
    #endif
}

#if !os(Windows)
    private enum DarwinOrGlibc {
        static func connect(
            _ socket: Int32,
            _ address: UnsafePointer<sockaddr>,
            _ addressLength: socklen_t
        ) -> Int32 {
            #if canImport(Darwin)
                Darwin.connect(socket, address, addressLength)
            #else
                Glibc.connect(socket, address, addressLength)
            #endif
        }
    }
#endif
