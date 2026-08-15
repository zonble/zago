import Foundation

extension LogoValue {
    internal func toListItems() -> [LogoValue] {
        switch self {
        case .list(let items), .array(let items): return items
        case .string(let s): return [.string(s)]
        }
    }
}
