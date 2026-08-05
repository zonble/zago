import Foundation

/// Contains line-by-line Git diff status and repository context for a buffer.
public struct GitDiffInfo: Sendable, Equatable {
    public let repoInfo: GitRepositoryInfo?
    public let branchName: String?
    public let lineStatuses: [Int: GitLineStatus]
    public let deletedLineIndices: Set<Int>
    public let hasDiffMarkers: Bool

    public init(
        repoInfo: GitRepositoryInfo? = nil,
        branchName: String? = nil,
        lineStatuses: [Int: GitLineStatus] = [:],
        deletedLineIndices: Set<Int> = [],
        hasDiffMarkers: Bool = false
    ) {
        self.repoInfo = repoInfo
        self.branchName = branchName ?? repoInfo?.branchName
        self.lineStatuses = lineStatuses
        self.deletedLineIndices = deletedLineIndices
        self.hasDiffMarkers = hasDiffMarkers
    }

    public static let empty = GitDiffInfo()
}
