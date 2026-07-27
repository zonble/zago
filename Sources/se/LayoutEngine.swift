import Foundation

/// 虛擬顯示行資料結構
public struct VirtualLine {
    public let bufferLineIndex: Int
    public let subLineIndex: Int
    public let text: String
    public let startCol: Int
    public let endCol: Int
}

/// 負責處理 Softwrap (軟折行) 計算與真實/虛擬座標轉換
public final class LayoutEngine {
    public var wrapColumn: Int? // nil 表示依 Terminal 視窗寬度自適應
    
    public init(wrapColumn: Int? = nil) {
        self.wrapColumn = wrapColumn
    }

    /// 根據傳入的可用寬度 (availableWidth)，計算所有虛擬顯示行
    public func computeVirtualLines(from lines: [String], viewWidth: Int) -> [VirtualLine] {
        let effectiveWrap = max(2, min(wrapColumn ?? viewWidth, viewWidth))
        var virtualLines: [VirtualLine] = []

        for (bIndex, line) in lines.enumerated() {
            if line.isEmpty {
                virtualLines.append(VirtualLine(
                    bufferLineIndex: bIndex,
                    subLineIndex: 0,
                    text: "",
                    startCol: 0,
                    endCol: 0
                ))
                continue
            }

            var currentCharIndex = 0
            var subIndex = 0
            let chars = Array(line)
            let totalChars = chars.count

            while currentCharIndex < totalChars {
                var currentWidth = 0
                var endIndex = currentCharIndex

                while endIndex < totalChars {
                    let w = chars[endIndex].displayWidth
                    if currentWidth + w > effectiveWrap && endIndex > currentCharIndex {
                        break
                    }
                    currentWidth += w
                    endIndex += 1
                }

                let chunkText = String(chars[currentCharIndex..<endIndex])
                
                virtualLines.append(VirtualLine(
                    bufferLineIndex: bIndex,
                    subLineIndex: subIndex,
                    text: chunkText,
                    startCol: currentCharIndex,
                    endCol: endIndex
                ))

                currentCharIndex = endIndex
                subIndex += 1
            }
        }

        return virtualLines
    }

    /// 將 Buffer Real Cursor (lineIndex, columnIndex) 轉為 Virtual Line Index 與 Virtual Column
    public func getVirtualCursor(
        lineIndex: Int,
        columnIndex: Int,
        virtualLines: [VirtualLine]
    ) -> (vLineIndex: Int, vColIndex: Int) {
        // 尋找對應 bufferLineIndex 的所有虛擬行
        let matching = virtualLines.enumerated().filter { $0.element.bufferLineIndex == lineIndex }
        
        if matching.isEmpty {
            return (0, 0)
        }

        for (vIdx, vLine) in matching {
            if columnIndex >= vLine.startCol && columnIndex <= vLine.endCol {
                // 如果恰好在行末折行點，且非最後一區塊，歸類在該區塊內
                if columnIndex == vLine.endCol && vLine.endCol < vLine.startCol + vLine.text.count && vIdx < virtualLines.count - 1 {
                    let nextVLine = virtualLines[vIdx + 1]
                    if nextVLine.bufferLineIndex == lineIndex {
                        continue
                    }
                }
                let colInVLine = columnIndex - vLine.startCol
                return (vIdx, colInVLine)
            }
        }

        // 預設為該 buffer line 的最後一個虛擬行
        if let lastMatch = matching.last {
            return (lastMatch.offset, lastMatch.element.text.count)
        }

        return (0, 0)
    }

    /// 根據畫面虛擬行座標 (vLineIndex, vColIndex) 換回 Buffer Real Cursor (lineIndex, columnIndex)
    public func getBufferCursor(
        vLineIndex: Int,
        vColIndex: Int,
        virtualLines: [VirtualLine]
    ) -> (lineIndex: Int, columnIndex: Int) {
        guard !virtualLines.isEmpty else { return (0, 0) }
        let clampedVLineIndex = max(0, min(vLineIndex, virtualLines.count - 1))
        let vLine = virtualLines[clampedVLineIndex]

        let clampedVCol = max(0, min(vColIndex, vLine.text.count))
        let realCol = vLine.startCol + clampedVCol

        return (vLine.bufferLineIndex, realCol)
    }
}
