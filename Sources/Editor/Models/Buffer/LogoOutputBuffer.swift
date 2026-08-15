import Foundation

final class LogoOutputBuffer: TextBuffer {
    override var isReadOnly: Bool {
        get { true }
        set {}
    }
    override var allowsLogoExecution: Bool { false }
}
