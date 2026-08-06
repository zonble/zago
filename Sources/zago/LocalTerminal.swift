import Config
import Editor
import Foundation

#if os(Windows)
    public typealias LocalTerminal = WindowsTerminal
#else
    public typealias LocalTerminal = PosixTerminal
#endif
