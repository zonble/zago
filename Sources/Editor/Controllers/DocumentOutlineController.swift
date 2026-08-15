import Foundation
import Syntax

/// Controller for heading navigation and document outline view modal.
final class DocumentOutlineController: KeyInputHandler {
    weak var editor: Editor?
    private(set) var isOutlineActive: Bool = false

    enum HeadingNavigationDirection {
        case next
        case previous
    }

    init(editor: Editor? = nil) {
        self.editor = editor
    }

    /// KeyInputHandler protocol implementation.
    func handleKey(_ key: Key) -> Bool {
        if isOutlineActive {
            if key == .esc || key == .ctrl("C") || key == .ctrl("G") {
                return true
            }
        }
        switch key {
        case .alt("]"):
            goToNextHeading()
            return true
        case .alt("["):
            goToPreviousHeading()
            return true
        case .alt("\\"):
            showDocumentOutline()
            return true
        default:
            return false
        }
    }

    func goToNextHeading() {
        goToHeading(direction: .next)
    }

    func goToPreviousHeading() {
        goToHeading(direction: .previous)
    }

    func showDocumentOutline() {
        guard let editor else { return }
        guard reportHeadingNavigationAvailability(editor).isSucceeded else { return }
        let outline = currentDocumentOutline()
        guard !outline.headings.isEmpty else {
            editor.reportOperationResult(.noOp(message: editor.l10n["status.no_headings"]))
            return
        }

        isOutlineActive = true
        defer { isOutlineActive = false }

        let selectedIndex = initialOutlineSelectionIndex(in: outline)
        let headingResult = DocumentOutlineView(
            terminal: editor.terminal,
            title: editor.l10n["outlineview.title"],
            headings: outline.headings,
            footer: editor.l10n["outlineview.footer"],
            initialSelectedIndex: selectedIndex
        ).show()

        if let heading = headingResult {
            editor.renderer.invalidateScreenCache()
            editor.refreshScreen()
            jumpToHeading(heading, in: outline)
        } else {
            editor.reportOperationResult(.cancelled(message: editor.l10n["status.outline_cancelled"]))
            editor.renderer.invalidateScreenCache()
            editor.refreshScreen()
        }
    }

    func supportsDocumentOutlineForCurrentBuffer() -> Bool {
        guard let editor, !editor.buffer.isDirectoryBuffer else { return false }
        return editor.syntaxHighlighter.detectLanguage(for: editor.buffer.filePath)?.supportsDocumentOutline == true
    }

    private func goToHeading(direction: HeadingNavigationDirection) {
        guard let editor else { return }
        guard reportHeadingNavigationAvailability(editor).isSucceeded else { return }
        let outline = currentDocumentOutline()
        guard !outline.headings.isEmpty else {
            editor.reportOperationResult(.noOp(message: editor.l10n["status.no_headings"]))
            return
        }

        let target: DocumentHeading
        switch direction {
        case .next:
            target = outline.headings.first { $0.lineIndex > editor.buffer.lineIndex } ?? outline.headings[0]
        case .previous:
            target =
                outline.headings.last { $0.lineIndex < editor.buffer.lineIndex }
                ?? outline.headings[outline.headings.count - 1]
        }
        jumpToHeading(target, in: outline)
    }

    private func currentDocumentOutline() -> DocumentOutline {
        guard let editor else { return DocumentOutline(headings: []) }
        let language = editor.syntaxHighlighter.detectLanguage(for: editor.buffer.filePath)
        return DocumentOutlineParser.parse(lines: editor.buffer.lines, customParser: language?.outlineParser)
    }

    private func reportHeadingNavigationAvailability(_ editor: Editor) -> EditorOperationResult {
        let result = headingNavigationAvailability(for: editor)
        editor.applyOperationResult(result)
        return result
    }

    private func headingNavigationAvailability(for editor: Editor) -> EditorOperationResult {
        if editor.buffer.isDirectoryBuffer {
            return .noOp(message: editor.l10n["status.heading_nav_disabled_directory"])
        }
        if editor.isCanvasModeActive {
            return .noOp(message: editor.l10n["status.heading_nav_disabled_canvas"])
        }
        if editor.isTableModeActive {
            return .noOp(message: editor.l10n["status.heading_nav_disabled_table"])
        }
        if !supportsDocumentOutlineForCurrentBuffer() {
            return .noOp(message: editor.l10n["status.heading_nav_unsupported_format"])
        }
        return .succeeded
    }

    private func jumpToHeading(_ heading: DocumentHeading, in outline: DocumentOutline) {
        guard let editor else { return }
        editor.clearActiveMark()
        editor.buffer.lineIndex = max(0, min(heading.lineIndex, editor.buffer.lines.count - 1))
        editor.buffer.columnIndex = 0
        editor.topVLineIndex = max(0, editor.buffer.lineIndex - 1)
        let index = (outline.headings.firstIndex(of: heading) ?? 0) + 1
        let markerTitle = "\(heading.marker) \(heading.title)"
        editor.reportOperationResult(
            .succeeded(
                message: String(
                    format: editor.l10n["status.heading_position"], index, outline.headings.count, markerTitle)))
    }

    private func initialOutlineSelectionIndex(in outline: DocumentOutline) -> Int {
        guard let editor else { return 0 }
        if let index = outline.headings.lastIndex(where: { $0.lineIndex <= editor.buffer.lineIndex }) {
            return index
        }
        return 0
    }
}
