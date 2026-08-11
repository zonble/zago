import Foundation

public struct BufferInfo {
    public let bufferId: String
    public let filePath: String?
    public let fileName: String
    public let isModified: Bool
    public let isFocused: Bool

    public init(bufferId: String, filePath: String?, fileName: String, isModified: Bool, isFocused: Bool) {
        self.bufferId = bufferId
        self.filePath = filePath
        self.fileName = fileName
        self.isModified = isModified
        self.isFocused = isFocused
    }
}

/// Identity established by `zago.client.register` for exactly one IPC connection.
public struct IPCClientIdentity: Equatable, Sendable {
    public let clientId: String
    public let clientName: String
    public let agentType: String?
    public let color: String

    public init(clientId: String, clientName: String, agentType: String? = nil, color: String = "cyan") {
        self.clientId = clientId
        self.clientName = clientName
        self.agentType = agentType
        self.color = color
    }
}

public struct IPCHistoryEntry: Codable, Equatable, Sendable {
    public let id: String
    public let author: String
    public let reason: String
    public let action: String
    public let timestamp: String

    public init(id: String, author: String, reason: String, action: String, timestamp: String) {
        self.id = id
        self.author = author
        self.reason = reason
        self.action = action
        self.timestamp = timestamp
    }
}

public protocol ZagoIPCServerDataSource: AnyObject {
    func ipcServerGetBuffers(_ server: any ZagoIPCServer) -> [BufferInfo]
    func ipcServer(_ server: any ZagoIPCServer, textFor bufferTarget: String?, startLine: Int?, endLine: Int?) -> (lines: [String], totalLines: Int)?
    func ipcServer(_ server: any ZagoIPCServer, cursorFor bufferTarget: String?) -> (line: Int, column: Int, visualCol: Int, mode: String)?
    func ipcServer(_ server: any ZagoIPCServer, historyWithLimit limit: Int) -> [IPCHistoryEntry]
}

public protocol ZagoIPCServerDelegate: AnyObject {
    func ipcServer(_ server: any ZagoIPCServer, showPreviewFor client: IPCClientIdentity, reason: String, affectedFiles: [AffectedFilePayload]) -> Bool
    func ipcServer(_ server: any ZagoIPCServer, executeLogo script: String, mode: String?) -> (success: Bool, result: String, error: String?)
    func ipcServer(_ server: any ZagoIPCServer, clientDidDisconnect client: IPCClientIdentity)
}

public extension ZagoIPCServerDelegate {
    func ipcServer(_ server: any ZagoIPCServer, clientDidDisconnect client: IPCClientIdentity) {}
}
