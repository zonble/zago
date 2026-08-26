import Foundation
import Testing

@testable import Config
@testable import Editor
@testable import Git

@Test func testGitDiffEngineAddedLines() {
    let repoInfo = GitRepositoryInfo(repoRootPath: "/test", branchName: "main", relativeFilePath: "file.txt")
    let base = ["line 1", "line 2"]
    let current = ["line 1", "line 2", "line 3"]

    let info = GitDiffEngine.computeDiff(repoInfo: repoInfo, baseLines: base, currentLines: current)

    #expect(info.hasDiffMarkers == true)
    #expect(info.branchName == "main")
    #expect(info.lineStatuses[0] == .unmodified)
    #expect(info.lineStatuses[1] == .unmodified)
    #expect(info.lineStatuses[2] == .added)
}

@Test func testGitDiffEngineModifiedLines() {
    let repoInfo = GitRepositoryInfo(repoRootPath: "/test", branchName: "feature", relativeFilePath: "file.txt")
    let base = ["line 1", "line 2"]
    let current = ["line 1", "line 2 modified"]

    let info = GitDiffEngine.computeDiff(repoInfo: repoInfo, baseLines: base, currentLines: current)

    #expect(info.hasDiffMarkers == true)
    #expect(info.branchName == "feature")
    #expect(info.lineStatuses[0] == .unmodified)
    #expect(info.lineStatuses[1] == .modified)
}

@Test func testGitDiffEngineDeletedLines() {
    let repoInfo = GitRepositoryInfo(repoRootPath: "/test", branchName: "main", relativeFilePath: "file.txt")
    let base = ["line 1", "line 2", "line 3"]
    let current = ["line 1", "line 3"]

    let info = GitDiffEngine.computeDiff(repoInfo: repoInfo, baseLines: base, currentLines: current)

    #expect(info.hasDiffMarkers == true)
    #expect(info.lineStatuses[0] == .unmodified)
    #expect(info.lineStatuses[1] == .unmodified)
    #expect(info.deletedLineIndices.contains(1) == true)
}

@Test func testGitDiffEngineUnmodified() {
    let repoInfo = GitRepositoryInfo(repoRootPath: "/test", branchName: "main", relativeFilePath: "file.txt")
    let base = ["line 1", "line 2"]
    let current = ["line 1", "line 2"]

    let info = GitDiffEngine.computeDiff(repoInfo: repoInfo, baseLines: base, currentLines: current)

    #expect(info.hasDiffMarkers == false)
    #expect(info.lineStatuses[0] == .unmodified)
    #expect(info.lineStatuses[1] == .unmodified)
}

@Test func testGitOutputLinesIgnoreTrailingNewlineSentinel() {
    #expect(GitService.splitGitOutputLines("line 1\r\nline 2\r\n") == ["line 1", "line 2"])
    #expect(GitService.splitGitOutputLines("line 1\nline 2") == ["line 1", "line 2"])
    #expect(GitService.splitGitOutputLines("line 1\n\n") == ["line 1", ""])
}

@Test func testRealRepositoryDetectionWithRelativePaths() {
    let gitService = GitService()

    let infoRelative = gitService.detectRepository(for: "README.md")
    #expect(infoRelative != nil)
    #expect(infoRelative?.branchName != nil)
    #expect(infoRelative?.relativeFilePath == "README.md")

    let infoSubdir = gitService.detectRepository(for: "Sources/Editor/Editor.swift")
    #expect(infoSubdir != nil)
    #expect(infoSubdir?.branchName != nil)
    #expect(infoSubdir?.relativeFilePath == "Sources/Editor/Editor.swift")

    let diffInfo = gitService.computeDiffSync(filePath: "README.md", currentLines: ["# zago"])
    #expect(diffInfo.branchName != nil)
}

@Test func testTitleBarBranchDisplay() {
    let fileIO = MemoryEditorFileIOStrategy(files: ["/test/file.txt": "Hello World"])
    let editor = Editor(
        options: EditorOptions(filePaths: ["/test/file.txt"]),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared),
        initialVariables: [:]
    )
    editor.gitDiffInfo = GitDiffInfo(branchName: "main", hasDiffMarkers: false)

    let renderer = Renderer()
    let output = renderer.renderTitleOrMenuBar(editor: editor, cols: 80)
    #expect(output.contains("[main]") == true)
}

@Test func testUndoAndRedoUpdatesGitStatus() {
    final class MockGitService: GitServiceProtocol, @unchecked Sendable {
        var baseLines = ["Original line"]

        func detectRepository(for filePath: String?) -> GitRepositoryInfo? {
            GitRepositoryInfo(repoRootPath: "/test", branchName: "main", relativeFilePath: "file.txt")
        }
        func fetchDirectoryGitStatus(repoRoot: String) -> [String: String] { [:] }
        func computeDiffSync(filePath: String?, currentLines: [String]) -> GitDiffInfo {
            let isModified = currentLines != baseLines
            let lineStatuses = isModified ? [0: GitLineStatus.modified] : [0: GitLineStatus.unmodified]
            return GitDiffInfo(branchName: "main", lineStatuses: lineStatuses, deletedLineIndices: [], hasDiffMarkers: isModified)
        }
        func repositoryStateChanged(for filePath: String?) -> Bool { false }
    }

    let mockGit = MockGitService()
    let fileIO = MemoryEditorFileIOStrategy(files: ["/test/file.txt": "Original line"])
    let editor = Editor(
        options: EditorOptions(filePaths: ["/test/file.txt"]),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared, gitService: mockGit),
        initialVariables: [:]
    )
    editor.displayConfig.showGitDiff = true
    editor.updateGitDiff()

    #expect(editor.gitDiffInfo.hasDiffMarkers == false)
    #expect(editor.gitDiffInfo.lineStatuses[0] == .unmodified)

    // 1. Mutate buffer
    editor.saveUndoSnapshot()
    editor.buffer.lines[0] = "Modified line"
    editor.buffer.isModified = true
    editor.updateGitDiff()

    #expect(editor.gitDiffInfo.hasDiffMarkers == true)
    #expect(editor.gitDiffInfo.lineStatuses[0] == .modified)

    // 2. Undo (^Z) restores clean state and updates git diff immediately
    editor.performUndo()

    #expect(editor.buffer.lines[0] == "Original line")
    #expect(editor.gitDiffInfo.hasDiffMarkers == false)
    #expect(editor.gitDiffInfo.lineStatuses[0] == .unmodified)

    // 3. Redo (Ctrl+Shift+Z) restores modified state and updates git diff immediately
    editor.performRedo()

    #expect(editor.buffer.lines[0] == "Modified line")
    #expect(editor.gitDiffInfo.hasDiffMarkers == true)
    #expect(editor.gitDiffInfo.lineStatuses[0] == .modified)
}
