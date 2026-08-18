import Foundation

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

enum ZagoIPCSessionPaths {
    #if os(Windows)
        static let unixSocketPathByteLimit = Int.max
    #else
        static var unixSocketPathByteLimit: Int {
            let address = sockaddr_un()
            return max(0, MemoryLayout.size(ofValue: address.sun_path) - 1)
        }
    #endif

    static func candidateTemporaryDirectories() -> [URL] {
        var candidates: [URL] = [
            URL(fileURLWithPath: "/tmp", isDirectory: true),
            URL(fileURLWithPath: "/private/tmp", isDirectory: true),
            URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true),
        ]

        if let tmpDir = ProcessInfo.processInfo.environment["TMPDIR"], !tmpDir.isEmpty {
            candidates.append(URL(fileURLWithPath: tmpDir, isDirectory: true))
        }

        var seen: Set<String> = []
        return candidates.compactMap { url in
            let path = url.standardizedFileURL.path
            guard seen.insert(path).inserted else { return nil }
            return URL(fileURLWithPath: path, isDirectory: true)
        }
    }

    static func generatedSessionPaths(pid: Int32, nonce: String) -> (socketPath: String, tokenPath: String) {
        #if os(Windows)
            let instanceName = "zago-\(pid)-\(nonce)"
            let tokenName = "\(instanceName).token"
        #else
            let socketName = "zago-\(pid)-\(nonce).sock"
            let tokenName = "zago-\(pid)-\(nonce).token"
        #endif
        let fileManager = FileManager.default

        for directory in candidateTemporaryDirectories() {
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory), isDirectory.boolValue
            else {
                continue
            }

            #if os(Windows)
                return (
                    #"\\.\pipe\\#(instanceName)"#,
                    directory.appendingPathComponent(tokenName).path
                )
            #else
                let socketPath = directory.appendingPathComponent(socketName).path
                guard socketPath.utf8CString.count <= unixSocketPathByteLimit else { continue }
                return (
                    socketPath,
                    directory.appendingPathComponent(tokenName).path
                )
            #endif
        }

        let fallbackDirectory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        #if os(Windows)
            return (
                #"\\.\pipe\\#(instanceName)"#,
                fallbackDirectory.appendingPathComponent(tokenName).path
            )
        #else
            return (
                fallbackDirectory.appendingPathComponent(socketName).path,
                fallbackDirectory.appendingPathComponent(tokenName).path
            )
        #endif
    }
}
