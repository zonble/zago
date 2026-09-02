/// Clean abstract delegate protocol for host editor interaction.
public protocol LogoEngineDelegate: AnyObject {
    /// Perform an action or mutation on the host editor.
    func logoEngine(_ engine: LogoEngine, performAction action: LogoEditorAction)

    /// Query state or data from the host editor.
    func logoEngine(_ engine: LogoEngine, queryState query: LogoEditorQuery) -> LogoEditorQueryResult?

    /// Read a line of text input with prompt message.
    func logoEngine(_ engine: LogoEngine, readWordWithPrompt prompt: String) -> String?

    /// Read a single keypress input with prompt message.
    func logoEngine(_ engine: LogoEngine, readCharWithPrompt prompt: String) -> String?
}

extension LogoEngineDelegate {
    public func logoEngine(_ engine: LogoEngine, readWordWithPrompt prompt: String) -> String? { "" }
    public func logoEngine(_ engine: LogoEngine, readCharWithPrompt prompt: String) -> String? { "" }
}
