import Config
import Foundation

public struct EditorConfigSource {
    public let initial: EditorConfig
    public let reload: () -> EditorConfig

    public init(
        initial: EditorConfig = EditorConfig(),
        reload: @escaping () -> EditorConfig = { EditorConfig() }
    ) {
        self.initial = initial
        self.reload = reload
    }
}
