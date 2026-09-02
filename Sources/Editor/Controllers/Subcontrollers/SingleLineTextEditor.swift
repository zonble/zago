import Config
import Foundation
import TextMetrics
import TextTransform

/// Reusable single-line text editor state and key handler supporting editing, selection,
/// clipboard integration, and keymap-driven commands without hardcoded keys.
struct SingleLineTextEditor: Equatable, Sendable {
    var text: String
    var cursorIndex: Int
    var selectionAnchorIndex: Int?

    init(text: String = "", cursorIndex: Int = 0, selectionAnchorIndex: Int? = nil) {
        self.text = text
        self.cursorIndex = max(0, min(cursorIndex, text.count))
        self.selectionAnchorIndex = selectionAnchorIndex
    }

    public mutating func reset(text: String = "") {
        self.text = text
        self.cursorIndex = text.count
        self.selectionAnchorIndex = nil
    }

    public var selectionRange: Range<Int>? {
        guard let anchor = selectionAnchorIndex else { return nil }
        let start = max(0, min(anchor, cursorIndex, text.count))
        let end = min(text.count, max(anchor, cursorIndex, 0))
        guard start < end else { return nil }
        return start..<end
    }

    public var selectedText: String? {
        guard let range = selectionRange else { return nil }
        let chars = Array(text)
        return String(chars[range])
    }

    // MARK: - Mutations

    @discardableResult
    public mutating func deleteSelectionIfNeeded() -> Bool {
        guard let range = selectionRange else {
            selectionAnchorIndex = nil
            return false
        }
        var chars = Array(text)
        chars.removeSubrange(range)
        text = String(chars)
        cursorIndex = range.lowerBound
        selectionAnchorIndex = nil
        return true
    }

    public mutating func insertChar(_ ch: Character) {
        _ = deleteSelectionIfNeeded()
        let clamped = max(0, min(cursorIndex, text.count))
        let idx = text.index(text.startIndex, offsetBy: clamped)
        text.insert(ch, at: idx)
        cursorIndex = clamped + 1
        selectionAnchorIndex = nil
    }

    public mutating func insertString(_ str: String) {
        _ = deleteSelectionIfNeeded()
        let clamped = max(0, min(cursorIndex, text.count))
        let idx = text.index(text.startIndex, offsetBy: clamped)
        text.insert(contentsOf: str, at: idx)
        cursorIndex = clamped + str.count
        selectionAnchorIndex = nil
    }

    public mutating func deleteBackspace() {
        if deleteSelectionIfNeeded() { return }
        if cursorIndex > 0 && !text.isEmpty {
            let clamped = max(1, min(cursorIndex, text.count))
            let idx = text.index(text.startIndex, offsetBy: clamped - 1)
            text.remove(at: idx)
            cursorIndex = clamped - 1
        }
    }

    public mutating func deleteForward() {
        if deleteSelectionIfNeeded() { return }
        if cursorIndex < text.count && !text.isEmpty {
            let clamped = max(0, min(cursorIndex, text.count - 1))
            let idx = text.index(text.startIndex, offsetBy: clamped)
            text.remove(at: idx)
        }
    }

    public mutating func clearLine() {
        text = ""
        cursorIndex = 0
        selectionAnchorIndex = nil
    }

    public mutating func moveHome() {
        cursorIndex = 0
        selectionAnchorIndex = nil
    }

    public mutating func moveEnd() {
        cursorIndex = text.count
        selectionAnchorIndex = nil
    }

    public mutating func moveLeft() {
        cursorIndex = max(0, cursorIndex - 1)
        selectionAnchorIndex = nil
    }

    public mutating func moveRight() {
        cursorIndex = min(text.count, cursorIndex + 1)
        selectionAnchorIndex = nil
    }

    public mutating func moveWordBackward() {
        cursorIndex = TextAnalyzer.previousWordIndex(in: text, from: cursorIndex)
        selectionAnchorIndex = nil
    }

    public mutating func moveWordForward() {
        cursorIndex = TextAnalyzer.nextWordIndex(in: text, from: cursorIndex)
        selectionAnchorIndex = nil
    }

    public mutating func selectLeft() {
        extendSelection(to: max(0, cursorIndex - 1))
    }

    public mutating func selectRight() {
        extendSelection(to: min(text.count, cursorIndex + 1))
    }

    public mutating func selectHome() {
        extendSelection(to: 0)
    }

    public mutating func selectEnd() {
        extendSelection(to: text.count)
    }

    public mutating func selectAll() {
        guard !text.isEmpty else { return }
        selectionAnchorIndex = 0
        cursorIndex = text.count
    }

    public mutating func extendSelection(to newCursorIndex: Int) {
        let clamped = max(0, min(newCursorIndex, text.count))
        if selectionAnchorIndex == nil {
            selectionAnchorIndex = cursorIndex
        }
        cursorIndex = clamped
        if selectionRange == nil {
            selectionAnchorIndex = nil
        }
    }

    public mutating func cut(to clipboard: inout String?) {
        if let sel = selectedText, !sel.isEmpty {
            clipboard = sel
            _ = deleteSelectionIfNeeded()
            return
        }
        guard !text.isEmpty else { return }
        let clamped = max(0, min(cursorIndex, text.count))
        let chars = Array(text)
        if clamped == 0 || clamped >= chars.count {
            clipboard = text
            clearLine()
        } else {
            clipboard = String(chars[clamped...])
            text = String(chars[..<clamped])
            cursorIndex = clamped
        }
        selectionAnchorIndex = nil
    }

    public mutating func copy(to clipboard: inout String?) {
        guard let sel = selectedText, !sel.isEmpty else { return }
        clipboard = sel
    }

    public mutating func paste(from clipboard: String?) {
        guard let clipboard, !clipboard.isEmpty else { return }
        insertString(clipboard)
    }

    // MARK: - Keymap Dispatcher

    public enum EventResult: Equatable, Sendable {
        case handled
        case confirmed(String)
        case cancelled
        case tabCompleted
        case historyPrev
        case historyNext
        case unhandled
    }

    public mutating func handleKey(
        _ key: Key,
        keymapManager: KeymapManager,
        clipboard: inout String?
    ) -> EventResult {
        let cmd = keymapManager.resolve(key: key, in: .prompt)

        switch cmd {
        case .promptConfirm:
            return .confirmed(text)
        case .promptCancel:
            return .cancelled
        case .promptComplete:
            return .tabCompleted
        case .promptHistoryPrev:
            return .historyPrev
        case .promptHistoryNext:
            return .historyNext
        case .moveHome:
            moveHome()
            return .handled
        case .moveEnd:
            moveEnd()
            return .handled
        case .moveLeft:
            moveLeft()
            return .handled
        case .moveRight:
            moveRight()
            return .handled
        case .moveWordBackward:
            moveWordBackward()
            return .handled
        case .moveWordForward:
            moveWordForward()
            return .handled
        case .selectLeft:
            selectLeft()
            return .handled
        case .selectRight:
            selectRight()
            return .handled
        case .selectHome:
            selectHome()
            return .handled
        case .selectEnd:
            selectEnd()
            return .handled
        case .selectAll:
            selectAll()
            return .handled
        case .editCut:
            cut(to: &clipboard)
            return .handled
        case .editCopy:
            copy(to: &clipboard)
            return .handled
        case .editUncut:
            paste(from: clipboard)
            return .handled
        case .promptClearLine:
            clearLine()
            return .handled
        case .editDelete:
            deleteForward()
            return .handled
        default:
            break
        }

        switch key {
        case .backspace:
            deleteBackspace()
            return .handled
        case .char(let ch):
            insertChar(ch)
            return .handled
        default:
            return .unhandled
        }
    }
}
