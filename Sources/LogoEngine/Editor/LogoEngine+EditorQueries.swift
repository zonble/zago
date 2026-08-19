import Foundation

extension LogoEngine {
    internal func queryInteger(_ query: LogoEditorQuery) -> Int? {
        delegate?.logoEngine(self, queryState: query)?.integerValue
    }

    internal func queryString(_ query: LogoEditorQuery) -> String? {
        delegate?.logoEngine(self, queryState: query)?.stringValue
    }

    internal func queryBool(_ query: LogoEditorQuery) -> Bool? {
        delegate?.logoEngine(self, queryState: query)?.boolValue
    }

    internal func queryStrings(_ query: LogoEditorQuery) -> [String]? {
        delegate?.logoEngine(self, queryState: query)?.stringsValue
    }

    internal func queryBorderStyle(_ query: LogoEditorQuery) -> BorderStyle? {
        delegate?.logoEngine(self, queryState: query)?.borderStyleValue
    }

    internal func queryArrowStyle(_ query: LogoEditorQuery) -> ArrowStyle? {
        delegate?.logoEngine(self, queryState: query)?.arrowStyleValue
    }

    internal func queryCanvasBlockFrame(_ query: LogoEditorQuery) -> LogoCanvasBlockFrame? {
        delegate?.logoEngine(self, queryState: query)?.canvasBlockFrameValue
    }
}
