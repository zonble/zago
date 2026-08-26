import Foundation
import Testing

@testable import Config
@testable import zagoweb

@Suite struct WasiTerminalTests {

    @Test func testReadPendingTextWithEmptyPendingBuffer() {
        let terminal = WasiTerminal()
        let result = terminal.readPendingText(firstChar: "A")
        #expect(result == "A")
    }

    @Test func testReadPendingTextDrainsCJKCharacters() {
        let terminal = WasiTerminal()
        let textToInject = "測試中文輸入法批次處理"
        let utf8Bytes = Array(textToInject.utf8)
        terminal.injectPendingBytes(utf8Bytes)
        
        let result = terminal.readPendingText(firstChar: "這")
        #expect(result == "這測試中文輸入法批次處理")
        #expect(!terminal.hasPendingInput())
    }

    @Test func testReadPendingTextPreservesNewlinesAndCRLF() {
        let terminal = WasiTerminal()
        let textToInject = "hello\r\nworld\nend"
        let utf8Bytes = Array(textToInject.utf8)
        terminal.injectPendingBytes(utf8Bytes)
        
        let result = terminal.readPendingText(firstChar: ">")
        #expect(result == ">hello\nworld\nend")
        #expect(!terminal.hasPendingInput())
    }

    @Test func testReadPendingTextStopsBeforeEscapeSequence() {
        let terminal = WasiTerminal()
        // Text followed by Up Arrow escape sequence \u{1B}[A
        let textToInject = "abc\u{1B}[A"
        let utf8Bytes = Array(textToInject.utf8)
        terminal.injectPendingBytes(utf8Bytes)
        
        let result = terminal.readPendingText(firstChar: "X")
        #expect(result == "Xabc")
        #expect(terminal.hasPendingInput())
        
        // Next readInputEvent should parse the escape sequence as Arrow Up
        let event = terminal.readInputEvent()
        if case .key(let key) = event {
            #expect(key == .arrowUp)
        } else {
            Issue.record("Expected .arrowUp key event")
        }
    }

    @Test func testReadPendingTextHandlesIncompleteUTF8SequenceGracefully() {
        let terminal = WasiTerminal()
        // "中" in UTF-8 is 0xE4 0xB8 0xAD (3 bytes). Inject only the first 2 bytes.
        let incompleteBytes: [UInt8] = [0xE4, 0xB8]
        terminal.injectPendingBytes(incompleteBytes)
        
        let result = terminal.readPendingText(firstChar: "X")
        #expect(result == "X")
        #expect(terminal.hasPendingInput())
    }
}
