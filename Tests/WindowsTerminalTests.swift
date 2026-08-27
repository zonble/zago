import Foundation
import Testing

@testable import Config
@testable import Editor
@testable import zago

#if os(Windows)
@Suite struct WindowsTerminalTests {

    @Test func testWindowsTerminalSGRMouseLeftClick() {
        let terminal = WindowsTerminal()
        let seq = "\u{1B}[<0;20;10M"
        terminal.injectPendingUnitsForTesting(Array(seq.utf16))

        let event = terminal.readInputEvent()
        if case .mouse(let mouseEvent) = event {
            #expect(mouseEvent.action == .press(.left))
            #expect(mouseEvent.col == 20)
            #expect(mouseEvent.row == 10)
            #expect(mouseEvent.shift == false)
            #expect(mouseEvent.alt == false)
            #expect(mouseEvent.ctrl == false)
        } else {
            Issue.record("Expected .mouse event but got \(event)")
        }
        #expect(!terminal.hasPendingInput())
    }

    @Test func testWindowsTerminalSGRMouseRelease() {
        let terminal = WindowsTerminal()
        let seq = "\u{1B}[<0;20;10m"
        terminal.injectPendingUnitsForTesting(Array(seq.utf16))

        let event = terminal.readInputEvent()
        if case .mouse(let mouseEvent) = event {
            #expect(mouseEvent.action == .release(.left))
            #expect(mouseEvent.col == 20)
            #expect(mouseEvent.row == 10)
        } else {
            Issue.record("Expected .mouse release event but got \(event)")
        }
    }

    @Test func testWindowsTerminalSGRMouseDrag() {
        let terminal = WindowsTerminal()
        let seq = "\u{1B}[<32;25;12M"
        terminal.injectPendingUnitsForTesting(Array(seq.utf16))

        let event = terminal.readInputEvent()
        if case .mouse(let mouseEvent) = event {
            #expect(mouseEvent.action == .drag(.left))
            #expect(mouseEvent.col == 25)
            #expect(mouseEvent.row == 12)
        } else {
            Issue.record("Expected .mouse drag event but got \(event)")
        }
    }

    @Test func testWindowsTerminalSGRMouseScrollUpAndDown() {
        let terminal = WindowsTerminal()
        let seqUp = "\u{1B}[<64;10;5M"
        let seqDown = "\u{1B}[<65;10;5M"
        terminal.injectPendingUnitsForTesting(Array(seqUp.utf16) + Array(seqDown.utf16))

        let event1 = terminal.readInputEvent()
        if case .mouse(let mouseEvent) = event1 {
            #expect(mouseEvent.action == .scrollUp)
            #expect(mouseEvent.col == 10)
            #expect(mouseEvent.row == 5)
        } else {
            Issue.record("Expected .scrollUp event but got \(event1)")
        }

        let event2 = terminal.readInputEvent()
        if case .mouse(let mouseEvent) = event2 {
            #expect(mouseEvent.action == .scrollDown)
            #expect(mouseEvent.col == 10)
            #expect(mouseEvent.row == 5)
        } else {
            Issue.record("Expected .scrollDown event but got \(event2)")
        }
    }

    @Test func testWindowsTerminalReadKeyIgnoresMouse() {
        let terminal = WindowsTerminal()
        let seq = "\u{1B}[<0;20;10M"
        terminal.injectPendingUnitsForTesting(Array(seq.utf16))

        let key = terminal.readKey()
        #expect(key == .unknown)
        #expect(!terminal.hasPendingInput())
    }

    @Test func testWindowsTerminalHasPendingInput() {
        let terminal = WindowsTerminal()
        #expect(!terminal.hasPendingInput())

        terminal.injectPendingUnitsForTesting(Array("A".utf16))
        #expect(terminal.hasPendingInput())

        let event = terminal.readInputEvent()
        #expect(event == .key(.char("A")))
        #expect(!terminal.hasPendingInput())
    }

    @Test func testWindowsTerminalReadPendingTextDrainsInjectedUnits() {
        let terminal = WindowsTerminal()
        terminal.injectPendingUnitsForTesting(Array("bcdef".utf16))

        let text = terminal.readPendingText(firstChar: "a")
        #expect(text == "abcdef")
    }
}
#endif
