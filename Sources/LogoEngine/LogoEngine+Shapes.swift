import Foundation

extension LogoEngine {
    internal func executeDateCommand(_ tokens: [String], index: inout Int, on editor: LogoEditorContext) {
        let dateStr = evaluateTokenOrCommand(tokens, index: &index)
        editor.insertString(dateStr)
    }

    internal func executeTimeCommand(_ tokens: [String], index: inout Int, on editor: LogoEditorContext) {
        let timeStr = evaluateTokenOrCommand(tokens, index: &index)
        editor.insertString(timeStr)
    }

    internal func executeLineCommand(_ tokens: [String], index: inout Int, on editor: LogoEditorContext) {
        var length = 40
        var styleChar: Character = "─"

        if index < tokens.count {
            let firstToken = tokens[index]
            let upperFirst = firstToken.uppercased()

            if (!LogoEngine.keywords.contains(upperFirst) || firstToken.hasPrefix("\"")) && firstToken != "]" {
                let valStr = evaluateExpression(tokens, index: &index)
                length = max(1, min(Int(valStr) ?? 40, 200))

                if index + 1 < tokens.count {
                    let nextUpper = tokens[index + 1].uppercased()
                    if !LogoEngine.keywords.contains(nextUpper) || nextUpper == "DOUBLE" || nextUpper == "ASCII" {
                        index += 1
                        let sStr = evaluateExpression(tokens, index: &index)
                        if sStr == "double" { styleChar = "═" }
                        else if sStr == "ascii" { styleChar = "-" }
                    }
                }
            } else {
                index -= 1
            }
        } else {
            index -= 1
        }

        let startCol = editor.columnIndex
        let startLine = editor.lineIndex

        editor.ensureLineExists(at: startLine)

        var currentChars = Array(editor.getLine(at: startLine))
        while currentChars.count < startCol {
            currentChars.append(" ")
        }

        for i in 0..<length {
            let col = startCol + i
            let moveMask = (i == 0) ? 2 : ((i == length - 1) ? 8 : 10)
            if col < currentChars.count {
                let existing = currentChars[col]
                currentChars[col] = fuseChar(existing: existing, defaultNewChar: styleChar, moveMask: moveMask)
            } else {
                currentChars.append(styleChar)
            }
        }

        editor.setLine(at: startLine, text: String(currentChars))
        editor.columnIndex = startCol + length
        editor.insertNewline()
    }

    internal func executeVlineCommand(_ tokens: [String], index: inout Int, on editor: LogoEditorContext) {
        var height = 5
        var styleChar: Character = "│"

        if index < tokens.count {
            let firstToken = tokens[index]
            let upperFirst = firstToken.uppercased()

            if (!LogoEngine.keywords.contains(upperFirst) || firstToken.hasPrefix("\"")) && firstToken != "]" {
                let valStr = evaluateExpression(tokens, index: &index)
                height = max(1, min(Int(valStr) ?? 5, 100))

                if index + 1 < tokens.count {
                    let nextUpper = tokens[index + 1].uppercased()
                    if !LogoEngine.keywords.contains(nextUpper) || nextUpper == "DOUBLE" || nextUpper == "ASCII" {
                        index += 1
                        let sStr = evaluateExpression(tokens, index: &index)
                        if sStr == "double" { styleChar = "║" }
                        else if sStr == "ascii" { styleChar = "|" }
                    }
                }
            } else {
                index -= 1
            }
        } else {
            index -= 1
        }

        let startCol = editor.columnIndex
        let startLine = editor.lineIndex

        for r in 0..<height {
            let line = startLine + r
            editor.ensureLineExists(at: line)

            var currentChars = Array(editor.getLine(at: startLine + r))
            while currentChars.count <= startCol {
                currentChars.append(" ")
            }

            let moveMask = (r == 0) ? 4 : ((r == height - 1) ? 1 : 5)
            let existing = currentChars[startCol]
            currentChars[startCol] = fuseChar(existing: existing, defaultNewChar: styleChar, moveMask: moveMask)

            editor.setLine(at: line, text: String(currentChars))
        }

        editor.lineIndex = startLine + height
        editor.columnIndex = startCol
    }

    internal func executeNewlineCommand(_ tokens: [String], index: inout Int, on editor: LogoEditorContext) {
        var count = 1
        if index < tokens.count {
            let firstToken = tokens[index]
            let upperFirst = firstToken.uppercased()

            if !LogoEngine.keywords.contains(upperFirst) && firstToken != "]" {
                let valStr = evaluateExpression(tokens, index: &index)
                count = max(1, min(Int(valStr) ?? 1, 50))
            } else {
                index -= 1
            }
        } else {
            index -= 1
        }

        for _ in 0..<count {
            editor.insertNewline()
        }
    }

    internal func executeBoxCommand(_ tokens: [String], index: inout Int, on editor: LogoEditorContext) {
        let boxSubKeywords: Set<String> = ["ASCII", "SINGLE", "DOUBLE", "ROUND", "LEFT", "CENTER", "CENTRE", "RIGHT"]

        guard index < tokens.count else {
            drawBoxFrame(width: 20, height: 5, style: .single, on: editor)
            return
        }

        let firstToken = tokens[index]

        // Mode 1: BOX width [height] ["text"] [align] [style]
        if let w = Int(unquote(firstToken)) {
            let width = max(3, min(w, 200))
            var height: Int? = nil
            var textContent: String? = nil
            var align = "left"
            var styleName = ""

            if index + 1 < tokens.count {
                let secondUpper = tokens[index + 1].uppercased()
                if let h = Int(unquote(secondUpper)) {
                    index += 1
                    height = max(2, min(h, 100))
                }
            }

            while index + 1 < tokens.count {
                let nextToken = tokens[index + 1]
                let nextUpper = nextToken.uppercased()
                if nextToken == "]" || nextToken == ")" || (LogoEngine.keywords.contains(nextUpper) && !boxSubKeywords.contains(nextUpper)) { break }
                index += 1
                let val = unquote(tokens[index])
                let valLower = val.lowercased()

                if valLower == "left" || valLower == "center" || valLower == "centre" || valLower == "right" {
                    align = valLower
                } else if valLower == "single" || valLower == "double" || valLower == "ascii" || valLower == "round" {
                    styleName = val
                } else if textContent == nil {
                    textContent = val
                }
            }

            if let text = textContent {
                drawBoxAroundText(text, targetWidth: width, targetHeight: height, align: align, style: BoxStyle.from(styleName), on: editor)
            } else {
                drawBoxFrame(width: width, height: height ?? 5, style: BoxStyle.from(styleName), on: editor)
            }
            return
        }

        // Mode 2: BOX "text" [align/style] [style/align]
        let textContent = evaluateExpression(tokens, index: &index)
        var align = "left"
        var styleName = ""

        while index + 1 < tokens.count {
            let nextToken = tokens[index + 1]
            let nextUpper = nextToken.uppercased()
            if nextToken == "]" || nextToken == ")" || (LogoEngine.keywords.contains(nextUpper) && !boxSubKeywords.contains(nextUpper)) { break }
            index += 1
            let val = unquote(tokens[index])
            let valLower = val.lowercased()

            if valLower == "left" || valLower == "center" || valLower == "centre" || valLower == "right" {
                align = valLower
            } else if valLower == "single" || valLower == "double" || valLower == "ascii" || valLower == "round" {
                styleName = val
            }
        }

        drawBoxAroundText(textContent, targetWidth: nil, targetHeight: nil, align: align, style: BoxStyle.from(styleName), on: editor)
    }

    private func drawBoxFrame(width: Int, height: Int, style: BoxStyle, on editor: LogoEditorContext) {
        let startCol = editor.columnIndex
        let startLine = editor.lineIndex

        for r in 0..<height {
            let currentLineIndex = startLine + r
            editor.ensureLineExists(at: currentLineIndex)

            var lineChars = Array(editor.getLine(at: currentLineIndex))
            while lineChars.count < startCol + width {
                lineChars.append(" ")
            }

            let isTop = (r == 0)
            let isBottom = (r == height - 1)

            for c in 0..<width {
                let targetCol = startCol + c
                let isLeft = (c == 0)
                let isRight = (c == width - 1)

                var ch: Character = " "
                var moveMask = 0

                if isTop && isLeft { ch = style.topLeft; moveMask = 6 }
                else if isTop && isRight { ch = style.topRight; moveMask = 12 }
                else if isBottom && isLeft { ch = style.bottomLeft; moveMask = 3 }
                else if isBottom && isRight { ch = style.bottomRight; moveMask = 9 }
                else if isTop { ch = style.topChar; moveMask = 10 }
                else if isBottom { ch = style.bottomChar; moveMask = 10 }
                else if isLeft || isRight { ch = style.sideChar; moveMask = 5 }

                if moveMask != 0 {
                    let existing = (targetCol < lineChars.count) ? lineChars[targetCol] : " "
                    lineChars[targetCol] = fuseChar(existing: existing, defaultNewChar: ch, moveMask: moveMask)
                } else {
                    lineChars[targetCol] = " "
                }
            }

            editor.setLine(at: currentLineIndex, text: String(lineChars))
        }

        editor.lineIndex = startLine + height - 1
        editor.columnIndex = startCol + width
    }

    private func drawBoxAroundText(_ text: String, targetWidth: Int?, targetHeight: Int?, align: String, style: BoxStyle, on editor: LogoEditorContext) {
        let rawLines = text.replacingOccurrences(of: "\\n", with: "\n").components(separatedBy: "\n")
        let calcWidth = targetWidth ?? ((rawLines.map { $0.count }.max() ?? 0) + 4)
        let innerWidth = max(1, calcWidth - 2)

        var textLines: [String] = []
        for rLine in rawLines {
            textLines.append(contentsOf: wrapTextLine(rLine, maxWidth: innerWidth))
        }

        let calcHeight = max(targetHeight ?? 0, textLines.count + 2)

        let startCol = editor.columnIndex
        let startLine = editor.lineIndex

        for r in 0..<calcHeight {
            let currentLineIndex = startLine + r
            editor.ensureLineExists(at: currentLineIndex)

            var lineChars = Array(editor.getLine(at: currentLineIndex))
            while lineChars.count < startCol + calcWidth {
                lineChars.append(" ")
            }

            let isTop = (r == 0)
            let isBottom = (r == calcHeight - 1)

            for c in 0..<calcWidth {
                let targetCol = startCol + c
                let isLeft = (c == 0)
                let isRight = (c == calcWidth - 1)

                var ch: Character = " "
                var moveMask = 0

                if isTop && isLeft { ch = style.topLeft; moveMask = 6 }
                else if isTop && isRight { ch = style.topRight; moveMask = 12 }
                else if isBottom && isLeft { ch = style.bottomLeft; moveMask = 3 }
                else if isBottom && isRight { ch = style.bottomRight; moveMask = 9 }
                else if isTop { ch = style.topChar; moveMask = 10 }
                else if isBottom { ch = style.bottomChar; moveMask = 10 }
                else if isLeft || isRight { ch = style.sideChar; moveMask = 5 }
                else if r >= 1 && (r - 1) < textLines.count {
                    let lineStr = textLines[r - 1]
                    let textWidth = lineStr.count
                    let textCol: Int
                    if align == "center" || align == "centre" {
                        let textOffset = max(0, (innerWidth - textWidth) / 2)
                        textCol = c - 1 - textOffset
                    } else if align == "right" {
                        let textOffset = max(0, innerWidth - textWidth)
                        textCol = c - 1 - textOffset
                    } else {
                        let textOffset = (innerWidth > textWidth) ? 1 : 0
                        textCol = c - 1 - textOffset
                    }

                    if textCol >= 0 && textCol < textWidth {
                        let textChars = Array(lineStr)
                        ch = textChars[textCol]
                    } else {
                        ch = " "
                    }
                    moveMask = 0
                } else {
                    ch = " "
                    moveMask = 0
                }

                if moveMask != 0 {
                    let existing = (targetCol < lineChars.count) ? lineChars[targetCol] : " "
                    lineChars[targetCol] = fuseChar(existing: existing, defaultNewChar: ch, moveMask: moveMask)
                } else {
                    lineChars[targetCol] = ch
                }
            }

            editor.setLine(at: currentLineIndex, text: String(lineChars))
        }

        editor.lineIndex = startLine + calcHeight - 1
        editor.columnIndex = startCol + calcWidth
    }

    private func wrapTextLine(_ text: String, maxWidth: Int) -> [String] {
        guard text.count > maxWidth && maxWidth > 0 else { return [text] }
        var result: [String] = []
        let words = text.components(separatedBy: " ")
        var currentLine = ""

        for word in words {
            if currentLine.isEmpty {
                currentLine = word
            } else if currentLine.count + 1 + word.count <= maxWidth {
                currentLine += " " + word
            } else {
                result.append(currentLine)
                currentLine = word
            }
        }
        if !currentLine.isEmpty {
            result.append(currentLine)
        }
        return result
    }
}
