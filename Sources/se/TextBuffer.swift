import Foundation

/// 文字資料與游標狀態管理
public final class TextBuffer {
    public var lines: [String] = [""]
    public var filePath: String?
    public var isModified: Bool = false

    /// 游標真實位置 (以字元 Character/Grapheme Cluster 為單位)
    /// lineIndex: 0-indexed 行號
    /// columnIndex: 0-indexed 欄號
    public var lineIndex: Int = 0
    public var columnIndex: Int = 0

    public init(filePath: String? = nil) {
        self.filePath = filePath
        if let path = filePath {
            loadFile(at: path)
        }
    }

    /// 從檔案載入文字
    public func loadFile(at path: String) {
        let expandedPath = NSString(string: path).expandingTildeInPath
        if let content = try? String(contentsOfFile: expandedPath, encoding: .utf8) {
            let fileLines = content.components(separatedBy: .newlines)
            self.lines = fileLines.isEmpty ? [""] : fileLines
            self.filePath = expandedPath
            self.isModified = false
            self.lineIndex = 0
            self.columnIndex = 0
        } else {
            // 如果檔案不存在，則創立空文件，留給使用者儲存
            self.lines = [""]
            self.filePath = expandedPath
            self.isModified = false
        }
    }

    /// 儲存檔案
    public func saveFile(to path: String? = nil) throws {
        let targetPath = path ?? filePath
        guard let savePath = targetPath, !savePath.isEmpty else {
            throw NSError(domain: "TextBuffer", code: 1, userInfo: [NSLocalizedDescriptionKey: "No file path specified"])
        }

        let expandedPath = NSString(string: savePath).expandingTildeInPath
        let content = lines.joined(separator: "\n")
        try content.write(toFile: expandedPath, atomically: true, encoding: .utf8)

        self.filePath = expandedPath
        self.isModified = false
    }

    /// 插入字元
    public func insert(character ch: Character) {
        ensureBounds()
        var currentLine = lines[lineIndex]
        let index = currentLine.index(currentLine.startIndex, offsetBy: columnIndex, limitedBy: currentLine.endIndex) ?? currentLine.endIndex
        currentLine.insert(ch, at: index)
        lines[lineIndex] = currentLine
        columnIndex += 1
        isModified = true
    }

    /// 按 Enter 換行
    public func insertNewline() {
        ensureBounds()
        let currentLine = lines[lineIndex]
        let index = currentLine.index(currentLine.startIndex, offsetBy: columnIndex, limitedBy: currentLine.endIndex) ?? currentLine.endIndex

        let leftPart = String(currentLine[..<index])
        let rightPart = String(currentLine[index...])

        lines[lineIndex] = leftPart
        lines.insert(rightPart, at: lineIndex + 1)

        lineIndex += 1
        columnIndex = 0
        isModified = true
    }

    /// Backspace 刪除字元
    public func backspace() {
        ensureBounds()
        if columnIndex > 0 {
            var currentLine = lines[lineIndex]
            let prevIndex = currentLine.index(currentLine.startIndex, offsetBy: columnIndex - 1)
            currentLine.remove(at: prevIndex)
            lines[lineIndex] = currentLine
            columnIndex -= 1
            isModified = true
        } else if lineIndex > 0 {
            // 合併至上一行末尾
            let currentLine = lines.remove(at: lineIndex)
            lineIndex -= 1
            let prevLineLength = lines[lineIndex].count
            lines[lineIndex].append(currentLine)
            columnIndex = prevLineLength
            isModified = true
        }
    }

    /// Delete 鍵刪除右側字元
    public func delete() {
        ensureBounds()
        let currentLine = lines[lineIndex]
        if columnIndex < currentLine.count {
            var lineCopy = currentLine
            let targetIndex = lineCopy.index(lineCopy.startIndex, offsetBy: columnIndex)
            lineCopy.remove(at: targetIndex)
            lines[lineIndex] = lineCopy
            isModified = true
        } else if lineIndex < lines.count - 1 {
            // 合併下一行
            let nextLine = lines.remove(at: lineIndex + 1)
            lines[lineIndex].append(nextLine)
            isModified = true
        }
    }

    /// 確保游標在合法範圍內
    public func clampCursor() {
        if lines.isEmpty {
            lines = [""]
        }
        lineIndex = max(0, min(lineIndex, lines.count - 1))
        let currentLineCount = lines[lineIndex].count
        columnIndex = max(0, min(columnIndex, currentLineCount))
    }

    /// 執行 ^J (Justify Paragraph) 對齊重排段落文字
    public func justifyParagraph(targetWidth: Int = 72) {
        guard !lines.isEmpty else { return }
        clampCursor()

        let currentLine = lines[lineIndex]
        if currentLine.trimmingCharacters(in: .whitespaces).isEmpty {
            return
        }

        // 1. 尋找當前段落的起點 line 與終點 line (以空行分界)
        var startLine = lineIndex
        while startLine > 0 && !lines[startLine - 1].trimmingCharacters(in: .whitespaces).isEmpty {
            startLine -= 1
        }

        var endLine = lineIndex
        while endLine < lines.count - 1 && !lines[endLine + 1].trimmingCharacters(in: .whitespaces).isEmpty {
            endLine += 1
        }

        // 2. 提取段落所有文字並以單一空格組合
        let paragraphText = lines[startLine...endLine]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: " ")

        // 3. 依據 targetWidth 進行段落重新分行
        let words = paragraphText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !words.isEmpty else { return }

        var newParagraphLines: [String] = []
        var currentFormattedLine = ""

        for word in words {
            if currentFormattedLine.isEmpty {
                currentFormattedLine = word
            } else {
                let candidate = currentFormattedLine + " " + word
                if candidate.displayWidth <= targetWidth {
                    currentFormattedLine = candidate
                } else {
                    newParagraphLines.append(currentFormattedLine)
                    currentFormattedLine = word
                }
            }
        }
        if !currentFormattedLine.isEmpty {
            newParagraphLines.append(currentFormattedLine)
        }

        // 4. 替換舊段落列
        lines.replaceSubrange(startLine...endLine, with: newParagraphLines)
        lineIndex = min(startLine, lines.count - 1)
        columnIndex = 0
        isModified = true
    }

    private func ensureBounds() {
        clampCursor()
    }
}
