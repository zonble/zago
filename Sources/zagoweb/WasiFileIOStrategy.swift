import Editor
import Foundation
import TextEncoding

#if canImport(WASILibc)
    import WASILibc
#endif

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
        if normalized == "/workspace" || normalized == "/" || normalized == "." {
            return EditorFileInfo(
                exists: true,
                isDirectory: true,
                isBinary: false,
                isExecutable: false,
                modificationDate: Date()
            )
        }

        let rel =
            normalized.hasPrefix("/workspace/")
            ? String(normalized.dropFirst("/workspace/".count))
            : (normalized.hasPrefix("/") ? String(normalized.dropFirst()) : normalized)
        let queryPath = rel.isEmpty ? "." : rel

        #if canImport(WASILibc)
            var statBuf = stat()
            if fstatat(AT_FDCWD, queryPath, &statBuf, 0) == 0 {
                let isDir = (statBuf.st_mode & S_IFMT) == S_IFDIR
                return EditorFileInfo(
                    exists: true,
                    isDirectory: isDir,
                    isBinary: false,
                    isExecutable: false,
                    modificationDate: Date(timeIntervalSince1970: TimeInterval(statBuf.st_mtim.tv_sec)),
                    size: isDir ? 0 : Int64(statBuf.st_size)
                )
            }
        #endif

        var isDir: ObjCBool = false
        let exists = fileManager.fileExists(atPath: queryPath, isDirectory: &isDir)
        return EditorFileInfo(
            exists: exists,
            isDirectory: isDir.boolValue,
            isBinary: false,
            isExecutable: false,
            modificationDate: Date()
        )
    }

    public func listDirectory(at path: String) throws -> [EditorDirectoryEntry] {
        let normalized = normalizePath(path, isDirectory: true)
        let rel =
            normalized.hasPrefix("/workspace/")
            ? String(normalized.dropFirst("/workspace/".count))
            : (normalized == "/workspace"
                ? "." : (normalized.hasPrefix("/") ? String(normalized.dropFirst()) : normalized))
        let dirPath = rel.isEmpty ? "." : rel

        #if canImport(WASILibc)
            if let dir = WASILibc.opendir(dirPath) {
                defer { WASILibc.closedir(dir) }
                var entries: [EditorDirectoryEntry] = []
                let dNameOffset = (MemoryLayout<dirent>.offset(of: \dirent.d_type) ?? 8) + MemoryLayout<UInt8>.size
                while let entry = WASILibc.readdir(dir) {
                    let namePtr = UnsafeRawPointer(entry).advanced(by: dNameOffset).assumingMemoryBound(to: CChar.self)
                    let name = String(cString: namePtr)
                    if name.isEmpty || name == "." || name == ".." {
                        continue
                    }
                    let full = (normalized as NSString).appendingPathComponent(name)
                    // In WASI preview 1 dirent: FILETYPE_DIRECTORY = 3, FILETYPE_REGULAR_FILE = 4
                    var isDir = entry.pointee.d_type == 3
                    let childRel = dirPath == "." ? name : "\(dirPath)/\(name)"
                    var statBuf = stat()
                    if fstatat(AT_FDCWD, childRel, &statBuf, 0) == 0 {
                        isDir = (statBuf.st_mode & S_IFMT) == S_IFDIR
                    }
                    entries.append(
                        EditorDirectoryEntry(
                            name: name,
                            path: full,
                            isDirectory: isDir,
                            isExecutable: false
                        ))
                }
                return entries
            }
        #endif

        let candidates = [
            dirPath,
            normalized,
            ".",
        ]

        var items: [String] = []
        for candidate in candidates {
            if let list = try? fileManager.contentsOfDirectory(atPath: candidate), !list.isEmpty {
                items = list
                break
            }
        }

        return items.map { name in
            let full = (normalized as NSString).appendingPathComponent(name)
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
        let normalized = normalizePath(path)
        let rel =
            normalized.hasPrefix("/workspace/")
            ? String(normalized.dropFirst("/workspace/".count))
            : (normalized.hasPrefix("/") ? String(normalized.dropFirst()) : normalized)

        #if canImport(WASILibc)
            let fd = WASILibc.open(rel, O_RDONLY)
            if fd >= 0 {
                defer { WASILibc.close(fd) }
                var data = Data()
                var buf = [UInt8](repeating: 0, count: 4096)
                while true {
                    let n = WASILibc.read(fd, &buf, buf.count)
                    if n <= 0 { break }
                    data.append(buf, count: Int(n))
                }
                if let utf8 = String(data: data, encoding: .utf8) {
                    return TextReadResult(content: utf8, encoding: .utf8)
                }
                return TextReadResult(content: String(decoding: data, as: UTF8.self), encoding: .utf8)
            }
        #endif

        let data = try Data(contentsOf: URL(fileURLWithPath: rel))
        if let utf8 = String(data: data, encoding: .utf8) {
            return TextReadResult(content: utf8, encoding: .utf8)
        }
        return TextReadResult(content: String(decoding: data, as: UTF8.self), encoding: .utf8)
    }

    public func writeTextFile(_ contents: String, to path: String, encoding: String.Encoding) throws {
        guard let data = contents.data(using: encoding, allowLossyConversion: false) ?? contents.data(using: .utf8)
        else {
            throw EncodingError.unsupportedCharacters
        }
        let normalized = normalizePath(path)
        let rel =
            normalized.hasPrefix("/workspace/")
            ? String(normalized.dropFirst("/workspace/".count))
            : (normalized.hasPrefix("/") ? String(normalized.dropFirst()) : normalized)

        #if canImport(WASILibc)
            let oCreat: Int32 = 0x1000  // __WASI_OFLAGS_CREAT << 12
            let oTrunc: Int32 = 0x8000  // __WASI_OFLAGS_TRUNC << 12
            let fd = WASILibc.open(rel, O_WRONLY | oCreat | oTrunc, 0o644)
            if fd >= 0 {
                defer { WASILibc.close(fd) }
                data.withUnsafeBytes { ptr in
                    if let base = ptr.baseAddress {
                        _ = WASILibc.write(fd, base, ptr.count)
                    }
                }
                return
            }
        #endif

        try data.write(to: URL(fileURLWithPath: rel))
    }

    public func startWatchingFile(at path: String, onChange: @escaping () -> Void) {}
    public func stopWatchingFile() {}
    public func recordCurrentModificationDate() {}
}
