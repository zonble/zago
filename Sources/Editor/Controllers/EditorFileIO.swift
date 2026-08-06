import Foundation
import TextEncoding

/// Errors thrown during encoding conversion or file saving.
public enum EncodingError: Error {
    /// Thrown when content contains characters that cannot be represented in the target encoding.
    case unsupportedCharacters
}

/// Metadata information about a file or directory.
public struct EditorFileInfo: Sendable, Equatable {
    /// Whether the file or directory exists on disk.
    public let exists: Bool
    /// Whether the path represents a directory.
    public let isDirectory: Bool
    /// Whether the file contains binary / non-printable characters.
    public let isBinary: Bool
    /// Whether the file has executable permissions.
    public let isExecutable: Bool
    /// Last modification timestamp, if available.
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

/// Directory entry item returned when listing folder contents.
public struct EditorDirectoryEntry: Sendable, Equatable {
    /// Entry file or folder name.
    public let name: String
    /// Absolute or normalized path to the item.
    public let path: String
    /// Whether this entry is a subdirectory.
    public let isDirectory: Bool
    /// Whether this entry is an executable file.
    public let isExecutable: Bool

    public init(name: String, path: String, isDirectory: Bool, isExecutable: Bool = false) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.isExecutable = isExecutable
    }
}

/// Abstract File System I/O strategy interface decoupling `Editor` from underlying storage.
///
/// Implement this protocol to customize file operations for different environments:
/// - Local disk filesystem (`LocalEditorFileIOStrategy`)
/// - In-memory mock filesystem for unit testing (`MemoryEditorFileIOStrategy`)
/// - Remote filesystems (SSH/SFTP, Cloud Storage, WebDAV)
public protocol EditorFileIOStrategy: AnyObject {
    /// Normalizes path string by expanding tildes (`~`), resolving relative components, and standardizing slashes.
    ///
    /// - Parameters:
    ///   - path: The raw input path.
    ///   - isDirectory: Whether target path is expected to be a directory.
    /// - Returns: A standardized absolute path string.
    func normalizePath(_ path: String, isDirectory: Bool) -> String

    /// Returns absolute path to current user's home directory (`~`).
    func homeDirectoryPath() -> String

    /// Returns absolute path to current working directory (`.`).
    func currentDirectoryPath() -> String

    /// Returns absolute path of parent directory containing target path.
    ///
    /// - Parameter path: Target file or directory path.
    /// - Returns: Absolute parent directory path.
    func parentDirectory(of path: String) -> String

    /// Joins parent directory path and child entry name into a normalized child path.
    ///
    /// - Parameters:
    ///   - name: Child file or folder name.
    ///   - directory: Parent directory path.
    /// - Returns: Combined child path string.
    func childPath(_ name: String, in directory: String) -> String

    /// Inspects target path metadata on storage.
    ///
    /// - Parameter path: Target path to inspect.
    /// - Returns: An `EditorFileInfo` metadata object describing existence, type, and permissions.
    func fileInfo(at path: String) -> EditorFileInfo

    /// Reads text file data from storage, auto-detecting character encoding.
    ///
    /// - Parameter path: Absolute path to text file.
    /// - Throws: An error if file does not exist or cannot be read.
    /// - Returns: A `TextReadResult` containing decoded text content and detected `String.Encoding`.
    func readTextFile(at path: String) throws -> TextReadResult

    /// Writes text string content to storage using target character encoding.
    ///
    /// - Parameters:
    ///   - contents: Text content to save.
    ///   - path: Target destination file path.
    ///   - encoding: Target character encoding (e.g. `.utf8`, `.big5`).
    /// - Throws: `EncodingError.unsupportedCharacters` if contents cannot be represented in target encoding, or file write error.
    func writeTextFile(_ contents: String, to path: String, encoding: String.Encoding) throws

    /// Lists directory child entries for file browser / DirectoryBuffer navigation.
    ///
    /// - Parameter path: Directory path to list.
    /// - Throws: An error if directory cannot be read.
    /// - Returns: Array of `EditorDirectoryEntry` items.
    func listDirectory(at path: String) throws -> [EditorDirectoryEntry]

    /// Registers file system watcher to receive change notifications when file is modified externally.
    ///
    /// - Parameters:
    ///   - path: Target file path to watch.
    ///   - onChange: Callback block invoked when external modification is detected.
    func startWatchingFile(at path: String, onChange: @escaping () -> Void)

    /// Stops watching external file system changes for specified path.
    ///
    /// - Parameter path: Target file path to unwatch.
    func stopWatchingFile(at path: String)
}

extension EditorFileIOStrategy {
    public func startWatchingFile(at path: String, onChange: @escaping () -> Void) {}
    public func stopWatchingFile(at path: String) {}
}
