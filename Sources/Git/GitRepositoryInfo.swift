import Foundation

/// Holds Git repository metadata for an open file.
public struct GitRepositoryInfo: Sendable, Equatable {
    public let repoRootPath: String
    public let branchName: String?
    public let relativeFilePath: String

    public init(repoRootPath: String, branchName: String?, relativeFilePath: String) {
        self.repoRootPath = repoRootPath
        self.branchName = branchName
        self.relativeFilePath = relativeFilePath
    }
}
