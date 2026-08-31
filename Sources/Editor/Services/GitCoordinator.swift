import Foundation
import Git

/// Manages Git repository diff caching, dirty flags, and on-demand synchronization for editor buffers.
public final class GitCoordinator: @unchecked Sendable {
    private let lock = NSRecursiveLock()
    public let gitService: GitServiceProtocol
    private var _currentDiffInfo: GitDiffInfo = .empty
    private var _isDirty: Bool = true

    public var debounceInterval: TimeInterval = 0.3
    private var _lastUpdateTime: Date = .distantPast

    public var currentDiffInfo: GitDiffInfo {
        get { lock.withLock { _currentDiffInfo } }
        set { lock.withLock { _currentDiffInfo = newValue } }
    }

    public var isDirty: Bool {
        get { lock.withLock { _isDirty } }
        set { lock.withLock { _isDirty = newValue } }
    }

    public init(gitService: GitServiceProtocol) {
        self.gitService = gitService
    }

    /// Marks the Git diff state as dirty, requesting recalculation on next render pass.
    public func markDirty() {
        lock.withLock {
            _isDirty = true
        }
    }

    /// Synchronizes Git diff if marked dirty or if the external git repository state has changed.
    public func updateIfNeeded(
        filePath: String?,
        currentLines: [String],
        showGitDiff: Bool,
        isScratchBuffer: Bool,
        force: Bool = false
    ) {
        lock.withLock {
            let stateChanged = gitService.repositoryStateChanged(for: filePath)
            if !_isDirty && stateChanged {
                _isDirty = true
            }
            guard _isDirty else { return }
            let now = Date()
            if !force && !stateChanged && debounceInterval > 0
                && now.timeIntervalSince(_lastUpdateTime) < debounceInterval
            {
                return
            }
            update(
                filePath: filePath, currentLines: currentLines, showGitDiff: showGitDiff,
                isScratchBuffer: isScratchBuffer)
        }
    }

    /// Computes Git diff synchronously for the specified file and lines.
    public func update(
        filePath: String?,
        currentLines: [String],
        showGitDiff: Bool,
        isScratchBuffer: Bool
    ) {
        lock.withLock {
            _isDirty = false
            _lastUpdateTime = Date()
            guard showGitDiff, !isScratchBuffer else {
                _currentDiffInfo = .empty
                return
            }
            _currentDiffInfo = gitService.computeDiffSync(filePath: filePath, currentLines: currentLines)
        }
    }
}
