import Config
import Editor
import Foundation
import Git
import LogoEngine

let terminal = WasiTerminal()
let fileIO = WasiFileIOStrategy()
let configSource = EditorConfigSource()

let args = ProcessInfo.processInfo.arguments
let targetFiles = args.count > 1 ? Array(args.dropFirst()) : ["/workspace/welcome.md"]

final class StubGitService: GitServiceProtocol, @unchecked Sendable {
    func detectRepository(for filePath: String?) -> GitRepositoryInfo? { nil }
    func computeDiffSync(filePath: String?, currentLines: [String]) -> GitDiffInfo { GitDiffInfo() }
    func fetchDirectoryGitStatus(repoRoot: String) -> [String: String] { [:] }
    func repositoryStateChanged(for filePath: String?) -> Bool { false }
}

let options = EditorOptions(
    filePaths: targetFiles,
    wrapColumn: nil,
    showLineNumbers: true,
    showSubLineNumbers: false,
    ipcEnabled: false,
    language: .en,
    spellLanguage: nil,
    initialLine: 1,
    initialColumn: 1,
    readOnly: false,
    pipedInput: nil,
    keymapPreset: .classic,
    defaultLineEnding: .lf
)

let dependencies = EditorDependencies(
    fileIOStrategy: fileIO,
    terminal: terminal,
    gitService: StubGitService(),
    historyStore: InMemoryAIHistoryStore(),
    clipboardStrategy: InMemoryClipboardStrategy()
)

let editor = Editor(
    options: options,
    configSource: configSource,
    dependencies: dependencies,
    initialVariables: [
        "zago.author": "zonble",
        "zago.version": "web-edition",
    ]
)

editor.run()
