import Config
import Foundation

public protocol EditorTerminal: AnyObject {
    func enableRawMode() throws
    func disableRawMode()
    func getWindowSize() -> (rows: Int, cols: Int)
    func readKey() -> Key
    func readPendingText(firstChar: Character) -> String
    func write(_ text: String)
    func hideCursor()
    func showCursor()
    func clearScreen()
}
