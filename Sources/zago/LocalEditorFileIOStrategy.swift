import Editor
import Foundation

public final class LocalEditorFileIOStrategy: EditorFileIOStrategy, @unchecked Sendable {
    public static let shared = LocalEditorFileIOStrategy()

    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func normalizePath(_ path: String, isDirectory: Bool = false) -> String {
        let expanded = expandTilde(path)
        guard isDirectory else {
            return expanded
        }
        return URL(fileURLWithPath: expanded, isDirectory: true).standardizedFileURL.path
    }

    public func homeDirectoryPath() -> String {
        fileManager.homeDirectoryForCurrentUser.path
    }

    public func currentDirectoryPath() -> String {
        fileManager.currentDirectoryPath
    }

    public func parentDirectory(of path: String) -> String {
        URL(fileURLWithPath: path, isDirectory: true).deletingLastPathComponent().path
    }

    public func childPath(_ name: String, in directory: String) -> String {
        URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent(name).path
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
            modificationDate: attrs?[.modificationDate] as? Date
        )
    }

    public func readTextFile(at path: String) throws -> String {
        try String(contentsOfFile: normalizePath(path, isDirectory: false), encoding: .utf8)
    }

    public func writeTextFile(_ contents: String, to path: String) throws {
        try contents.write(toFile: normalizePath(path, isDirectory: false), atomically: true, encoding: .utf8)
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
                isExecutable: info.isExecutable
            )
        }
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
        if data.contains(0) { return true }
        return String(data: data, encoding: .utf8) == nil
    }
}
