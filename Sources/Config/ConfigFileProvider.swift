import Foundation

/// Abstract interface for reading and writing configuration file contents across runtime environments
/// (Desktop Local FileSystem, WebAssembly Browser LocalStorage/HTTP, In-Memory Virtual FS).
public protocol ConfigFileProvider: Sendable {
    /// Returns current user's home directory path.
    func homeDirectoryPath() -> String

    /// Returns current working directory path.
    func currentDirectoryPath() -> String

    /// Returns whether a configuration file exists at specified path.
    func fileExists(atPath path: String) -> Bool

    /// Reads UTF-8 text string content at specified path.
    func readString(atPath path: String) throws -> String

    /// Writes UTF-8 text string content to specified path.
    func writeString(_ content: String, toPath path: String) throws
}

/// In-memory virtual file provider for testing and WASM browser environment injection.
public final class InMemoryConfigFileProvider: ConfigFileProvider, @unchecked Sendable {
    public let homePath: String
    public let currentPath: String
    public var files: [String: String]

    public init(
        homePath: String = "/home/user",
        currentPath: String = "/home/user",
        files: [String: String] = [:]
    ) {
        self.homePath = homePath
        self.currentPath = currentPath
        self.files = files
    }

    public func homeDirectoryPath() -> String {
        homePath
    }

    public func currentDirectoryPath() -> String {
        currentPath
    }

    public func fileExists(atPath path: String) -> Bool {
        files[path] != nil
    }

    public func readString(atPath path: String) throws -> String {
        guard let content = files[path] else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        return content
    }

    public func writeString(_ content: String, toPath path: String) throws {
        files[path] = content
    }
}
