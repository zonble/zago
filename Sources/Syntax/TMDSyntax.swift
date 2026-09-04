import DocumentOutline
import Foundation

/// Syntax definition for TMD (Text Music Description) files.
public struct TMDSyntaxDefinition: SyntaxDefinition {
    public let name = "TMD"
    public let fileExtensions = ["tmd"]
    public var commentPrefix: String { "/* " }
    public var supportsDocumentOutline: Bool { true }

    public init() {}

    public var headerRules: [NSRegularExpression] {
        (try? [
            NSRegularExpression(pattern: #"^\s*::SCORE::\s*$"#)
        ]) ?? []
    }

    public var rules: [SyntaxRule] {
        [
            // 1. Block comments /* ... */
            makeRule(#"/\*.*?\*/"#, .comment),
            makeRule(#"/\*.*$"#, .comment),

            // 2. Header root ::SCORE::
            makeRule(#"::SCORE::"#, .keyword),

            // 3. Title ** Title **
            makeRule(#"\*\*[^*]+\*\*"#, .string),

            // 4. Global settings and inline directives
            // Tempo: != 120, ! = 120, {!=120}, {!+30}
            makeRule(#"(!\s*=|\{!=[0-9.]+\}|\{![\+][0-9.]+\})"#, .keyword),
            // Key: ?= C, ? = A', {?=C}, {?+1}, {?-1}
            makeRule(#"(\?\s*=|\{\?=[A-Ga-g0-9',#b]+\}|\{\?[\+-][A-Ga-g0-9',#b]+\})"#, .keyword),
            // Time signature: <4/4>, {<4/4>}
            makeRule(#"(\{[<][0-9]+/[0-9]+[>]\}|<[0-9]+/[0-9]+>)"#, .typeOrAttribute),

            // 5. Sections / Subdivisions: <4*>, <8*>, <16*>
            makeRule(#"<[0-9]+\*>"#, .typeOrAttribute),

            // 6. Playback orders: ->#, -> {modulation}, -> sectionName
            makeRule(#"->\s*#"#, .keyword),
            makeRule(#"->\s*\{[^{}]+\}"#, .keyword),
            makeRule(#"->\s*[a-zA-Z0-9_\u4e00-\u9fa5-]+"#, .keyword),

            // 7. Paragraph / Instrument header: section:instrument@|0|{ or section:instrument{
            makeRule(#"[a-zA-Z0-9_\u4e00-\u9fa5-]+:[a-zA-Z0-9_\u4e00-\u9fa5-]+(@\|?[+-]?[0-9]+\|?)?\s*\{"#, .typeOrAttribute),

            // 8. Chords: [C], [Am7], [G/B]
            makeRule(#"\[[^\]]+\]"#, .typeOrAttribute),

            // 9. Tuplet modifiers: %(---)
            makeRule(#"%\(-+\)"#, .keyword),

            // 10. Notes: numbered musical notation 1-7 with accidentals and octave markers
            // e.g. 1, 1', 1,, 1_, 1^, 1'__
            makeRule(#"[1-7]['',#b]*[_^]*"#, .number),

            // 11. Ties & barlines
            makeRule(#"(\||-)"#, .keyword),

            // 12. General standalone numbers (e.g. tempo numbers)
            makeRule(#"\b[0-9]+(\.[0-9]+)?\b"#, .number),
        ].compactMap { $0 }
    }

    public func documentOutline(in lines: [String]) -> DocumentOutline? {
        var headings: [DocumentHeading] = []
        let sectionRegex = try? NSRegularExpression(
            pattern: #"^([a-zA-Z0-9_\u4e00-\u9fa5-]+):([a-zA-Z0-9_\u4e00-\u9fa5-]+)(?:@\|?([+-]?[0-9]+)?\|?)?\s*\{"#
        )
        let titleRegex = try? NSRegularExpression(pattern: #"^\s*\*\*\s*([^*]+)\s*\*\*"#)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("/*") {
                continue
            }

            if let titleRegex {
                let range = NSRange(location: 0, length: (trimmed as NSString).length)
                if let match = titleRegex.firstMatch(in: trimmed, options: [], range: range),
                    let titleRange = Range(match.range(at: 1), in: trimmed)
                {
                    let titleText = String(trimmed[titleRange]).trimmingCharacters(in: .whitespaces)
                    headings.append(DocumentHeading(lineIndex: index, level: 1, title: titleText, marker: "**"))
                    continue
                }
            }

            if let sectionRegex {
                let range = NSRange(location: 0, length: (line as NSString).length)
                if let match = sectionRegex.firstMatch(in: line, options: [], range: range),
                    let sectionRange = Range(match.range(at: 1), in: line),
                    let instRange = Range(match.range(at: 2), in: line)
                {
                    let section = String(line[sectionRange])
                    let instrument = String(line[instRange])
                    let title = "\(section) (\(instrument))"
                    headings.append(DocumentHeading(lineIndex: index, level: 2, title: title, marker: ":"))
                }
            }
        }

        return headings.isEmpty ? nil : DocumentOutline(headings: headings)
    }
}
