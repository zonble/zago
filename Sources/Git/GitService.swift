import Foundation

/// Service for detecting Git repositories, fetching `HEAD` baselines, and maintaining diff status.
public final class GitService: @unchecked Sendable {
    public static let shared = GitService()

    private let queue = DispatchQueue(label: "org.zago.gitservice", qos: .userInitiated)
    private var repoRootCache: [String: String] = [:]
    private var branchCache: [String: String] = [:]
    private var headCache: [String: [String]] = [:]

    public init() {}

    /// Detects if a file path or current working directory lives inside a Git repository and returns its metadata.
    public func detectRepository(for filePath: String?) -> GitRepositoryInfo? {
        let absFilePath: String?
        let pathToInspect: String

        if let filePath = filePath, !filePath.isEmpty, filePath != "Untitled" {
            let expanded = (filePath as NSString).isAbsolutePath
                ? filePath
                : (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(filePath)
            absFilePath = expanded
            pathToInspect = (expanded as NSString).deletingLastPathComponent
        } else {
            absFilePath = nil
            pathToInspect = FileManager.default.currentDirectoryPath
        }
        guard !pathToInspect.isEmpty else { return nil }

        let repoRoot: String
        if let cachedRoot = repoRootCache[pathToInspect] {
            repoRoot = cachedRoot
        } else {
            var currentDir = pathToInspect
            var foundRepoRoot: String? = nil

            while !currentDir.isEmpty && currentDir != "/" {
                let gitPath = (currentDir as NSString).appendingPathComponent(".git")
                if FileManager.default.fileExists(atPath: gitPath) {
                    foundRepoRoot = currentDir
                    break
                }
                let parent = (currentDir as NSString).deletingLastPathComponent
                if parent == currentDir { break }
                currentDir = parent
            }

            guard let root = foundRepoRoot else { return nil }
            repoRootCache[pathToInspect] = root
            repoRoot = root
        }

        let relativePath: String
        if let absFilePath = absFilePath, absFilePath.hasPrefix(repoRoot) {
            var rel = String(absFilePath.dropFirst(repoRoot.count))
            if rel.hasPrefix("/") { rel.removeFirst() }
            relativePath = rel
        } else {
            relativePath = absFilePath.map { ($0 as NSString).lastPathComponent } ?? ""
        }

        let branch = readBranchName(repoRoot: repoRoot)
        return GitRepositoryInfo(repoRootPath: repoRoot, branchName: branch, relativeFilePath: relativePath)
    }

    /// Synchronously computes Git diff status for immediate render passes.
    public func computeDiffSync(filePath: String?, currentLines: [String]) -> GitDiffInfo {
        guard let repoInfo = detectRepository(for: filePath) else {
            return GitDiffInfo.empty
        }

        guard !repoInfo.relativeFilePath.isEmpty else {
            return GitDiffInfo(repoInfo: repoInfo, branchName: repoInfo.branchName)
        }

        let cacheKey = "\(repoInfo.repoRootPath):\(repoInfo.relativeFilePath)"
        let baseLines: [String]?

        if let cached = headCache[cacheKey] {
            baseLines = cached
        } else {
            baseLines = fetchHEADLinesSync(repoInfo: repoInfo)
            if let baseLines {
                headCache[cacheKey] = baseLines
            }
        }

        return GitDiffEngine.computeDiff(
            repoInfo: repoInfo,
            baseLines: baseLines,
            currentLines: currentLines
        )
    }

    /// Asynchronously fetches `HEAD` version lines of a file and computes diff against current buffer.
    public func computeDiffAsync(
        filePath: String?,
        currentLines: [String],
        completion: @escaping @MainActor (GitDiffInfo) -> Void
    ) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let info = self.computeDiffSync(filePath: filePath, currentLines: currentLines)
            DispatchQueue.main.async {
                completion(info)
            }
        }
    }

    /// Invalidates cached `HEAD` content for a file (e.g. after save or external git action).
    public func invalidateCache(for filePath: String?) {
        let targetPath = filePath ?? FileManager.default.currentDirectoryPath
        let dirPath = (targetPath as NSString).deletingLastPathComponent
        repoRootCache.removeValue(forKey: dirPath)
        branchCache.removeAll()
        headCache.removeAll()
    }

    // MARK: - Private Helpers

    private func readBranchName(repoRoot: String) -> String? {
        let headFile = (repoRoot as NSString).appendingPathComponent(".git/HEAD")
        if let content = try? String(contentsOfFile: headFile, encoding: .utf8) {
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("ref: refs/heads/") {
                return String(trimmed.dropFirst("ref: refs/heads/".count))
            }
            if trimmed.count >= 7 {
                return String(trimmed.prefix(7))
            }
        }
        return runGitCommand(args: ["branch", "--show-current"], cwd: repoRoot)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func fetchHEADLinesSync(repoInfo: GitRepositoryInfo) -> [String]? {
        guard !repoInfo.relativeFilePath.isEmpty else { return nil }
        guard let output = runGitCommand(args: ["show", "HEAD:\(repoInfo.relativeFilePath)"], cwd: repoInfo.repoRootPath) else {
            return nil
        }
        return output.components(separatedBy: "\n").map { line in
            line.hasSuffix("\r") ? String(line.dropLast()) : line
        }
    }

    private func findGitBinary() -> URL {
        let candidates = [
            "/usr/bin/git",
            "/opt/homebrew/bin/git",
            "/usr/local/bin/git"
        ]
        for candidate in candidates {
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return URL(fileURLWithPath: candidate)
            }
        }
        return URL(fileURLWithPath: "/usr/bin/env")
    }

    private func runGitCommand(args: [String], cwd: String) -> String? {
        let process = Process()
        let pipe = Pipe()
        let gitURL = findGitBinary()
        if gitURL.path == "/usr/bin/env" {
            process.executableURL = gitURL
            process.arguments = ["git"] + args
        } else {
            process.executableURL = gitURL
            process.arguments = args
        }
        process.currentDirectoryURL = URL(fileURLWithPath: cwd)
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
}
