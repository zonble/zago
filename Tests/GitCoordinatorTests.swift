import Git
import Testing
@testable import Editor

@Suite struct GitCoordinatorTests {
    final class MockGitService: GitServiceProtocol, @unchecked Sendable {
        var diffToReturn = GitDiffInfo(branchName: "main", lineStatuses: [0: .added], deletedLineIndices: [], hasDiffMarkers: true)
        var stateChanged = false

        func detectRepository(for filePath: String?) -> GitRepositoryInfo? { nil }
        func fetchDirectoryGitStatus(repoRoot: String) -> [String: String] { [:] }

        func computeDiffSync(filePath: String?, currentLines: [String]) -> GitDiffInfo {
            diffToReturn
        }

        func repositoryStateChanged(for filePath: String?) -> Bool {
            stateChanged
        }
    }

    @Test func testGitCoordinatorCachesAndUpdatesOnDirty() {
        let mock = MockGitService()
        let coordinator = GitCoordinator(gitService: mock)

        #expect(coordinator.isDirty == true)
        #expect(coordinator.currentDiffInfo == .empty)

        coordinator.update(filePath: "/repo/file.txt", currentLines: ["new line"], showGitDiff: true, isScratchBuffer: false)
        #expect(coordinator.isDirty == false)
        #expect(coordinator.currentDiffInfo.branchName == "main")
        #expect(coordinator.currentDiffInfo.lineStatuses[0] == .added)

        // Does not recompute if clean
        mock.diffToReturn = GitDiffInfo(branchName: "feature", lineStatuses: [:], deletedLineIndices: [], hasDiffMarkers: false)
        coordinator.updateIfNeeded(filePath: "/repo/file.txt", currentLines: ["new line"], showGitDiff: true, isScratchBuffer: false)
        #expect(coordinator.currentDiffInfo.branchName == "main")

        // Recomputes when stateChanged is true
        mock.stateChanged = true
        coordinator.updateIfNeeded(filePath: "/repo/file.txt", currentLines: ["new line"], showGitDiff: true, isScratchBuffer: false)
        #expect(coordinator.currentDiffInfo.branchName == "feature")
    }

    @Test func testGitCoordinatorClearsOnScratchOrDisabled() {
        let mock = MockGitService()
        let coordinator = GitCoordinator(gitService: mock)

        coordinator.update(filePath: "/repo/file.txt", currentLines: ["line"], showGitDiff: false, isScratchBuffer: false)
        #expect(coordinator.currentDiffInfo == .empty)

        coordinator.update(filePath: "/repo/file.txt", currentLines: ["line"], showGitDiff: true, isScratchBuffer: true)
        #expect(coordinator.currentDiffInfo == .empty)
    }
}
