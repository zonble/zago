import Foundation

public struct TextReadResult: Sendable, Equatable {
    public let content: String
    public let encoding: String.Encoding

    public init(content: String, encoding: String.Encoding) {
        self.content = content
        self.encoding = encoding
    }
}
