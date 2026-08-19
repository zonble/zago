import Foundation

/// Manages active file watching subscriptions and lifecycle for editor buffers.
public final class FileWatcherCoordinator: @unchecked Sendable {
    public var fileIOStrategy: EditorFileIOStrategy
    public private(set) var currentWatchedPath: String?

    public init(fileIOStrategy: EditorFileIOStrategy) {
        self.fileIOStrategy = fileIOStrategy
    }

    /// Stops watching previous path and begins watching new path if specified.
    public func startWatching(path: String?, onChange: @escaping @Sendable () -> Void) {
        stopWatching()
        guard let path, !path.isEmpty else { return }
        currentWatchedPath = path
        fileIOStrategy.startWatchingFile(at: path, onChange: onChange)
    }

    /// Stops watching the currently active file path.
    public func stopWatching() {
        if let oldPath = currentWatchedPath {
            fileIOStrategy.stopWatchingFile(at: oldPath)
            currentWatchedPath = nil
        }
    }
}
