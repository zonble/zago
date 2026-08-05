import Foundation

/// Pure logic engine for computing line-by-line diff status between base HEAD lines and live buffer lines.
public enum GitDiffEngine: Sendable {

    /// Computes Git diff status for every buffer line index.
    /// - Parameters:
    ///   - repoInfo: Git repository metadata.
    ///   - baseLines: The lines from `HEAD` (or nil if new untracked file).
    ///   - currentLines: The live editor buffer lines.
    /// - Returns: `GitDiffInfo` containing line statuses and deleted line indices.
    public static func computeDiff(
        repoInfo: GitRepositoryInfo?,
        baseLines: [String]?,
        currentLines: [String]
    ) -> GitDiffInfo {
        guard let baseLines = baseLines else {
            // Untracked or new file: show repository branch context without flooding line gutter
            return GitDiffInfo(repoInfo: repoInfo, branchName: repoInfo?.branchName)
        }

        let cleanBase = baseLines.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\r")) }
        let cleanCurrent = currentLines.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\r")) }

        // Compute longest common subsequence / diff script between baseLines and currentLines
        let diffScript = computeLCSDiff(base: cleanBase, current: cleanCurrent)

        var lineStatuses: [Int: GitLineStatus] = [:]
        var deletedLineIndices: Set<Int> = []
        var hasDiff = false

        for edit in diffScript {
            switch edit {
            case .keep(let baseIdx, let currentIdx):
                _ = baseIdx
                lineStatuses[currentIdx] = .unmodified

            case .add(let currentIdx):
                lineStatuses[currentIdx] = .added
                hasDiff = true

            case .modify(let baseIdx, let currentIdx):
                _ = baseIdx
                lineStatuses[currentIdx] = .modified
                hasDiff = true

            case .delete(let baseIdx, let targetCurrentIdx):
                _ = baseIdx
                deletedLineIndices.insert(targetCurrentIdx)
                hasDiff = true
            }
        }

        return GitDiffInfo(
            repoInfo: repoInfo,
            branchName: repoInfo?.branchName,
            lineStatuses: lineStatuses,
            deletedLineIndices: deletedLineIndices,
            hasDiffMarkers: hasDiff
        )
    }

    private enum DiffEdit {
        case keep(baseIdx: Int, currentIdx: Int)
        case add(currentIdx: Int)
        case modify(baseIdx: Int, currentIdx: Int)
        case delete(baseIdx: Int, targetCurrentIdx: Int)
    }

    /// Computes LCS-based diff edits between base and current lines.
    private static func computeLCSDiff(base: [String], current: [String]) -> [DiffEdit] {
        let m = base.count
        let n = current.count

        if m == 0 {
            return (0..<n).map { .add(currentIdx: $0) }
        }
        if n == 0 {
            return (0..<m).map { .delete(baseIdx: $0, targetCurrentIdx: 0) }
        }

        // DP matrix for LCS
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        for i in 0..<m {
            for j in 0..<n {
                if base[i] == current[j] {
                    dp[i + 1][j + 1] = dp[i][j] + 1
                } else {
                    dp[i + 1][j + 1] = max(dp[i + 1][j], dp[i][j + 1])
                }
            }
        }

        // Backtrack to reconstruct edits
        var i = m
        var j = n
        var edits: [DiffEdit] = []

        while i > 0 || j > 0 {
            if i > 0 && j > 0 && base[i - 1] == current[j - 1] {
                edits.append(.keep(baseIdx: i - 1, currentIdx: j - 1))
                i -= 1
                j -= 1
            } else if j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j]) {
                edits.append(.add(currentIdx: j - 1))
                j -= 1
            } else if i > 0 && (j == 0 || dp[i][j - 1] < dp[i - 1][j]) {
                let targetIdx = max(0, min(j, n - 1))
                edits.append(.delete(baseIdx: i - 1, targetCurrentIdx: targetIdx))
                i -= 1
            }
        }

        edits.reverse()

        // Combine adjacent delete + add pairs into modify edits
        var optimizedEdits: [DiffEdit] = []
        var idx = 0
        while idx < edits.count {
            if idx + 1 < edits.count,
               case .delete(let bIdx, let cIdx) = edits[idx],
               case .add(let cIdx2) = edits[idx + 1],
               cIdx == cIdx2 {
                optimizedEdits.append(.modify(baseIdx: bIdx, currentIdx: cIdx2))
                idx += 2
            } else {
                optimizedEdits.append(edits[idx])
                idx += 1
            }
        }

        return optimizedEdits
    }
}
