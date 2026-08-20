import Foundation

public struct CanvasBlockClipboard: Sendable, Equatable, Codable {
    public let width: Int
    public let rows: [String]

    public init(width: Int, rows: [String]) {
        self.width = width
        self.rows = rows
    }
}
