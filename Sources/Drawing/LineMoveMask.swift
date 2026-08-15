import Foundation

/// Connection masks used when rendering an automatically connected line.
public enum LineMoveMask {
    public static func horizontal(offset: Int, lastOffset: Int) -> Int {
        if lastOffset == 0 { return 10 }
        if offset == 0 { return 2 }
        if offset == lastOffset { return 8 }
        return 10
    }

    public static func vertical(offset: Int, lastOffset: Int) -> Int {
        if lastOffset == 0 { return 5 }
        if offset == 0 { return 4 }
        if offset == lastOffset { return 1 }
        return 5
    }
}
