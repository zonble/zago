import Foundation

/// Extension logic for detecting embedded code block languages inside prose markup files (Markdown, RST, Org, AsciiDoc, Wiki).
extension SyntaxHighlighter {
    /// Determines LanguageSyntax for a specific buffer line, accounting for Markdown/RST/Org-mode embedded code blocks.
    public func getSyntaxForLine(
        filePath: String?,
        isDirectoryBuffer: Bool,
        lines: [String],
        bufferLineIndex: Int,
        isEnabled: Bool
    ) -> LanguageSyntax? {
        guard isEnabled else { return nil }
        if isDirectoryBuffer {
            return DirectorySyntax.syntax
        }
        let defaultSyntax = detectLanguage(for: filePath)

        let ext = (filePath as NSString? ?? "").pathExtension.lowercased()
        let isMarkup = [
            "md", "markdown", "mdown", "mkd", "rst", "rest", "org", "adoc", "asciidoc", "ascii", "wiki", "mediawiki",
        ].contains(ext)
        guard isMarkup else { return defaultSyntax }

        guard bufferLineIndex >= 0 && bufferLineIndex < lines.count else { return defaultSyntax }

        if let embedded = detectEmbeddedLanguage(in: lines, bufferLineIndex: bufferLineIndex, fileExtension: ext) {
            return embedded
        }
        return defaultSyntax
    }

    /// Detects embedded code block language in Markdown, RST, Org-mode, AsciiDoc, or Wiki buffer up to bufferLineIndex.
    public func detectEmbeddedLanguage(in lines: [String], bufferLineIndex: Int, fileExtension: String)
        -> LanguageSyntax?
    {
        var activeLangName: String? = nil
        var inBlock = false

        if fileExtension == "org" {
            for i in 0...bufferLineIndex {
                let line = lines[i].trimmingCharacters(in: .whitespaces)
                let upper = line.uppercased()
                if upper.hasPrefix("#+BEGIN_SRC") {
                    inBlock = true
                    let langStr = String(line.dropFirst("#+BEGIN_SRC".count)).trimmingCharacters(in: .whitespaces)
                    activeLangName = langStr.isEmpty ? nil : langStr
                } else if upper.hasPrefix("#+END_SRC") {
                    inBlock = false
                    activeLangName = nil
                }
            }
            if inBlock, let langName = activeLangName {
                let currentLine = lines[bufferLineIndex].trimmingCharacters(in: .whitespaces).uppercased()
                if currentLine.hasPrefix("#+BEGIN_SRC") || currentLine.hasPrefix("#+END_SRC") {
                    return nil
                }
                return findLanguage(named: langName)
            }
        } else if fileExtension == "rst" || fileExtension == "rest" {
            for i in 0...bufferLineIndex {
                let line = lines[i]
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix(".. code-block::") || trimmed.hasPrefix(".. code::")
                    || trimmed.hasPrefix(".. highlight::")
                {
                    inBlock = true
                    if let range = trimmed.range(of: "::") {
                        let langStr = String(trimmed[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                        activeLangName = langStr.isEmpty ? nil : langStr
                    }
                } else if inBlock {
                    if !trimmed.isEmpty && !line.hasPrefix(" ") && !line.hasPrefix("\t") && !trimmed.hasPrefix("..") {
                        inBlock = false
                        activeLangName = nil
                    }
                }
            }
            if inBlock, let langName = activeLangName {
                let currentLine = lines[bufferLineIndex].trimmingCharacters(in: .whitespaces)
                if currentLine.hasPrefix("..") {
                    return nil
                }
                return findLanguage(named: langName)
            }
        } else if ["adoc", "asciidoc", "ascii"].contains(fileExtension) {
            for i in 0...bufferLineIndex {
                let line = lines[i].trimmingCharacters(in: .whitespaces)
                if line.hasPrefix("[source") && line.contains("]") {
                    if let start = line.firstIndex(of: ","), let end = line.firstIndex(of: "]"), start < end {
                        let langStr = String(line[line.index(after: start)..<end]).trimmingCharacters(in: .whitespaces)
                        activeLangName = langStr.isEmpty ? nil : langStr
                    }
                } else if line.hasPrefix("----") || line.hasPrefix("....") {
                    if inBlock {
                        inBlock = false
                        activeLangName = nil
                    } else if activeLangName != nil {
                        inBlock = true
                    }
                }
            }
            if inBlock, let langName = activeLangName {
                let currentLine = lines[bufferLineIndex].trimmingCharacters(in: .whitespaces)
                if currentLine.hasPrefix("----") || currentLine.hasPrefix("....") || currentLine.hasPrefix("[source") {
                    return nil
                }
                return findLanguage(named: langName)
            }
        } else if ["wiki", "mediawiki"].contains(fileExtension) {
            for i in 0...bufferLineIndex {
                let line = lines[i].trimmingCharacters(in: .whitespaces).lowercased()
                if line.contains("<syntaxhighlight") || line.contains("<source") || line.contains("<code") {
                    if let langRange = line.range(of: "lang=\"") ?? line.range(of: "lang='") {
                        let rest = line[langRange.upperBound...]
                        if let quoteEnd = rest.firstIndex(where: { $0 == "\"" || $0 == "'" }) {
                            let langStr = String(rest[..<quoteEnd]).trimmingCharacters(in: .whitespaces)
                            activeLangName = langStr.isEmpty ? nil : langStr
                            inBlock = true
                        }
                    }
                }
                if line.contains("</syntaxhighlight>") || line.contains("</source>") || line.contains("</code>") {
                    inBlock = false
                    activeLangName = nil
                }
            }
            if inBlock, let langName = activeLangName {
                let currentLine = lines[bufferLineIndex].trimmingCharacters(in: .whitespaces).lowercased()
                if currentLine.contains("<syntaxhighlight") || currentLine.contains("<source")
                    || currentLine.contains("<code") || currentLine.contains("</syntaxhighlight>")
                    || currentLine.contains("</source>") || currentLine.contains("</code>")
                {
                    return nil
                }
                return findLanguage(named: langName)
            }
        } else {
            // Markdown (md, markdown, mdown, mkd)
            for i in 0...bufferLineIndex {
                let line = lines[i].trimmingCharacters(in: .whitespaces)
                if line.hasPrefix("```") || line.hasPrefix("~~~") {
                    if inBlock {
                        inBlock = false
                        activeLangName = nil
                    } else {
                        inBlock = true
                        let langStr = String(line.drop(while: { $0 == "`" || $0 == "~" })).trimmingCharacters(
                            in: .whitespaces)
                        activeLangName = langStr.isEmpty ? nil : langStr
                    }
                }
            }
            if inBlock, let langName = activeLangName {
                let currentLine = lines[bufferLineIndex].trimmingCharacters(in: .whitespaces)
                if currentLine.hasPrefix("```") || currentLine.hasPrefix("~~~") {
                    return nil
                }
                return findLanguage(named: langName)
            }
        }

        return nil
    }
}
