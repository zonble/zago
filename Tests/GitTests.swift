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

// @Test func testRealRepositoryDetectionWithRelativePaths() {
//     let gitService = GitService.shared

//     let infoRelative = gitService.detectRepository(for: "README.md")
//     #expect(infoRelative != nil)
//     #expect(infoRelative?.branchName == "dev")
//     #expect(infoRelative?.relativeFilePath == "README.md")

//     let infoSubdir = gitService.detectRepository(for: "Sources/Editor/Editor.swift")
//     #expect(infoSubdir != nil)
//     #expect(infoSubdir?.branchName == "dev")
//     #expect(infoSubdir?.relativeFilePath == "Sources/Editor/Editor.swift")

//     let diffInfo = gitService.computeDiffSync(filePath: "README.md", currentLines: ["# zago"])
//     #expect(diffInfo.branchName == "dev")
// }

@Test func testTitleBarBranchDisplay() {
    let fileIO = MemoryEditorFileIOStrategy(files: ["/test/file.txt": "Hello World"])
    let editor = Editor(
        options: EditorOptions(filePaths: ["/test/file.txt"]),
        dependencies: EditorDependencies(fileIOStrategy: fileIO, terminal: TestEditorTerminal.shared)
    )
    editor.gitDiffInfo = GitDiffInfo(branchName: "main", hasDiffMarkers: false)

    let renderer = Renderer()
    let output = renderer.renderTitleOrMenuBar(editor: editor, cols: 80)
    #expect(output.contains("[main]") == true)
}
