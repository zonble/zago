import Foundation

public final class LogoOutputBuffer: TextBuffer {
    override public var isReadOnly: Bool {
        get { true }
        set {}
    }
    override public var allowsLogoExecution: Bool { false }
}
