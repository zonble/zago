import Dispatch
import Foundation

#if !canImport(Darwin) && !os(Windows)
    final class PollingFileWatcher: PlatformFileWatcher, @unchecked Sendable {
        var onChange: (() -> Void)? = nil

        private var watchedPath: String? = nil
        private var lastModificationDate: Date? = nil
        private var timerSource: (any DispatchSourceTimer)? = nil
        private let queue = DispatchQueue(label: "com.se.filewatcher.polling", qos: .utility)

        func start(path: String) {
            stop()

            guard !path.isEmpty else { return }

            let normalized = (path as NSString).standardizingPath
            watchedPath = normalized
            startTimerFallback(for: normalized)
        }

        func stop() {
            if let timer = timerSource {
                timer.cancel()
                timerSource = nil
            }
            watchedPath = nil
            lastModificationDate = nil
        }

        func recordCurrentModificationDate() {
            guard let path = watchedPath else { return }
            lastModificationDate = getModificationDate(for: path)
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
