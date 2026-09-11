import Config
import Editor
import FileWatcher
import Foundation
import TextEncoding

public final class LocalEditorFileIOStrategy: EditorFileIOStrategy, @unchecked Sendable {
    public static let shared = LocalEditorFileIOStrategy()

    private let fileManager: FileManager
    private let fileWatcher = FileWatcher()

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func normalizePath(_ path: String, isDirectory: Bool = false) -> String {
        let cleaned = FilePathNormalizer.fileURLToPath(path)
        let expanded = expandTilde(cleaned)
        let absolutePath: String
        if isAbsolutePath(expanded) {
            absolutePath = expanded
        } else {
            let cwd = currentDirectoryPath()
            absolutePath = URL(fileURLWithPath: cwd, isDirectory: true).appendingPathComponent(expanded).path
        }
        let standardized = URL(fileURLWithPath: absolutePath, isDirectory: isDirectory).standardizedFileURL.path
        #if os(Windows)
            return standardized.replacingOccurrences(of: "/", with: "\\")
        #else
            return standardized
        #endif
    }

    private func isAbsolutePath(_ path: String) -> Bool {
        #if os(Windows)
            if path.count >= 2 {
                let first = path[path.startIndex]
                let second = path[path.index(after: path.startIndex)]
                if first.isLetter && second == ":" {
                    return true
                }
            }
            if path.hasPrefix("\\\\") || path.hasPrefix("//") {
                return true
            }
            if path.hasPrefix("/") || path.hasPrefix("\\") {
                return true
            }
            return false
        #else
            return path.hasPrefix("/")
        #endif
    }

    public func homeDirectoryPath() -> String {
        let home = fileManager.homeDirectoryForCurrentUser.path
        #if os(Windows)
            return home.replacingOccurrences(of: "/", with: "\\")
        #else
            return home
        #endif
    }

    public func currentDirectoryPath() -> String {
        let cwd = fileManager.currentDirectoryPath
        #if os(Windows)
            return cwd.replacingOccurrences(of: "/", with: "\\")
        #else
            return cwd
        #endif
    }

    public func parentDirectory(of path: String) -> String {
        let normalized = normalizePath(path, isDirectory: true)
        let parent = URL(fileURLWithPath: normalized, isDirectory: true).deletingLastPathComponent().path
        #if os(Windows)
            return parent.replacingOccurrences(of: "/", with: "\\")
        #else
            return parent
        #endif
    }

    public func childPath(_ name: String, in directory: String) -> String {
        let normalizedDir = normalizePath(directory, isDirectory: true)
        let child = URL(fileURLWithPath: normalizedDir, isDirectory: true).appendingPathComponent(name).path
        #if os(Windows)
            return child.replacingOccurrences(of: "/", with: "\\")
        #else
            return child
        #endif
    }

    public func fileInfo(at path: String) -> EditorFileInfo {
        let normalized = normalizePath(path, isDirectory: false)
        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: normalized, isDirectory: &isDir)
        guard exists else {
            return EditorFileInfo(exists: false, isDirectory: false)
        }

        let attrs = try? fileManager.attributesOfItem(atPath: normalized)
        return EditorFileInfo(
            exists: true,
            isDirectory: isDir.boolValue,
            isBinary: isDir.boolValue ? false : isBinaryFile(at: normalized),
            isExecutable: isDir.boolValue ? false : fileManager.isExecutableFile(atPath: normalized),
            creationDate: attrs?[.creationDate] as? Date,
            modificationDate: attrs?[.modificationDate] as? Date,
            size: isDir.boolValue ? 0 : EditorFileInfo.fileSize(from: attrs)
        )
    }

    public func readTextFile(at path: String) throws -> TextReadResult {
        let normalized = normalizePath(path, isDirectory: false)
        let data = try Data(contentsOf: URL(fileURLWithPath: normalized))
        guard let result = TextEncodingDetector.detectAndDecode(data) else {
            throw CocoaError(.fileReadInapplicableStringEncoding)
        }
        return result
    }

    public func writeTextFile(_ contents: String, to path: String, encoding: String.Encoding) throws {
        let normalized = normalizePath(path, isDirectory: false)
        // NOTE (Cross-Platform Pitfall): On Windows (swift-corelibs-foundation using WideCharToMultiByte),
        // contents.data(using: encoding, allowLossyConversion: false) may silently replace unmappable
        // characters (e.g. Emoji in Big5) with default fallback characters ('?') instead of returning nil.
        // We perform a strict roundtrip equality check (roundtrip == contents) to ensure non-lossy
        // encoding validation consistently across macOS, Linux, and Windows.
        guard let data = contents.data(using: encoding, allowLossyConversion: false),
            let roundtrip = String(data: data, encoding: encoding),
            roundtrip == contents
        else {
            throw EncodingError.unsupportedCharacters
        }
        let parentDir = parentDirectory(of: normalized)
        if !fileManager.fileExists(atPath: parentDir) {
            try fileManager.createDirectory(atPath: parentDir, withIntermediateDirectories: true)
        }
        fileWatcher.stop()
        #if os(Windows)
            // On Windows, virtual/cloud file systems (e.g. Google Drive, OneDrive) and locked directories
            // fail when using atomic file replacement. Write directly to the destination file.
            try data.write(to: URL(fileURLWithPath: normalized), options: [])
        #else
            do {
                try data.write(to: URL(fileURLWithPath: normalized), options: .atomic)
            } catch {
                try data.write(to: URL(fileURLWithPath: normalized), options: [])
            }
        #endif
        fileWatcher.start(path: normalized)
        fileWatcher.recordCurrentModificationDate()
    }

    public func listDirectory(at path: String) throws -> [EditorDirectoryEntry] {
        let normalized = normalizePath(path, isDirectory: true)
        return try fileManager.contentsOfDirectory(atPath: normalized).map { name in
            let fullPath = childPath(name, in: normalized)
            let info = fileInfo(at: fullPath)
            return EditorDirectoryEntry(
                name: name,
                path: fullPath,
                isDirectory: info.isDirectory,
                isExecutable: info.isExecutable,
                creationDate: info.creationDate,
                modificationDate: info.modificationDate,
                size: info.size
            )
        }
    }

    public func copyFile(at sourcePath: String, to targetPath: String) throws {
        let normalizedSource = normalizePath(sourcePath, isDirectory: false)
        let normalizedTarget = normalizePath(targetPath, isDirectory: false)
        let targetDir = parentDirectory(of: normalizedTarget)
        if !fileManager.fileExists(atPath: targetDir) {
            try fileManager.createDirectory(atPath: targetDir, withIntermediateDirectories: true)
        }
        if fileManager.fileExists(atPath: normalizedTarget) {
            try fileManager.removeItem(atPath: normalizedTarget)
        }
        try fileManager.copyItem(atPath: normalizedSource, toPath: normalizedTarget)
    }

    public func isDirectoryWritable(at path: String) -> Bool {
        let normalized = normalizePath(path, isDirectory: true)
        return fileManager.isWritableFile(atPath: normalized)
    }

    public func temporaryDirectoryPath() -> String {
        fileManager.temporaryDirectory.path
    }

    public func documentDirectoryPath() -> String {
        if let docsUrl = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first,
            fileManager.fileExists(atPath: docsUrl.path)
        {
            return docsUrl.path
        }
        let home = homeDirectoryPath()
        let candidate = childPath("Documents", in: home)
        if fileInfo(at: candidate).exists {
            return candidate
        }
        return home
    }

    public func startWatchingFile(at path: String, onChange: @escaping @Sendable () -> Void) {
        fileWatcher.onChange = {
            onChange()
        }
        fileWatcher.start(path: normalizePath(path, isDirectory: false))
    }

    public func stopWatchingFile(at path: String) {
        fileWatcher.stop()
    }

    private func expandTilde(_ path: String) -> String {
        #if os(Windows)
            let hasTildePrefix = path == "~" || path.hasPrefix("~/") || path.hasPrefix("~\\")
        #else
            let hasTildePrefix = path == "~" || path.hasPrefix("~/")
        #endif
        guard hasTildePrefix else {
            return path
        }

        let home = homeDirectoryPath()
        guard path.count > 1 else {
            return home
        }

        let rest = String(path.dropFirst(2))
        #if os(Windows)
            let components = rest.split(whereSeparator: { $0 == "/" || $0 == "\\" }).map(String.init)
        #else
            let components = rest.split(separator: "/").map(String.init)
        #endif
        return components.reduce(URL(fileURLWithPath: home, isDirectory: true)) { url, component in
            url.appendingPathComponent(component)
        }.path
    }

    private func isBinaryFile(at path: String) -> Bool {
        let url = URL(fileURLWithPath: path)
        guard let fileData = try? Data(contentsOf: url, options: [.uncached]) else {
            return true
        }
        let data = Data(fileData.prefix(8192))
        if data.isEmpty { return false }
        let hasUTF16BOM =
            (data.count >= 2 && ((data[0] == 0xFE && data[1] == 0xFF) || (data[0] == 0xFF && data[1] == 0xFE)))
        if !hasUTF16BOM && data.contains(0) {
            return true
        }

        // Delegate multi-encoding detection with sample boundary truncation trimming (1..3 bytes) to TextEncodingDetector
        return TextEncodingDetector.detectAndDecode(data) == nil
    }
}
