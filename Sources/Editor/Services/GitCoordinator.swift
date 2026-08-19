import Foundation
import Git

/// Manages Git repository diff caching, dirty flags, and on-demand synchronization for editor buffers.
public final class GitCoordinator: @unchecked Sendable {
    public let gitService: GitServiceProtocol
    public var currentDiffInfo: GitDiffInfo = .empty
    public var isDirty: Bool = true

    public init(gitService: GitServiceProtocol) {
        self.gitService = gitService
    }

    /// Marks the Git diff state as dirty, requesting recalculation on next render pass.
    public func markDirty() {
        isDirty = true
    }

    /// Synchronizes Git diff if marked dirty or if the external git repository state has changed.
    public func updateIfNeeded(
        filePath: String?,
        currentLines: [String],
        showGitDiff: Bool,
        isScratchBuffer: Bool
    ) {
        if !isDirty && gitService.repositoryStateChanged(for: filePath) {
            isDirty = true
        }
        guard isDirty else { return }
        update(filePath: filePath, currentLines: currentLines, showGitDiff: showGitDiff, isScratchBuffer: isScratchBuffer)
    }

    /// Computes Git diff synchronously for the specified file and lines.
    public func update(
        filePath: String?,
        currentLines: [String],
        showGitDiff: Bool,
        isScratchBuffer: Bool
    ) {
        isDirty = false
        guard showGitDiff, !isScratchBuffer else {
            currentDiffInfo = .empty
            return
        }
        currentDiffInfo = gitService.computeDiffSync(filePath: filePath, currentLines: currentLines)
    }
}
