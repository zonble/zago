import Config
import Editor
import Foundation
import Git
import LogoEngine

let terminal = WasiTerminal()
let fileIO = WasiFileIOStrategy()
let configProvider = { ConfigLoader(provider: StrategyConfigFileProvider(strategy: fileIO)).loadConfig() }
let configSource = EditorConfigSource(initial: configProvider(), reload: configProvider)

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
    initialLine: 1,
    initialColumn: 1,
    readOnly: false,
    defaultLineEnding: .lf
)

let dependencies = EditorDependencies(
    fileIOStrategy: fileIO,
    terminal: terminal,
    gitService: StubGitService(),
    historyStore: InMemoryAIHistoryStore(),
    clipboardStrategy: InMemoryClipboardStrategy(),
    tmdExportDelegate: WasiTMDExporter()
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
