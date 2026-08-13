import Config
import Foundation

/// Standard local desktop filesystem provider for `ConfigLoader`, injected from the `zago` target executable.
public struct LocalConfigFileProvider: ConfigFileProvider {
    public init() {}

    public func homeDirectoryPath() -> String {
        #if os(Windows)
            let environment = ProcessInfo.processInfo.environment
            if let userProfile = environment["USERPROFILE"], !userProfile.isEmpty {
                return userProfile
            }
            if let homeDrive = environment["HOMEDRIVE"], let homePath = environment["HOMEPATH"],
                !homeDrive.isEmpty, !homePath.isEmpty
            {
                return homeDrive + homePath
            }
        #endif
        return FileManager.default.homeDirectoryForCurrentUser.path
    }

    public func currentDirectoryPath() -> String {
        FileManager.default.currentDirectoryPath
    }

    public func fileExists(atPath path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    public func readString(atPath path: String) throws -> String {
        try String(contentsOfFile: path, encoding: .utf8)
    }

    public func writeString(_ content: String, toPath path: String) throws {
        try content.write(toFile: path, atomically: false, encoding: .utf8)
    }
}
