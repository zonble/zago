import Foundation

public enum ZagoVersion {
    /// Single Source of Truth for the `zago` editor version number.
    public static let current = "1.3.0"
    public static let author = "zonble"
    public static let email = "zonble@gmail.com"
    public static let repository = "https://github.com/zonble/zago"
    public static let summary = "zago v\(current) - zonble's nano + Editor LOGO"

    public static var creditsBanner: String {
        """
        ┌─────────────────────────────────────────────────────────────┐
        │                      zago v\(current.padding(toLength: 8, withPad: " ", startingAt: 0))                         │
        │      zonble's nano + Editor LOGO Plain-Text Editor          │
        │                                                             │
        │  Author:     zonble (zonble@gmail.com)                      │
        │  Repository: https://github.com/zonble/zago                 │
        │  License:    MIT                                            │
        │              To all the heroes who inspired me              │
        │              In memory of China Airlines Flight 676         │
        └─────────────────────────────────────────────────────────────┘
        """
    }
}
