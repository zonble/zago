import Dispatch
import Foundation

#if canImport(Darwin)
    import Darwin

    final class DarwinFileWatcher: PlatformFileWatcher, @unchecked Sendable {
        var onChange: (() -> Void)? = nil

        private var watchedPath: String? = nil
        private var lastModificationDate: Date? = nil
        private var timerSource: (any DispatchSourceTimer)? = nil
        private let queue = DispatchQueue(label: "com.se.filewatcher.darwin", qos: .utility)

        private var fileDescriptor: Int32 = -1
        private var source: (any DispatchSourceFileSystemObject)? = nil

        func start(path: String) {
            stop()

            guard !path.isEmpty else { return }

            let normalized = (path as NSString).standardizingPath
            watchedPath = normalized

            if FileManager.default.fileExists(atPath: normalized) {
                startWatchingExistingFile(at: normalized)
            } else {
                startTimerFallback(for: normalized)
            }
        }

        func stop() {
            if let timer = timerSource {
                timer.cancel()
                timerSource = nil
            }
            if let src = source {
                src.cancel()
                source = nil
            }
            fileDescriptor = -1
            watchedPath = nil
            lastModificationDate = nil
        }

        func recordCurrentModificationDate() {
            guard let path = watchedPath else { return }
            lastModificationDate = getModificationDate(for: path)
        }

        private func startWatchingExistingFile(at path: String) {
            fileDescriptor = open(path, O_EVTONLY)
            guard fileDescriptor >= 0 else {
                startTimerFallback(for: path)
                return
            }

            lastModificationDate = getModificationDate(for: path)

            let eventMask: DispatchSource.FileSystemEvent = [.write, .delete, .rename, .extend, .attrib]
            let src = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fileDescriptor,
                eventMask: eventMask,
                queue: queue
            )

            src.setEventHandler { [weak self] in
                guard let self else { return }
                let events = src.data

                if events.contains(.delete) || events.contains(.rename) {
                    self.reopenWatchedFile(at: path)
                } else {
                    let currentMTime = self.getModificationDate(for: path)
                    self.lastModificationDate = currentMTime
                    self.notifyChange()
                }
            }

            src.setCancelHandler { [fd = fileDescriptor] in
                if fd >= 0 {
                    close(fd)
                }
            }

            source = src
            src.resume()
        }

        private func reopenWatchedFile(at path: String) {
            if let src = source {
                src.cancel()
                source = nil
            }
            fileDescriptor = -1

            queue.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let self, self.watchedPath == path else { return }
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

                if FileManager.default.fileExists(atPath: path) {
                    timer.cancel()
                    self.timerSource = nil
                    let currentMTime = self.getModificationDate(for: path)
                    self.lastModificationDate = currentMTime
                    self.notifyChange()
                    self.startWatchingExistingFile(at: path)
                    return
                }

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
