import Foundation
import Git

public struct EditorDependencies {
    public let fileIOStrategy: EditorFileIOStrategy
    public let terminal: EditorTerminal
    public let gitService: GitServiceProtocol
    public let historyStore: any AIHistoryStoring
    public let clipboardStrategy: any EditorClipboardStrategy

    public init(
        fileIOStrategy: EditorFileIOStrategy,
        terminal: EditorTerminal,
        gitService: GitServiceProtocol = GitService(),
        historyStore: any AIHistoryStoring = InMemoryAIHistoryStore(),
        clipboardStrategy: any EditorClipboardStrategy = InMemoryClipboardStrategy()
    ) {
        self.fileIOStrategy = fileIOStrategy
        self.terminal = terminal
        self.gitService = gitService
        self.historyStore = historyStore
        self.clipboardStrategy = clipboardStrategy
    }
}
