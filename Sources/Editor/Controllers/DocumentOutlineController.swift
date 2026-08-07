import Foundation
import Syntax

/// Controller for heading navigation and document outline view modal.
public final class DocumentOutlineController: KeyInputHandler {
    public weak var editor: Editor?

    public enum HeadingNavigationDirection {
        case next
        case previous
    }

    public init(editor: Editor? = nil) {
        self.editor = editor
    }

    /// KeyInputHandler protocol implementation.
    public func handleKey(_ key: Key) -> Bool {
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

    public func goToNextHeading() {
        goToHeading(direction: .next)
    }

    public func goToPreviousHeading() {
        goToHeading(direction: .previous)
    }

    public func showDocumentOutline() {
        guard let editor else { return }
        guard canNavigateHeadings() else { return }
        let outline = currentDocumentOutline()
        guard !outline.headings.isEmpty else {
            editor.setStatusMessage(editor.l10n["status.no_headings"])
            return
        }

        let selectedIndex = initialOutlineSelectionIndex(in: outline)
        guard
            let heading = DocumentOutlineView(
                terminal: editor.terminal,
                title: editor.l10n["outlineview.title"],
                headings: outline.headings,
                footer: editor.l10n["outlineview.footer"],
                initialSelectedIndex: selectedIndex
            ).show()
        else {
            editor.setStatusMessage(editor.l10n["status.outline_cancelled"])
            return
        }

        jumpToHeading(heading, in: outline)
    }

    public func supportsDocumentOutlineForCurrentBuffer() -> Bool {
        guard let editor, !editor.buffer.isDirectoryBuffer else { return false }
        return editor.syntaxHighlighter.detectLanguage(for: editor.buffer.filePath)?.supportsDocumentOutline == true
    }

    private func goToHeading(direction: HeadingNavigationDirection) {
        guard let editor else { return }
        guard canNavigateHeadings() else { return }
        let outline = currentDocumentOutline()
        guard !outline.headings.isEmpty else {
            editor.setStatusMessage(editor.l10n["status.no_headings"])
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

    private func canNavigateHeadings() -> Bool {
        guard let editor else { return false }
        if editor.buffer.isDirectoryBuffer {
            editor.setStatusMessage(editor.l10n["status.heading_nav_disabled_directory"])
            return false
        }
        if editor.isCanvasModeActive {
            editor.setStatusMessage(editor.l10n["status.heading_nav_disabled_canvas"])
            return false
        }
        if editor.isTableModeActive {
            editor.setStatusMessage(editor.l10n["status.heading_nav_disabled_table"])
            return false
        }
        if !supportsDocumentOutlineForCurrentBuffer() {
            editor.setStatusMessage(editor.l10n["status.heading_nav_unsupported_format"])
            return false
        }
        return true
    }

    private func jumpToHeading(_ heading: DocumentHeading, in outline: DocumentOutline) {
        guard let editor else { return }
        editor.clearActiveMark()
        editor.buffer.lineIndex = max(0, min(heading.lineIndex, editor.buffer.lines.count - 1))
        editor.buffer.columnIndex = 0
        editor.topVLineIndex = max(0, editor.buffer.lineIndex - 1)
        let index = (outline.headings.firstIndex(of: heading) ?? 0) + 1
        let markerTitle = "\(heading.marker) \(heading.title)"
        editor.setStatusMessage(
            String(format: editor.l10n["status.heading_position"], index, outline.headings.count, markerTitle))
    }

    private func initialOutlineSelectionIndex(in outline: DocumentOutline) -> Int {
        guard let editor else { return 0 }
        if let index = outline.headings.lastIndex(where: { $0.lineIndex <= editor.buffer.lineIndex }) {
            return index
        }
        return 0
    }
}
