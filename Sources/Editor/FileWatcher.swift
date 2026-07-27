import Foundation

/// Monitors a file path for external file system modifications using DispatchSource.
public final class FileWatcher: @unchecked Sendable {
    private var fileDescriptor: Int32 = -1
    private var source: (any DispatchSourceFileSystemObject)? = nil
    private let queue = DispatchQueue(label: "com.se.filewatcher", qos: .utility)

    public var onChange: (() -> Void)? = nil

    public init() {}

    /// Starts monitoring the file at path for changes.
    public func start(path: String) {
        stop()

        guard !path.isEmpty, FileManager.default.fileExists(atPath: path) else { return }

        fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let eventMask: DispatchSource.FileSystemEvent = [.write, .delete, .rename, .extend, .attrib]
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: eventMask,
            queue: queue
        )

        src.setEventHandler { [weak self] in
            DispatchQueue.main.async {
                self?.onChange?()
            }
        }

        src.setCancelHandler { [fd = fileDescriptor] in
            if fd >= 0 {
                close(fd)
            }
        }

        self.source = src
        src.resume()
    }

    /// Stops watching the current file.
    public func stop() {
        if let src = source {
            src.cancel()
            source = nil
        }
        fileDescriptor = -1
    }

    deinit {
        stop()
    }
}
