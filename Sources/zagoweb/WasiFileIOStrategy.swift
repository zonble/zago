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
        let current = fileManager.currentDirectoryPath
        return (current as NSString).appendingPathComponent(path)
    }

    public func homeDirectoryPath() -> String {
        "/workspace"
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
        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
        let isDirectory = isDir.boolValue
        var modificationDate: Date? = nil

        if exists, let attrs = try? fileManager.attributesOfItem(atPath: path) {
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
        let items = try fileManager.contentsOfDirectory(atPath: path)
        return items.map { name in
            let full = (path as NSString).appendingPathComponent(name)
            var isDir: ObjCBool = false
            _ = fileManager.fileExists(atPath: full, isDirectory: &isDir)
            return EditorDirectoryEntry(
                name: name,
                path: full,
                isDirectory: isDir.boolValue,
                isExecutable: false
            )
        }
    }

    public func readTextFile(at path: String) throws -> TextReadResult {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
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
        let url = URL(fileURLWithPath: path)
        try data.write(to: url)
    }

    public func startWatchingFile(at path: String, onChange: @escaping () -> Void) {}
    public func stopWatchingFile() {}
    public func recordCurrentModificationDate() {}
}
