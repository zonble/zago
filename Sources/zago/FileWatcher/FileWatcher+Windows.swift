import Dispatch
import Foundation

#if os(Windows)
    import WinSDK

    final class WindowsFileWatcher: PlatformFileWatcher, @unchecked Sendable {
        var onChange: (() -> Void)? = nil

        private struct FileSignature: Equatable {
            let modificationDate: Date?
            let fileSize: UInt64?
        }

        private var watchedPath: String? = nil
        private var lastSignature: FileSignature? = nil
        private var timerSource: (any DispatchSourceTimer)? = nil
        private let queue = DispatchQueue(label: "com.se.filewatcher.windows", qos: .utility)
        private let stateLock = NSLock()

        private var changeHandle: HANDLE? = nil
        private var stopEventHandle: HANDLE? = nil

        private final class WindowsHandleBox: @unchecked Sendable {
            let handle: HANDLE

            init(_ handle: HANDLE) {
                self.handle = handle
            }
        }

        func start(path: String) {
            stop()

            guard !path.isEmpty else { return }

            let normalized = (path as NSString).standardizingPath
            let signature = getSignature(for: normalized)
            stateLock.withLock {
                watchedPath = normalized
                lastSignature = signature
            }

            let parentDir = (normalized as NSString).deletingLastPathComponent
            let dirPath = parentDir.isEmpty ? "." : parentDir

            let handle = dirPath.withCString(encodedAs: UTF16.self) { pStr in
                FindFirstChangeNotificationW(
                    pStr,
                    false,
                    DWORD(FILE_NOTIFY_CHANGE_LAST_WRITE | FILE_NOTIFY_CHANGE_SIZE | FILE_NOTIFY_CHANGE_FILE_NAME)
                )
            }

            guard let h = handle, h != INVALID_HANDLE_VALUE else {
                startTimerFallback(for: normalized)
                return
            }

            let stopEvent = CreateEventW(nil, true, false, nil)
            guard let stopEvent, stopEvent != INVALID_HANDLE_VALUE else {
                FindCloseChangeNotification(h)
                startTimerFallback(for: normalized)
                return
            }

            changeHandle = h
            stopEventHandle = stopEvent

            let changeHandleBox = WindowsHandleBox(h)
            let stopEventBox = WindowsHandleBox(stopEvent)

            queue.async { [weak self, changeHandleBox, stopEventBox] in
                let h = changeHandleBox.handle
                let stopEvent = stopEventBox.handle
                var waitHandles: [HANDLE?] = [h, stopEvent]
                defer {
                    FindCloseChangeNotification(h)
                    CloseHandle(stopEvent)
                }

                while true {
                    let res = waitHandles.withUnsafeMutableBufferPointer { buffer in
                        WaitForMultipleObjects(DWORD(buffer.count), buffer.baseAddress, false, 100)
                    }
                    if res == WAIT_OBJECT_0 {
                        guard let self else { break }
                        let currentSignature = self.getSignature(for: normalized)
                        let shouldNotify = self.stateLock.withLock {
                            guard self.watchedPath == normalized else { return false }
                            guard currentSignature != self.lastSignature else { return false }
                            self.lastSignature = currentSignature
                            return true
                        }
                        if shouldNotify {
                            self.notifyChange()
                        }
                        FindNextChangeNotification(h)
                    } else if res == WAIT_OBJECT_0 + 1 {
                        break
                    }
                }
            }
        }

        func stop() {
            if let timer = timerSource {
                timer.cancel()
                timerSource = nil
            }
            if let h = stopEventHandle, h != INVALID_HANDLE_VALUE {
                SetEvent(h)
            }
            changeHandle = nil
            stopEventHandle = nil
            stateLock.withLock {
                watchedPath = nil
                lastSignature = nil
            }
        }

        func recordCurrentModificationDate() {
            stateLock.withLock {
                guard let path = watchedPath else { return }
                self.lastSignature = getSignature(for: path)
            }
        }

        private func startTimerFallback(for path: String) {
            if let timer = timerSource {
                timer.cancel()
                timerSource = nil
            }
            let initialSignature = getSignature(for: path)
            stateLock.withLock {
                lastSignature = initialSignature
            }

            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now() + 0.5, repeating: 0.5)
            timer.setEventHandler { [weak self] in
                guard let self else { return }
                let (isMatching, currentSig) = self.stateLock.withLock { () -> (Bool, FileSignature?) in
                    guard self.watchedPath == path else { return (false, nil) }
                    return (true, self.lastSignature)
                }
                guard isMatching else { return }

                let newSignature = self.getSignature(for: path)
                let shouldNotify = self.stateLock.withLock {
                    guard self.watchedPath == path else { return false }
                    guard newSignature != self.lastSignature else { return false }
                    self.lastSignature = newSignature
                    return true
                }
                if shouldNotify {
                    self.notifyChange()
                }
            }
            timerSource = timer
            timer.resume()
        }

        private func notifyChange() {
            onChange?()
        }

        private func getSignature(for path: String) -> FileSignature {
            let attrs = try? FileManager.default.attributesOfItem(atPath: path)
            return FileSignature(
                modificationDate: attrs?[.modificationDate] as? Date,
                fileSize: (attrs?[.size] as? NSNumber)?.uint64Value
            )
        }

        deinit {
            stop()
        }
    }
#endif
