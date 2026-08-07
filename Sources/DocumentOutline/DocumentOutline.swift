import Foundation

public struct DocumentHeading: Equatable, Sendable {
    public let lineIndex: Int
    public let level: Int
    public let title: String
    public let marker: String

    public init(lineIndex: Int, level: Int, title: String, marker: String) {
        self.lineIndex = lineIndex
        self.level = level
        self.title = title
        self.marker = marker
    }
}

public struct DocumentOutline: Equatable, Sendable {
    public let headings: [DocumentHeading]

    public init(headings: [DocumentHeading] = []) {
        self.headings = headings
    }
}

public enum DocumentOutlineParser {
    public static func parse(lines: [String], customParser: (@Sendable ([String]) -> DocumentOutline?)? = nil) -> DocumentOutline {
        if let outline = customParser?(lines) {
            return outline
        }

        let outlines = [
            MarkdownOutlineParser.parse(lines: lines),
            OrgOutlineParser.parse(lines: lines),
            ReSTOutlineParser.parse(lines: lines),
            AsciiDocOutlineParser.parse(lines: lines),
        ]
        var seenKeys: Set<String> = []
        let headings = outlines.flatMap(\.headings).filter { heading in
            let key = "\(heading.lineIndex)\u{1F}\(heading.title)"
            guard !seenKeys.contains(key) else { return false }
            seenKeys.insert(key)
            return true
        }.sorted {
            if $0.lineIndex == $1.lineIndex { return $0.level < $1.level }
            return $0.lineIndex < $1.lineIndex
        }
        return DocumentOutline(headings: headings)
    }
}

public enum MarkdownOutlineParser {
    public static func parse(lines: [String]) -> DocumentOutline {
        var headings: [DocumentHeading] = []
        var fencedBlockMarker: String?

        for index in lines.indices {
            let trimmed = lines[index].trimmingCharacters(in: .whitespaces)
            if let marker = markdownFenceMarker(in: trimmed) {
                if fencedBlockMarker == nil {
                    fencedBlockMarker = marker
                } else if marker == fencedBlockMarker {
                    fencedBlockMarker = nil
                }
                continue
            }
            guard fencedBlockMarker == nil else { continue }

            if let heading = atxHeading(line: lines[index], lineIndex: index) {
                headings.append(heading)
            } else if index + 1 < lines.count,
                let heading = setextHeading(titleLine: lines[index], underlineLine: lines[index + 1], lineIndex: index)
            {
                headings.append(heading)
            }
        }

        return DocumentOutline(headings: headings)
    }

    private static func markdownFenceMarker(in trimmedLine: String) -> String? {
        if trimmedLine.hasPrefix("```") { "```" }
        else if trimmedLine.hasPrefix("~~~") { "~~~" }
        else { nil }
    }

    private static func atxHeading(line: String, lineIndex: Int) -> DocumentHeading? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let marker = String(trimmed.prefix(while: { $0 == "#" }))
        guard !marker.isEmpty, marker.count <= 6 else { return nil }
        let rest = trimmed.dropFirst(marker.count)
        guard rest.first?.isWhitespace == true else { return nil }
        let title = stripClosingATXMarker(String(rest).trimmingCharacters(in: .whitespaces))
        guard !title.isEmpty else { return nil }
        return DocumentHeading(lineIndex: lineIndex, level: marker.count, title: title, marker: marker)
    }

    private static func stripClosingATXMarker(_ title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        guard trimmed.last == "#" else { return trimmed }
        var endIndex = trimmed.endIndex
        while endIndex > trimmed.startIndex {
            let previous = trimmed.index(before: endIndex)
            guard trimmed[previous] == "#" else { break }
            endIndex = previous
        }
        return String(trimmed[..<endIndex]).trimmingCharacters(in: .whitespaces)
    }

    private static func setextHeading(titleLine: String, underlineLine: String, lineIndex: Int) -> DocumentHeading? {
        let title = titleLine.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty, !title.hasPrefix("#"), !title.hasPrefix("|") else { return nil }
        let underline = underlineLine.trimmingCharacters(in: .whitespaces)
        guard !underline.isEmpty else { return nil }
        let markerChar = underline.first!
        guard markerChar == "=" || markerChar == "-" else { return nil }
        guard underline.allSatisfy({ $0 == markerChar }) else { return nil }
        guard underline.count >= title.count else { return nil }
        let level = markerChar == "=" ? 1 : 2
        return DocumentHeading(lineIndex: lineIndex, level: level, title: title, marker: String(markerChar))
    }
}

public enum OrgOutlineParser {
    public static func parse(lines: [String]) -> DocumentOutline {
        let headings = lines.enumerated().compactMap { index, line -> DocumentHeading? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let marker = String(trimmed.prefix(while: { $0 == "*" }))
            guard !marker.isEmpty else { return nil }
            let rest = trimmed.dropFirst(marker.count)
            guard rest.first?.isWhitespace == true else { return nil }
            let title = String(rest).trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty else { return nil }
            return DocumentHeading(lineIndex: index, level: marker.count, title: title, marker: marker)
        }
        return DocumentOutline(headings: headings)
    }
}

public enum ReSTOutlineParser {
    private static let underlineCharacters = CharacterSet(charactersIn: "=-`:.'\"~^_*+#")

    public static func parse(lines: [String]) -> DocumentOutline {
        var levelByMarker: [Character: Int] = [:]
        var markerOrder: [Character] = []
        var headings: [DocumentHeading] = []

        for index in 0..<max(0, lines.count - 1) {
            let title = lines[index].trimmingCharacters(in: .whitespaces)
            let underline = lines[index + 1].trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty, isUnderline(underline, title: title), let marker = underline.first else {
                continue
            }

            if levelByMarker[marker] == nil {
                markerOrder.append(marker)
                levelByMarker[marker] = markerOrder.count
            }
            headings.append(
                DocumentHeading(
                    lineIndex: index,
                    level: levelByMarker[marker] ?? 1,
                    title: title,
                    marker: String(marker)
                )
            )
        }

        return DocumentOutline(headings: headings)
    }

    private static func isUnderline(_ underline: String, title: String) -> Bool {
        guard !underline.isEmpty, underline.count >= title.count, let marker = underline.first else { return false }
        guard String(marker).rangeOfCharacter(from: underlineCharacters) != nil else { return false }
        return underline.allSatisfy { $0 == marker }
    }
}

public enum AsciiDocOutlineParser {
    public static func parse(lines: [String]) -> DocumentOutline {
        let headings = lines.enumerated().compactMap { index, line -> DocumentHeading? in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let marker = String(trimmed.prefix(while: { $0 == "=" }))
            guard !marker.isEmpty, marker.count <= 6 else { return nil }
            let rest = trimmed.dropFirst(marker.count)
            guard rest.first?.isWhitespace == true else { return nil }
            let title = String(rest).trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty else { return nil }
            return DocumentHeading(lineIndex: index, level: marker.count, title: title, marker: marker)
        }
        return DocumentOutline(headings: headings)
    }
}
