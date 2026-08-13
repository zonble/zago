import Dispatch
import Foundation

#if os(Windows)
    import WinSDK

    final class WindowsFileWatcher: PlatformFileWatcher, @unchecked Sendable {
        var onChange: (() -> Void)? = nil

        private var watchedPath: String? = nil
        private var lastModificationDate: Date? = nil
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
            watchedPath = normalized
            lastModificationDate = getModificationDate(for: normalized)

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
                        let currentMTime = self.getModificationDate(for: normalized)
                        let shouldNotify = self.stateLock.withLock {
                            guard currentMTime != self.lastModificationDate else { return false }
                            self.lastModificationDate = currentMTime
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
            watchedPath = nil
            lastModificationDate = nil
        }

        func recordCurrentModificationDate() {
            guard let path = watchedPath else { return }
            let currentMTime = getModificationDate(for: path)
            stateLock.withLock {
                self.lastModificationDate = currentMTime
            }
        }

        private func startTimerFallback(for path: String) {
            if let timer = timerSource {
                timer.cancel()
                timerSource = nil
            }
            lastModificationDate = getModificationDate(for: path)

            let timer = DispatchSource.makeTimerSource(queue: queue)
            timer.schedule(deadline: .now() + 0.5, repeating: 0.5)
            timer.setEventHandler { [weak self] in
                guard let self, let p = self.watchedPath, p == path else { return }

                let currentMTime = self.getModificationDate(for: p)
                if currentMTime != self.lastModificationDate {
                    self.lastModificationDate = currentMTime
                    self.notifyChange()
                }
            }
            timerSource = timer
            timer.resume()
        }

        private func notifyChange() {
            onChange?()
        }

        private func getModificationDate(for path: String) -> Date? {
            let attrs = try? FileManager.default.attributesOfItem(atPath: path)
            return attrs?[.modificationDate] as? Date
        }

        deinit {
            stop()
        }
    }
#endif
