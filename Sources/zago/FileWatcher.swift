import Dispatch
import Foundation

#if os(Windows)
    import WinSDK
#elseif canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#elseif canImport(Musl)
    import Musl
#endif

/// Monitors a file path for external file system modifications using DispatchSource on macOS,
/// native FindFirstChangeNotificationW on Windows, or mtime polling on Linux / non-Darwin platforms.
public final class FileWatcher: @unchecked Sendable {
    public var onChange: (() -> Void)? = nil

    #if canImport(Darwin)
        private var fileDescriptor: Int32 = -1
        private var source: (any DispatchSourceFileSystemObject)? = nil
        private let queue = DispatchQueue(label: "com.se.filewatcher", qos: .utility)
    #elseif os(Windows)
        private var changeHandle: HANDLE? = nil
        private var isWatchingWindows = false
        private var watchedPath: String? = nil
        private var lastModificationDate: Date? = nil
        private let queue = DispatchQueue(label: "com.se.filewatcher", qos: .utility)
    #else
        private var timerSource: (any DispatchSourceTimer)? = nil
        private var watchedPath: String? = nil
        private var lastModificationDate: Date? = nil
        private let queue = DispatchQueue(label: "com.se.filewatcher", qos: .utility)
    #endif

    public init() {}

    /// Starts monitoring the file at path for changes.
    public func start(path: String) {
        stop()

        guard !path.isEmpty, FileManager.default.fileExists(atPath: path) else { return }

        #if canImport(Darwin)
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
        #elseif os(Windows)
            self.watchedPath = path
            self.lastModificationDate = getModificationDate(for: path)

            let parentDir = (path as NSString).deletingLastPathComponent
            let dirPath = parentDir.isEmpty ? "." : parentDir

            let handle = dirPath.withCString(encodedAs: UTF16.self) { pStr in
                FindFirstChangeNotificationW(
                    pStr,
                    FALSE,
                    DWORD(FILE_NOTIFY_CHANGE_LAST_WRITE | FILE_NOTIFY_CHANGE_SIZE | FILE_NOTIFY_CHANGE_FILE_NAME)
                )
            }

            if let h = handle, h != INVALID_HANDLE_VALUE {
                self.changeHandle = h
                self.isWatchingWindows = true

                queue.async { [weak self] in
                    while let self = self, self.isWatchingWindows, let h = self.changeHandle {
                        let res = WaitForSingleObject(h, 1000)
                        if res == WAIT_OBJECT_0 {
                            if !self.isWatchingWindows { break }
                            let currentMTime = self.getModificationDate(for: path)
                            if currentMTime != self.lastModificationDate {
                                self.lastModificationDate = currentMTime
                                DispatchQueue.main.async {
                                    self.onChange?()
                                }
                            }
                            FindNextChangeNotification(h)
                        }
                    }
                }
            } else {
                // Fallback to mtime polling timer if Win32 handle creation fails
                startTimerFallback(for: path)
            }
        #else
            startTimerFallback(for: path)
        #endif
    }

    /// Stops watching the current file.
    public func stop() {
        #if canImport(Darwin)
            if let src = source {
                src.cancel()
                source = nil
            }
            fileDescriptor = -1
        #elseif os(Windows)
            isWatchingWindows = false
            if let h = changeHandle, h != INVALID_HANDLE_VALUE {
                FindCloseChangeNotification(h)
                changeHandle = nil
            }
            watchedPath = nil
            lastModificationDate = nil
        #else
            if let timer = timerSource {
                timer.cancel()
                timerSource = nil
            }
            watchedPath = nil
            lastModificationDate = nil
        #endif
    }

    #if !canImport(Darwin)
        private func startTimerFallback(for path: String) {
            self.watchedPath = path
            self.lastModificationDate = getModificationDate(for: path)

            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now() + 1.0, repeating: 1.0)
            timer.setEventHandler { [weak self] in
                guard let self = self, let p = self.watchedPath else { return }
                let currentMTime = self.getModificationDate(for: p)
                if currentMTime != self.lastModificationDate {
                    self.lastModificationDate = currentMTime
                    DispatchQueue.main.async {
                        self?.onChange?()
                    }
                }
            }
            self.timerSource = timer
            timer.resume()
        }
    #endif

    private func getModificationDate(for path: String) -> Date? {
        let attrs = try? FileManager.default.attributesOfItem(atPath: path)
        return attrs?[.modificationDate] as? Date
    }

    deinit {
        stop()
    }
}
