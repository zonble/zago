import Foundation
import Syntax

extension Editor {
    enum HeadingNavigationDirection {
        case next
        case previous
    }

    func goToNextHeading() {
        goToHeading(direction: .next)
    }

    func goToPreviousHeading() {
        goToHeading(direction: .previous)
    }

    func showDocumentOutline() {
        guard canNavigateHeadings() else { return }
        let outline = currentDocumentOutline()
        guard !outline.headings.isEmpty else {
            setStatusMessage(L10n["status.no_headings"])
            return
        }

        let selectedIndex = initialOutlineSelectionIndex(in: outline)
        guard
            let heading = DocumentOutlineView(
                terminal: terminal,
                title: L10n["outlineview.title"],
                headings: outline.headings,
                footer: L10n["outlineview.footer"],
                initialSelectedIndex: selectedIndex
            ).show()
        else {
            setStatusMessage(L10n["status.outline_cancelled"])
            return
        }

        jumpToHeading(heading, in: outline)
    }

    func supportsDocumentOutlineForCurrentBuffer() -> Bool {
        guard !buffer.isDirectoryBuffer else { return false }
        return syntaxHighlighter.detectLanguage(for: buffer.filePath)?.supportsDocumentOutline == true
    }

    private func goToHeading(direction: HeadingNavigationDirection) {
        guard canNavigateHeadings() else { return }
        let outline = currentDocumentOutline()
        guard !outline.headings.isEmpty else {
            setStatusMessage(L10n["status.no_headings"])
            return
        }

        let target: DocumentHeading
        switch direction {
        case .next:
            target = outline.headings.first { $0.lineIndex > buffer.lineIndex } ?? outline.headings[0]
        case .previous:
            target =
                outline.headings.last { $0.lineIndex < buffer.lineIndex }
                ?? outline.headings[outline.headings.count - 1]
        }
        jumpToHeading(target, in: outline)
    }

    private func currentDocumentOutline() -> DocumentOutline {
        let language = syntaxHighlighter.detectLanguage(for: buffer.filePath)
        return DocumentOutlineParser.parse(lines: buffer.lines, language: language)
    }

    private func canNavigateHeadings() -> Bool {
        if buffer.isDirectoryBuffer {
            setStatusMessage(L10n["status.heading_nav_disabled_directory"])
            return false
        }
        if isCanvasModeActive {
            setStatusMessage(L10n["status.heading_nav_disabled_canvas"])
            return false
        }
        if isTableModeActive {
            setStatusMessage(L10n["status.heading_nav_disabled_table"])
            return false
        }
        if !supportsDocumentOutlineForCurrentBuffer() {
            setStatusMessage(L10n["status.heading_nav_unsupported_format"])
            return false
        }
        return true
    }

    private func jumpToHeading(_ heading: DocumentHeading, in outline: DocumentOutline) {
        clearActiveMark()
        buffer.lineIndex = max(0, min(heading.lineIndex, buffer.lines.count - 1))
        buffer.columnIndex = 0
        topVLineIndex = max(0, buffer.lineIndex - 1)
        let index = (outline.headings.firstIndex(of: heading) ?? 0) + 1
        let markerTitle = "\(heading.marker) \(heading.title)"
        setStatusMessage(String(format: L10n["status.heading_position"], index, outline.headings.count, markerTitle))
    }

    private func initialOutlineSelectionIndex(in outline: DocumentOutline) -> Int {
        if let index = outline.headings.lastIndex(where: { $0.lineIndex <= buffer.lineIndex }) {
            return index
        }
        return 0
    }
}
