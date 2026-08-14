import Foundation

/// Monitors a file path for external file system modifications.
public final class FileWatcher: @unchecked Sendable {
    private let implementation: any PlatformFileWatcher

    public var onChange: (() -> Void)? {
        get { implementation.onChange }
        set { implementation.onChange = newValue }
    }

    public init() {
        self.implementation = makePlatformFileWatcher()
    }

    /// Starts monitoring the file at path for changes.
    public func start(path: String) {
        implementation.start(path: path)
    }

    /// Stops watching the current file.
    public func stop() {
        implementation.stop()
    }

    /// Records current modification date of watched file to suppress self-save change notifications.
    public func recordCurrentModificationDate() {
        implementation.recordCurrentModificationDate()
    }

    deinit {
        stop()
    }
}

protocol PlatformFileWatcher: AnyObject, Sendable {
    var onChange: (() -> Void)? { get set }
    func start(path: String)
    func stop()
    func recordCurrentModificationDate()
}

#if canImport(Darwin)
    private func makePlatformFileWatcher() -> any PlatformFileWatcher {
        DarwinFileWatcher()
    }
#elseif os(Windows)
    private func makePlatformFileWatcher() -> any PlatformFileWatcher {
        WindowsFileWatcher()
    }
#else
    private func makePlatformFileWatcher() -> any PlatformFileWatcher {
        PollingFileWatcher()
    }
#endif
