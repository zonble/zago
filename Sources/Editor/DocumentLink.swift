import Foundation

public struct DocumentLink: Equatable, Sendable {
    public let target: String
    public let range: Range<Int>

    public init(target: String, range: Range<Int>) {
        self.target = target
        self.range = range
    }
}

public enum DocumentLinkParser {
    public static func link(atColumn column: Int, in line: String) -> DocumentLink? {
        let links = links(in: line)
        guard !links.isEmpty else { return nil }

        let clampedColumn = max(0, min(column, line.count))
        if let exact = links.first(where: { contains(column: clampedColumn, in: $0.range) }) {
            return exact
        }

        return links.count == 1 ? links[0] : nil
    }

    public static func links(in line: String) -> [DocumentLink] {
        [
            markdownLinks(in: line),
            orgLinks(in: line),
            reStructuredTextLinks(in: line),
            asciiDocLinks(in: line),
            bareDocumentPaths(in: line),
        ].flatMap { $0 }.sorted { $0.range.lowerBound < $1.range.lowerBound }
    }

    public static func localPathTarget(from rawTarget: String) -> String? {
        var target = rawTarget.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return nil }

        if target.hasPrefix("<"), target.hasSuffix(">") {
            target = String(target.dropFirst().dropLast())
        }

        if target.lowercased().hasPrefix("file:") {
            target = String(target.dropFirst(5))
        }

        if target.hasPrefix("#") || target.hasPrefix("*") {
            return nil
        }

        let lower = target.lowercased()
        if lower.hasPrefix("http://")
            || lower.hasPrefix("https://")
            || lower.hasPrefix("mailto:")
            || lower.hasPrefix("id:")
        {
            return nil
        }

        if let range = target.range(of: "::") {
            target = String(target[..<range.lowerBound])
        }
        if let range = target.range(of: "#") {
            target = String(target[..<range.lowerBound])
        }
        if let range = target.range(of: "?") {
            target = String(target[..<range.lowerBound])
        }

        target = target.removingPercentEncoding ?? target
        target = target.trimmingCharacters(in: .whitespacesAndNewlines)
        return target.isEmpty ? nil : target
    }

    public static func resolvedPath(target: String, currentFilePath: String?) -> String? {
        guard let localTarget = localPathTarget(from: target) else { return nil }

        let expanded = NSString(string: localTarget).expandingTildeInPath
        if expanded.hasPrefix("/") {
            return expanded
        }

        let baseDirectory: String
        if let currentFilePath, !currentFilePath.isEmpty {
            baseDirectory = URL(fileURLWithPath: currentFilePath).deletingLastPathComponent().path
        } else {
            baseDirectory = FileManager.default.currentDirectoryPath
        }

        return URL(fileURLWithPath: baseDirectory).appendingPathComponent(expanded).standardizedFileURL.path
    }

    private static func markdownLinks(in line: String) -> [DocumentLink] {
        matches(pattern: #"!?\[[^\]\n]*\]\(([^)\n]+)\)"#, in: line).compactMap { match in
            guard let target = targetFromMarkdownDestination(match.groups[0]) else { return nil }
            return DocumentLink(target: target, range: match.range)
        }
    }

    private static func orgLinks(in line: String) -> [DocumentLink] {
        matches(pattern: #"\[\[([^\]\n]+)\](?:\[[^\]\n]*\])?\]"#, in: line).map { match in
            DocumentLink(target: match.groups[0], range: match.range)
        }
    }

    private static func reStructuredTextLinks(in line: String) -> [DocumentLink] {
        let inlineLinks = matches(pattern: #"`[^`\n<]+<([^>\n]+)>`_"#, in: line).map { match in
            DocumentLink(target: match.groups[0], range: match.range)
        }
        let roleLinks = matches(pattern: #":(?:doc|download):`([^`\n]+)`"#, in: line).map { match in
            DocumentLink(target: match.groups[0], range: match.range)
        }
        return inlineLinks + roleLinks
    }

    private static func asciiDocLinks(in line: String) -> [DocumentLink] {
        let inlineLinks = matches(pattern: #"\b(?:link|xref):([^\[\s]+)\[[^\]\n]*\]"#, in: line).map { match in
            DocumentLink(target: match.groups[0], range: match.range)
        }
        let includeLinks = matches(pattern: #"\binclude::([^\[\s]+)\[[^\]\n]*\]"#, in: line).map { match in
            DocumentLink(target: match.groups[0], range: match.range)
        }
        let angleLinks = matches(pattern: #"<<([^>,\n]+)(?:,[^>\n]*)?>>"#, in: line).map { match in
            DocumentLink(target: match.groups[0], range: match.range)
        }
        return inlineLinks + includeLinks + angleLinks
    }

    private static func bareDocumentPaths(in line: String) -> [DocumentLink] {
        matches(pattern: #"(?<![\w/.-])([A-Za-z0-9_./~-]+\.(?:md|markdown|org|rst|rest|adoc|asciidoc|asc|ascii))(?![\w/.-])"#, in: line)
            .map { match in
                DocumentLink(target: match.groups[0], range: match.range)
            }
    }

    private static func targetFromMarkdownDestination(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("<"), let closing = trimmed.firstIndex(of: ">") {
            return String(trimmed[trimmed.index(after: trimmed.startIndex)..<closing])
        }
        return trimmed.split(whereSeparator: \.isWhitespace).first.map(String.init)
    }

    private static func contains(column: Int, in range: Range<Int>) -> Bool {
        if range.isEmpty {
            return column == range.lowerBound
        }
        return column >= range.lowerBound && column < range.upperBound
    }

    private struct RegexMatch {
        let range: Range<Int>
        let groups: [String]
    }

    private static func matches(pattern: String, in line: String) -> [RegexMatch] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(line.startIndex..<line.endIndex, in: line)

        return regex.matches(in: line, range: nsRange).compactMap { match in
            guard let whole = Range(match.range(at: 0), in: line) else { return nil }
            let start = line.distance(from: line.startIndex, to: whole.lowerBound)
            let end = line.distance(from: line.startIndex, to: whole.upperBound)

            let groups = (1..<match.numberOfRanges).compactMap { index -> String? in
                guard let range = Range(match.range(at: index), in: line) else { return nil }
                return String(line[range])
            }
            return RegexMatch(range: start..<end, groups: groups)
        }
    }
}
