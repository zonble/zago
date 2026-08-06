import Foundation
import Git

public struct EditorDependencies {
    public let fileIOStrategy: EditorFileIOStrategy
    public let terminal: EditorTerminal
    public let gitService: GitServiceProtocol

    public init(
        fileIOStrategy: EditorFileIOStrategy,
        terminal: EditorTerminal,
        gitService: GitServiceProtocol = GitService()
    ) {
        self.fileIOStrategy = fileIOStrategy
        self.terminal = terminal
        self.gitService = gitService
    }
}
