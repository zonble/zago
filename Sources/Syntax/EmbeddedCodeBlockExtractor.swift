import Foundation

/// Represents the result of extracting an embedded code block from a document.
public struct EmbeddedCodeBlockResult: Sendable, Equatable {
    public let script: String
    public let startLine: Int

    public init(script: String, startLine: Int) {
        self.script = script
        self.startLine = startLine
    }
}

/// Helper for extracting embedded code blocks (e.g. Markdown fenced code blocks or Org-mode source blocks)
/// matching a target language from document buffer lines.
public enum EmbeddedCodeBlockExtractor {
    /// Extracts an embedded code block matching `targetLanguage` (default: "logo") at the specified line index.
    /// Supports Markdown fenced code blocks (```logo / ~~~logo) and Org-mode source blocks (#+BEGIN_SRC logo ... #+END_SRC).
    public static func extractBlock(
        targetLanguage: String = "logo",
        in lines: [String],
        lineIndex: Int
    ) -> EmbeddedCodeBlockResult? {
        guard !lines.isEmpty && lineIndex >= 0 && lineIndex < lines.count else { return nil }
        let targetLang = targetLanguage.lowercased()

        // Org-mode helpers
        let isOrgBegin: (String) -> Bool = { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.uppercased().hasPrefix("#+BEGIN_SRC") else { return false }
            let rest = trimmed.dropFirst("#+BEGIN_SRC".count).trimmingCharacters(in: .whitespaces)
            guard let lang = rest.split(separator: " ").first else { return false }
            return lang.lowercased() == targetLang
        }

        let isOrgEnd: (String) -> Bool = { line in
            line.trimmingCharacters(in: .whitespaces).uppercased().hasPrefix("#+END_SRC")
        }

        // 1. Check if cursor is on Org-mode #+END_SRC or line right after #+END_SRC
        var orgEndLine: Int? = nil
        if isOrgEnd(lines[lineIndex]) {
            orgEndLine = lineIndex
        } else if lineIndex > 0 && isOrgEnd(lines[lineIndex - 1]) {
            orgEndLine = lineIndex - 1
        }

        if let end = orgEndLine {
            for r in (0..<end).reversed() {
                let line = lines[r]
                if isOrgBegin(line) {
                    let scriptLines = end > r + 1 ? Array(lines[(r + 1)..<end]) : []
                    return EmbeddedCodeBlockResult(script: scriptLines.joined(separator: "\n"), startLine: r + 1)
                }
                if isOrgEnd(line) { break }
            }
        }

        // 2. Scan upwards for Org-mode #+BEGIN_SRC logo
        var orgStartLine: Int? = nil
        for r in (0...lineIndex).reversed() {
            let line = lines[r]
            if isOrgBegin(line) {
                orgStartLine = r
                break
            }
            if isOrgEnd(line) && r < lineIndex && r != lineIndex - 1 {
                break
            }
        }

        if let start = orgStartLine {
            var end: Int? = nil
            for r in (start + 1)..<lines.count {
                if isOrgEnd(lines[r]) {
                    end = r
                    break
                }
            }
            if let end = end, lineIndex >= start && lineIndex <= end + 1 {
                let scriptLines = end > start + 1 ? Array(lines[(start + 1)..<end]) : []
                return EmbeddedCodeBlockResult(script: scriptLines.joined(separator: "\n"), startLine: start + 1)
            }
        }

        // 3. Markdown fenced code blocks (```logo or ~~~logo)
        let isMarkdownBegin: (String) -> String? = { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces).lowercased()
            if trimmed.hasPrefix("```" + targetLang) { return "```" }
            if trimmed.hasPrefix("~~~" + targetLang) { return "~~~" }
            return nil
        }

        let isMarkdownFence: (String) -> String? = { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") { return "```" }
            if trimmed.hasPrefix("~~~") { return "~~~" }
            return nil
        }

        // Check if cursor is on Markdown closing fence or line right after
        var mdFenceEnd: (line: Int, marker: String)? = nil
        let lineAtCurrent = lines[lineIndex].trimmingCharacters(in: .whitespaces).lowercased()
        if let marker = isMarkdownFence(lines[lineIndex]), !lineAtCurrent.contains(targetLang) {
            mdFenceEnd = (lineIndex, marker)
        } else if lineIndex > 0 {
            let prevLine = lines[lineIndex - 1].trimmingCharacters(in: .whitespaces).lowercased()
            if let marker = isMarkdownFence(lines[lineIndex - 1]), !prevLine.contains(targetLang) {
                mdFenceEnd = (lineIndex - 1, marker)
            }
        }

        if let (end, marker) = mdFenceEnd {
            for r in (0..<end).reversed() {
                if let beginMarker = isMarkdownBegin(lines[r]), beginMarker == marker {
                    let scriptLines = end > r + 1 ? Array(lines[(r + 1)..<end]) : []
                    return EmbeddedCodeBlockResult(script: scriptLines.joined(separator: "\n"), startLine: r + 1)
                }
                if isMarkdownFence(lines[r]) != nil && r < end {
                    break
                }
            }
        }

        // Scan upwards for Markdown opening fence
        var mdStartLine: (line: Int, marker: String)? = nil
        for r in (0...lineIndex).reversed() {
            if let marker = isMarkdownBegin(lines[r]) {
                mdStartLine = (r, marker)
                break
            }
            if isMarkdownFence(lines[r]) != nil && r < lineIndex && r != lineIndex - 1 {
                break
            }
        }

        if let (start, marker) = mdStartLine {
            var end: Int? = nil
            for r in (start + 1)..<lines.count {
                let line = lines[r].trimmingCharacters(in: .whitespaces)
                if line.hasPrefix(marker) {
                    end = r
                    break
                }
            }
            if let end = end, lineIndex >= start && lineIndex <= end + 1 {
                let scriptLines = end > start + 1 ? Array(lines[(start + 1)..<end]) : []
                return EmbeddedCodeBlockResult(script: scriptLines.joined(separator: "\n"), startLine: start + 1)
            }
        }

        return nil
    }
}
