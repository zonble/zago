import Foundation

public struct EditorFileInfo: Sendable, Equatable {
    public let exists: Bool
    public let isDirectory: Bool
    public let isBinary: Bool
    public let isExecutable: Bool
    public let modificationDate: Date?

    public init(
        exists: Bool,
        isDirectory: Bool,
        isBinary: Bool = false,
        isExecutable: Bool = false,
        modificationDate: Date? = nil
    ) {
        self.exists = exists
        self.isDirectory = isDirectory
        self.isBinary = isBinary
        self.isExecutable = isExecutable
        self.modificationDate = modificationDate
    }
}

public struct EditorDirectoryEntry: Sendable, Equatable {
    public let name: String
    public let path: String
    public let isDirectory: Bool
    public let isExecutable: Bool

    public init(name: String, path: String, isDirectory: Bool, isExecutable: Bool = false) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.isExecutable = isExecutable
    }
}

public protocol EditorFileIOStrategy: AnyObject {
    func normalizePath(_ path: String, isDirectory: Bool) -> String
    func homeDirectoryPath() -> String
    func currentDirectoryPath() -> String
    func parentDirectory(of path: String) -> String
    func childPath(_ name: String, in directory: String) -> String
    func fileInfo(at path: String) -> EditorFileInfo
    func readTextFile(at path: String) throws -> String
    func writeTextFile(_ contents: String, to path: String) throws
    func listDirectory(at path: String) throws -> [EditorDirectoryEntry]
    func startWatchingFile(at path: String, onChange: @escaping () -> Void)
    func stopWatchingFile(at path: String)
}

extension EditorFileIOStrategy {
    public func startWatchingFile(at path: String, onChange: @escaping () -> Void) {}
    public func stopWatchingFile(at path: String) {}
}
