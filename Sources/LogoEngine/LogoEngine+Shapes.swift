import Foundation

extension LogoEngine {

    internal func executeLineCommand(_ tokens: [String], index: inout Int) {
        guard let editor = self.delegate else { return }
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

        let startCol = (editor.logoEngine(self, queryState: .currentColumnIndex) as? Int) ?? 0
        let startLine = (editor.logoEngine(self, queryState: .currentLineIndex) as? Int) ?? 0

        editor.logoEngine(self, performAction: .ensureLineExists(index:startLine))

        let startLineStr = (editor.logoEngine(self, queryState: .lineAt(startLine)) as? String) ?? ""
        var currentChars = Array(startLineStr)
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

        editor.logoEngine(self, performAction: .setLine(index: startLine, text: String(currentChars)))
        editor.logoEngine(self, performAction: .updateColumnIndex(startCol + length))
    }

    internal func executeVlineCommand(_ tokens: [String], index: inout Int) {
        guard let editor = self.delegate else { return }
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

        let startCol = (editor.logoEngine(self, queryState: .currentColumnIndex) as? Int) ?? 0
        let startLine = (editor.logoEngine(self, queryState: .currentLineIndex) as? Int) ?? 0

        for r in 0..<height {
            let line = startLine + r
            editor.logoEngine(self, performAction: .ensureLineExists(index:line))

            let lineStr = (editor.logoEngine(self, queryState: .lineAt(line)) as? String) ?? ""
            var currentChars = Array(lineStr)
            while currentChars.count <= startCol {
                currentChars.append(" ")
            }

            let moveMask = (r == 0) ? 4 : ((r == height - 1) ? 1 : 5)
            let existing = currentChars[startCol]
            currentChars[startCol] = fuseChar(existing: existing, defaultNewChar: styleChar, moveMask: moveMask)

            editor.logoEngine(self, performAction: .setLine(index: line, text: String(currentChars)))
        }

        editor.logoEngine(self, performAction: .updateLineIndex(startLine + height))
        editor.logoEngine(self, performAction: .updateColumnIndex(startCol))
    }

    internal func executeNewlineCommand(_ tokens: [String], index: inout Int) {
        guard let editor = self.delegate else { return }
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
            editor.logoEngine(self, performAction: .insertNewline)
        }
    }

    internal func executeBoxCommand(_ tokens: [String], index: inout Int) {
        let boxSubKeywords: Set<String> = ["ASCII", "SINGLE", "DOUBLE", "ROUND", "LEFT", "CENTER", "CENTRE", "RIGHT"]

        guard index < tokens.count else {
            drawBoxFrame(width: 20, height: 5, style: .single)
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
                drawBoxAroundText(text, targetWidth: width, targetHeight: height, align: align, style: BoxStyle.from(styleName))
            } else {
                drawBoxFrame(width: width, height: height ?? 5, style: BoxStyle.from(styleName))
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

        drawBoxAroundText(textContent, targetWidth: nil, targetHeight: nil, align: align, style: BoxStyle.from(styleName))
    }

    private func drawBoxFrame(width: Int, height: Int, style: BoxStyle) {
        guard let editor = self.delegate else { return }
        let startCol = (editor.logoEngine(self, queryState: .currentColumnIndex) as? Int) ?? 0
        let startLine = (editor.logoEngine(self, queryState: .currentLineIndex) as? Int) ?? 0

        for r in 0..<height {
            let currentLineIndex = startLine + r
            editor.logoEngine(self, performAction: .ensureLineExists(index:currentLineIndex))

            let lineStr = (editor.logoEngine(self, queryState: .lineAt(currentLineIndex)) as? String) ?? ""
            var lineChars = Array(lineStr)
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

            editor.logoEngine(self, performAction: .setLine(index: currentLineIndex, text: String(lineChars)))
        }

        editor.logoEngine(self, performAction: .updateLineIndex(startLine + height - 1))
        editor.logoEngine(self, performAction: .updateColumnIndex(startCol + width))
    }

    private func drawBoxAroundText(_ text: String, targetWidth: Int?, targetHeight: Int?, align: String, style: BoxStyle) {
        guard let editor = self.delegate else { return }
        let rawLines = text.replacingOccurrences(of: "\\n", with: "\n").components(separatedBy: "\n")
        let maxVisualWidth = rawLines.map { $0.displayWidth }.max() ?? 0
        let calcWidth = targetWidth ?? (maxVisualWidth + 4)
        let innerWidth = max(1, calcWidth - 2)

        var textLines: [String] = []
        for rLine in rawLines {
            textLines.append(contentsOf: wrapTextLine(rLine, maxWidth: innerWidth))
        }

        let calcHeight = max(targetHeight ?? 0, textLines.count + 2)

        let startCol = (editor.logoEngine(self, queryState: .currentColumnIndex) as? Int) ?? 0
        let startLine = (editor.logoEngine(self, queryState: .currentLineIndex) as? Int) ?? 0

        for r in 0..<calcHeight {
            let currentLineIndex = startLine + r
            editor.logoEngine(self, performAction: .ensureLineExists(index:currentLineIndex))

            let isTop = (r == 0)
            let isBottom = (r == calcHeight - 1)

            let rowStr: String
            if isTop {
                rowStr = String(style.topLeft) + String(repeating: style.topChar, count: innerWidth) + String(style.topRight)
            } else if isBottom {
                rowStr = String(style.bottomLeft) + String(repeating: style.bottomChar, count: innerWidth) + String(style.bottomRight)
            } else {
                let lineStr = (r >= 1 && (r - 1) < textLines.count) ? textLines[r - 1] : ""
                let textWidth = lineStr.displayWidth
                let textOffset: Int
                if align == "center" || align == "centre" {
                    textOffset = max(0, (innerWidth - textWidth) / 2)
                } else if align == "right" {
                    textOffset = max(0, innerWidth - textWidth)
                } else {
                    textOffset = (innerWidth > textWidth) ? 1 : 0
                }

                let leftSpaces = String(repeating: " ", count: textOffset)
                let rightSpacesCount = max(0, innerWidth - textOffset - textWidth)
                let rightSpaces = String(repeating: " ", count: rightSpacesCount)
                rowStr = String(style.sideChar) + leftSpaces + lineStr + rightSpaces + String(style.sideChar)
            }

            let existingLine = (editor.logoEngine(self, queryState: .lineAt(currentLineIndex)) as? String) ?? ""
            let newLineText: String
            if existingLine.trimmingCharacters(in: .whitespaces).isEmpty {
                let leadingSpaces = String(repeating: " ", count: startCol)
                newLineText = leadingSpaces + rowStr
            } else {
                newLineText = buildFusedRowText(existingLine: existingLine, startCol: startCol, calcWidth: calcWidth, rowStr: rowStr, isTop: isTop, isBottom: isBottom, style: style)
            }

            editor.logoEngine(self, performAction: .setLine(index: currentLineIndex, text: newLineText))
        }

        editor.logoEngine(self, performAction: .updateLineIndex(startLine + calcHeight - 1))
        editor.logoEngine(self, performAction: .updateColumnIndex(startCol + calcWidth))
    }

    private func buildFusedRowText(existingLine: String, startCol: Int, calcWidth: Int, rowStr: String, isTop: Bool, isBottom: Bool, style: BoxStyle) -> String {
        var prefix = ""
        var suffix = ""
        var existingBoxRegion: [Character] = []
        
        var currentW = 0
        for ch in existingLine {
            let w = ch.displayWidth
            if currentW + w <= startCol {
                prefix.append(ch)
            } else if currentW < startCol + calcWidth {
                existingBoxRegion.append(ch)
            } else {
                suffix.append(ch)
            }
            currentW += w
        }
        
        if prefix.displayWidth < startCol {
            prefix += String(repeating: " ", count: startCol - prefix.displayWidth)
        }

        var resultRow = ""
        var currentVisualCol = 0
        
        for ch in rowStr {
            let w = ch.displayWidth
            let isLeft = (currentVisualCol == 0)
            let isRight = (currentVisualCol + w == calcWidth)

            var moveMask = 0
            if isTop && isLeft { moveMask = 6 }
            else if isTop && isRight { moveMask = 12 }
            else if isBottom && isLeft { moveMask = 3 }
            else if isBottom && isRight { moveMask = 9 }
            else if isTop { moveMask = 10 }
            else if isBottom { moveMask = 10 }
            else if isLeft || isRight { moveMask = 5 }

            if moveMask != 0 && !existingBoxRegion.isEmpty {
                var regionW = 0
                var matchChar: Character? = nil
                for eCh in existingBoxRegion {
                    let eW = eCh.displayWidth
                    if regionW == currentVisualCol {
                        matchChar = eCh
                        break
                    }
                    regionW += eW
                }
                if let existingCh = matchChar {
                    let fused = fuseChar(existing: existingCh, defaultNewChar: ch, moveMask: moveMask)
                    resultRow.append(fused)
                } else {
                    resultRow.append(ch)
                }
            } else {
                resultRow.append(ch)
            }

            currentVisualCol += w
        }

        return prefix + resultRow + suffix
    }

    private func wrapTextLine(_ text: String, maxWidth: Int) -> [String] {
        guard text.displayWidth > maxWidth && maxWidth > 0 else { return [text] }
        var result: [String] = []
        let words = text.components(separatedBy: " ")
        var currentLine = ""

        for word in words {
            let wordWidth = word.displayWidth
            if wordWidth > maxWidth {
                if !currentLine.isEmpty {
                    result.append(currentLine)
                    currentLine = ""
                }
                var temp = ""
                for ch in word {
                    let chW = ch.displayWidth
                    if temp.displayWidth + chW > maxWidth && !temp.isEmpty {
                        result.append(temp)
                        temp = String(ch)
                    } else {
                        temp.append(ch)
                    }
                }
                if !temp.isEmpty {
                    currentLine = temp
                }
            } else if currentLine.isEmpty {
                currentLine = word
            } else if currentLine.displayWidth + 1 + wordWidth <= maxWidth {
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

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

extension Character {
    internal var displayWidth: Int {
        for scalar in self.unicodeScalars {
            #if canImport(Darwin)
            let w = wcwidth(wchar_t(scalar.value))
            #elseif canImport(Glibc)
            let w = wcwidth(Int32(scalar.value))
            #elseif canImport(Musl)
            let w = sys_wcwidth(Int32(scalar.value))
            #else
            let w = 1
            #endif
            if w > 0 { return Int(w) }
        }
        return 1
    }
}

extension String {
    internal var displayWidth: Int {
        return self.reduce(0) { $0 + $1.displayWidth }
    }
}
