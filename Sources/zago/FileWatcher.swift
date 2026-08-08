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

    private var watchedPath: String? = nil
    private var lastModificationDate: Date? = nil
    private var timerSource: (any DispatchSourceTimer)? = nil
    private let queue = DispatchQueue(label: "com.se.filewatcher", qos: .utility)

    #if canImport(Darwin)
        private var fileDescriptor: Int32 = -1
        private var source: (any DispatchSourceFileSystemObject)? = nil
    #elseif os(Windows)
        private var changeHandle: HANDLE? = nil
        private var isWatchingWindows = false
    #endif

    public init() {}

    /// Starts monitoring the file at path for changes.
    public func start(path: String) {
        stop()

        guard !path.isEmpty else { return }

        let normalized = (path as NSString).standardizingPath
        self.watchedPath = normalized

        #if canImport(Darwin)
            if FileManager.default.fileExists(atPath: normalized) {
                startWatchingExistingFile(at: normalized)
            } else {
                startTimerFallback(for: normalized)
            }
        #elseif os(Windows)
            self.lastModificationDate = getModificationDate(for: normalized)

            let parentDir = (normalized as NSString).deletingLastPathComponent
            let dirPath = parentDir.isEmpty ? "." : parentDir

            let handle = dirPath.withCString(encodedAs: UTF16.self) { pStr in
                FindFirstChangeNotificationW(
                    pStr,
                    false,
                    DWORD(FILE_NOTIFY_CHANGE_LAST_WRITE | FILE_NOTIFY_CHANGE_SIZE | FILE_NOTIFY_CHANGE_FILE_NAME)
                )
            }

            if let h = handle, h != INVALID_HANDLE_VALUE {
                self.changeHandle = h
                self.isWatchingWindows = true

                queue.async { [weak self] in
                    while let self = self, self.isWatchingWindows, let h = self.changeHandle {
                        let res = WaitForSingleObject(h, 100)
                        if res == WAIT_OBJECT_0 {
                            guard self.isWatchingWindows, let currentHandle = self.changeHandle else { break }
                            let currentMTime = self.getModificationDate(for: normalized)
                            if currentMTime != self.lastModificationDate {
                                self.lastModificationDate = currentMTime
                                self.notifyChange()
                            }
                            FindNextChangeNotification(currentHandle)
                        }
                    }
                }
            } else {
                startTimerFallback(for: normalized)
            }
        #else
            startTimerFallback(for: normalized)
        #endif
    }

    #if canImport(Darwin)
        private func startWatchingExistingFile(at path: String) {
            fileDescriptor = open(path, O_EVTONLY)
            guard fileDescriptor >= 0 else {
                startTimerFallback(for: path)
                return
            }

            self.lastModificationDate = getModificationDate(for: path)

            let eventMask: DispatchSource.FileSystemEvent = [.write, .delete, .rename, .extend, .attrib]
            let src = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fileDescriptor,
                eventMask: eventMask,
                queue: queue
            )

            src.setEventHandler { [weak self] in
                guard let self = self else { return }
                let events = src.data

                if events.contains(.delete) || events.contains(.rename) {
                    // Atomic replace by another editor (write temp -> rename to target file)
                    self.reopenWatchedFile(at: path)
                } else {
                    let currentMTime = self.getModificationDate(for: path)
                    if currentMTime != self.lastModificationDate {
                        self.lastModificationDate = currentMTime
                        self.notifyChange()
                    }
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

        private func reopenWatchedFile(at path: String) {
            if let src = source {
                src.cancel()
                source = nil
            }
            fileDescriptor = -1

            // Short delay for atomic replace (write temp -> rename) to settle
            queue.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let self = self, self.watchedPath == path else { return }
                if FileManager.default.fileExists(atPath: path) {
                    let currentMTime = self.getModificationDate(for: path)
                    self.lastModificationDate = currentMTime
                    self.notifyChange()
                    self.startWatchingExistingFile(at: path)
                } else {
                    self.startTimerFallback(for: path)
                }
            }
        }
    #endif

    /// Stops watching the current file.
    public func stop() {
        if let timer = timerSource {
            timer.cancel()
            timerSource = nil
        }
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
        #endif
        watchedPath = nil
        lastModificationDate = nil
    }

    /// Fallback timer monitoring for Linux / Glibc / Musl or non-Darwin platforms where native kqueue / Win32 handles are unavailable.
    ///
    /// Note on Linux (Glibc/Musl Foundation): `FileManager.default.attributesOfItem(atPath:)[.modificationDate]`
    /// evaluates file modification timestamps with 1-second time_t resolution. Comparing both `mtime` and file existence
    /// ensures reliable modification detection across fast background file edits on Linux ext4 / tmpfs filesystems.
    private func startTimerFallback(for path: String) {
        if let timer = timerSource {
            timer.cancel()
            timerSource = nil
        }
        self.lastModificationDate = getModificationDate(for: path)

        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 0.5, repeating: 0.5)
        timer.setEventHandler { [weak self] in
            guard let self = self, let p = self.watchedPath, p == path else { return }

            #if canImport(Darwin)
                if FileManager.default.fileExists(atPath: path) {
                    timer.cancel()
                    self.timerSource = nil
                    let currentMTime = self.getModificationDate(for: path)
                    if currentMTime != self.lastModificationDate {
                        self.lastModificationDate = currentMTime
                        self.notifyChange()
                    }
                    self.startWatchingExistingFile(at: path)
                    return
                }
            #endif

            let currentMTime = self.getModificationDate(for: p)
            if currentMTime != self.lastModificationDate {
                self.lastModificationDate = currentMTime
                self.notifyChange()
            }
        }
        self.timerSource = timer
        timer.resume()
    }

    private func notifyChange() {
        onChange?()
    }

    /// Records current modification date of watched file to suppress self-save change notifications.
    public func recordCurrentModificationDate() {
        guard let path = watchedPath else { return }
        queue.sync {
            self.lastModificationDate = self.getModificationDate(for: path)
        }
    }

    private func getModificationDate(for path: String) -> Date? {
        let attrs = try? FileManager.default.attributesOfItem(atPath: path)
        return attrs?[.modificationDate] as? Date
    }

    deinit {
        stop()
    }
}
