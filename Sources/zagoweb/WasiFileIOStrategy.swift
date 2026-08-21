import Editor
import Foundation
import TextEncoding

public final class WasiFileIOStrategy: EditorFileIOStrategy, @unchecked Sendable {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func normalizePath(_ path: String, isDirectory: Bool = false) -> String {
        if path.hasPrefix("/") {
            return (path as NSString).standardizingPath
        }
        if path.isEmpty || path == "." {
            return "/workspace"
        }
        let current = currentDirectoryPath()
        return (current as NSString).appendingPathComponent(path)
    }

    public func homeDirectoryPath() -> String {
        "/workspace"
    }

    public func currentDirectoryPath() -> String {
        "/workspace"
    }

    public func parentDirectory(of path: String) -> String {
        let parent = URL(fileURLWithPath: path, isDirectory: true).deletingLastPathComponent().path
        return parent.isEmpty ? "/workspace" : parent
    }

    public func childPath(_ name: String, in directory: String) -> String {
        URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent(name).path
    }

    public func fileInfo(at path: String) -> EditorFileInfo {
        let normalized = normalizePath(path)
        if normalized == "/workspace" || normalized == "/" {
            return EditorFileInfo(
                exists: true,
                isDirectory: true,
                isBinary: false,
                isExecutable: false,
                modificationDate: Date()
            )
        }

        var isDir: ObjCBool = false
        var exists = fileManager.fileExists(atPath: normalized, isDirectory: &isDir)
        if !exists && normalized.hasPrefix("/workspace/") {
            let rel = String(normalized.dropFirst("/workspace/".count))
            exists = fileManager.fileExists(atPath: rel, isDirectory: &isDir)
        }
        let isDirectory = isDir.boolValue
        var modificationDate: Date? = nil

        if exists, let attrs = (try? fileManager.attributesOfItem(atPath: normalized)) ?? (try? fileManager.attributesOfItem(atPath: ".")) {
            modificationDate = attrs[.modificationDate] as? Date
        }

        return EditorFileInfo(
            exists: exists,
            isDirectory: isDirectory,
            isBinary: false,
            isExecutable: false,
            modificationDate: modificationDate
        )
    }

    public func listDirectory(at path: String) throws -> [EditorDirectoryEntry] {
        let normalized = normalizePath(path, isDirectory: true)
        let candidates = [normalized, ".", String(normalized.dropFirst("/workspace/".count))]

        var items: [String] = []
        for candidate in candidates {
            if let list = try? fileManager.contentsOfDirectory(atPath: candidate), !list.isEmpty {
                items = list
                break
            }
        }
        if items.isEmpty {
            items = (try? fileManager.contentsOfDirectory(atPath: normalized)) ?? []
        }

        return items.map { name in
            let full = (normalized as NSString).appendingPathComponent(name)
            var isDir: ObjCBool = false
            var exists = fileManager.fileExists(atPath: full, isDirectory: &isDir)
            if !exists {
                exists = fileManager.fileExists(atPath: name, isDirectory: &isDir)
            }
            return EditorDirectoryEntry(
                name: name,
                path: full,
                isDirectory: isDir.boolValue,
                isExecutable: false
            )
        }
    }

    public func readTextFile(at path: String) throws -> TextReadResult {
        let normalized = normalizePath(path)
        let url = URL(fileURLWithPath: normalized)
        let data: Data
        if let d = try? Data(contentsOf: url) {
            data = d
        } else {
            let relUrl = URL(fileURLWithPath: String(normalized.dropFirst("/workspace/".count)))
            data = try Data(contentsOf: relUrl)
        }

        if let detected = TextEncodingDetector.detectAndDecode(data) {
            return detected
        }
        if let utf8 = String(data: data, encoding: .utf8) {
            return TextReadResult(content: utf8, encoding: .utf8)
        }
        return TextReadResult(content: String(decoding: data, as: UTF8.self), encoding: .utf8)
    }

    public func writeTextFile(_ contents: String, to path: String, encoding: String.Encoding) throws {
        guard let data = contents.data(using: encoding, allowLossyConversion: false) ?? contents.data(using: .utf8) else {
            throw EncodingError.unsupportedCharacters
        }
        let normalized = normalizePath(path)
        let url = URL(fileURLWithPath: normalized)
        do {
            try data.write(to: url)
        } catch {
            let relUrl = URL(fileURLWithPath: String(normalized.dropFirst("/workspace/".count)))
            try data.write(to: relUrl)
        }
    }

    public func startWatchingFile(at path: String, onChange: @escaping () -> Void) {}
    public func stopWatchingFile() {}
    public func recordCurrentModificationDate() {}
}
