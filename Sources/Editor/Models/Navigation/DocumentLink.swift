import DocumentOutline
import Foundation

public struct ParsedLinkTarget: Equatable, Sendable {
    public let path: String?
    public let anchor: String?

    public init(path: String?, anchor: String?) {
        self.path = path
        self.anchor = anchor
    }
}

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

    public static func parseTarget(_ rawTarget: String) -> ParsedLinkTarget? {
        var target = rawTarget.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return nil }

        if target.hasPrefix("<"), target.hasSuffix(">") {
            target = String(target.dropFirst().dropLast())
        }

        if target.lowercased().hasPrefix("file:") {
            target = String(target.dropFirst(5))
        }

        let lower = target.lowercased()
        if lower.hasPrefix("http://")
            || lower.hasPrefix("https://")
            || lower.hasPrefix("mailto:")
            || lower.hasPrefix("id:")
        {
            return nil
        }

        var pathPart: String? = nil
        var anchorPart: String? = nil

        if let range = target.range(of: "::") {
            let pathSub = String(target[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let anchorSub = String(target[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            pathPart = pathSub.isEmpty ? nil : pathSub
            anchorPart = anchorSub.isEmpty ? nil : anchorSub
        } else if let range = target.range(of: "#") {
            let pathSub = String(target[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            let anchorSub = String(target[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            pathPart = pathSub.isEmpty ? nil : pathSub
            anchorPart = anchorSub.isEmpty ? nil : anchorSub
        } else if target.hasPrefix("*") {
            anchorPart = String(target.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let isFilePath =
                target.contains("/")
                || target.contains("\\")
                || target.hasPrefix(".")
                || [".md", ".markdown", ".org", ".rst", ".rest", ".adoc", ".asciidoc", ".asc", ".ascii", ".txt"]
                    .contains { ext in
                        target.lowercased().hasSuffix(ext)
                    }

            if isFilePath {
                pathPart = target
            } else {
                anchorPart = target
            }
        }

        if let a = anchorPart {
            var cleanA = a.trimmingCharacters(in: .whitespacesAndNewlines)
            while cleanA.hasPrefix("#") || cleanA.hasPrefix("*") {
                cleanA = String(cleanA.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            anchorPart = cleanA.isEmpty ? nil : cleanA
        }

        if pathPart == nil && anchorPart == nil {
            return nil
        }

        if let p = pathPart {
            var cleanP = p.removingPercentEncoding ?? p
            cleanP = cleanP.trimmingCharacters(in: .whitespacesAndNewlines)
            pathPart = cleanP.isEmpty ? nil : cleanP
        }

        return ParsedLinkTarget(path: pathPart, anchor: anchorPart)
    }

    public static func localPathTarget(from rawTarget: String) -> String? {
        parseTarget(rawTarget)?.path
    }

    public static func resolvedPath(target: String, currentFilePath: String?) -> String? {
        guard let parsed = parseTarget(target) else { return nil }
        guard let localTarget = parsed.path else { return nil }

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

    public static func findAnchorLineIndex(anchor: String, in lines: [String], syntaxName: String? = nil) -> Int? {
        let rawAnchor = anchor.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawAnchor.isEmpty, !lines.isEmpty else { return nil }

        var cleanAnchor = rawAnchor
        while cleanAnchor.hasPrefix("#") || cleanAnchor.hasPrefix("*") {
            cleanAnchor = String(cleanAnchor.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard !cleanAnchor.isEmpty else { return nil }

        let lowerClean = cleanAnchor.lowercased()
        let slugAnchor = slugify(cleanAnchor)

        // Pass 1: Explicit target anchors / IDs
        for (idx, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            // reST target: .. _anchor:
            if trimmed.hasPrefix(".. _") {
                let targetName = String(trimmed.dropFirst(4)).trimmingCharacters(in: CharacterSet(charactersIn: ": \t"))
                if targetName.lowercased() == lowerClean || slugify(targetName) == slugAnchor {
                    return idx
                }
            }
            // AsciiDoc anchor: [[anchor]] or [#anchor] or [id="anchor"]
            if trimmed.hasPrefix("[[") && trimmed.hasSuffix("]]") {
                let idStr = String(trimmed.dropFirst(2).dropLast(2)).trimmingCharacters(in: .whitespaces)
                if idStr.lowercased() == lowerClean || slugify(idStr) == slugAnchor {
                    return idx
                }
            }
            if trimmed.hasPrefix("[#") && trimmed.hasSuffix("]") {
                let idStr = String(trimmed.dropFirst(2).dropLast(1)).trimmingCharacters(in: .whitespaces)
                if idStr.lowercased() == lowerClean || slugify(idStr) == slugAnchor {
                    return idx
                }
            }
            // Org-mode CUSTOM_ID or #+NAME:
            if trimmed.lowercased().hasPrefix(":custom_id:") {
                let idStr = String(trimmed.dropFirst(11)).trimmingCharacters(in: .whitespaces)
                if idStr.lowercased() == lowerClean || slugify(idStr) == slugAnchor {
                    return idx
                }
            }
            if trimmed.lowercased().hasPrefix("#+name:") {
                let idStr = String(trimmed.dropFirst(7)).trimmingCharacters(in: .whitespaces)
                if idStr.lowercased() == lowerClean || slugify(idStr) == slugAnchor {
                    return idx
                }
            }
            // HTML anchor: <a name="anchor"> or <a id="anchor"> or {#anchor}
            if trimmed.contains("id=\"\(cleanAnchor)\"") || trimmed.contains("name=\"\(cleanAnchor)\"")
                || trimmed.contains("id='\(cleanAnchor)'") || trimmed.contains("name='\(cleanAnchor)'")
                || trimmed.contains("{#\(cleanAnchor)}")
            {
                return idx
            }
        }

        // Pass 2: Headings matched via DocumentOutline
        let outline = DocumentOutlineParser.parse(lines: lines)
        for heading in outline.headings {
            let headingTitle = heading.title.trimmingCharacters(in: .whitespaces)
            let headingLower = headingTitle.lowercased()
            let headingSlug = slugify(headingTitle)

            if headingLower == lowerClean || headingSlug == slugAnchor || headingSlug == lowerClean {
                return heading.lineIndex
            }
        }

        // Pass 3: Heading line starts or content contains
        for (idx, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let isHeadingLine = trimmed.hasPrefix("#") || trimmed.hasPrefix("*") || trimmed.hasPrefix("=")
            if isHeadingLine {
                let lineLower = trimmed.lowercased()
                if lineLower.contains(lowerClean) || slugify(trimmed).contains(slugAnchor) {
                    return idx
                }
            }
        }

        // Pass 4: Any line containing cleanAnchor
        for (idx, line) in lines.enumerated() {
            if line.lowercased().contains(lowerClean) {
                return idx
            }
        }

        return nil
    }

    private static func slugify(_ str: String) -> String {
        let lower = str.lowercased()
        let components = lower.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        return components.joined(separator: "-")
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
        let simpleLinks = matches(pattern: #"`([^`\n]+)`_"#, in: line).map { match in
            DocumentLink(target: match.groups[0], range: match.range)
        }
        let roleLinks = matches(pattern: #":(?:doc|download|ref):`([^`\n]+)`"#, in: line).map { match in
            DocumentLink(target: match.groups[0], range: match.range)
        }
        return inlineLinks + simpleLinks + roleLinks
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
        matches(
            pattern:
                #"(?<![\w/.-])([A-Za-z0-9_./~-]+\.(?:md|markdown|org|rst|rest|adoc|asciidoc|asc|ascii))(?![\w/.-])"#,
            in: line
        )
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
