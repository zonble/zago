import Testing
@testable import Editor

@Suite struct ExternalRequestServiceTests {
    @Test func testResolveBufferByIdAndPath() {
        let service = ExternalRequestService()
        let buf1 = TextBuffer()
        buf1.filePath = "/path/to/file1.txt"
        let buf2 = TextBuffer()
        buf2.filePath = "/path/to/file2.txt"

        let active = buf1
        let buffers = [buf1, buf2]

        #expect(service.resolveBuffer(target: nil, buffers: buffers, activeBuffer: active)?.id == buf1.id)
        #expect(service.resolveBuffer(target: "active", buffers: buffers, activeBuffer: active)?.id == buf1.id)
        #expect(service.resolveBuffer(target: buf2.id, buffers: buffers, activeBuffer: active)?.id == buf2.id)
        #expect(service.resolveBuffer(target: "file2.txt", buffers: buffers, activeBuffer: active)?.id == buf2.id)
        #expect(service.resolveBuffer(target: "/path/to/file2.txt", buffers: buffers, activeBuffer: active)?.id == buf2.id)
    }

    @Test func testGetBuffersSnapshot() {
        let service = ExternalRequestService()
        let buf = TextBuffer()
        buf.filePath = "/test/doc.txt"
        buf.lines = ["hello"]

        let infos = service.getBuffers(buffers: [buf], activeIndex: 0)
        #expect(infos.count == 1)
        #expect(infos[0].fileName == "doc.txt")
        #expect(infos[0].isFocused == true)
    }

    @Test func testGetTextRange() {
        let service = ExternalRequestService()
        let buf = TextBuffer()
        buf.lines = ["Line 1", "Line 2", "Line 3", "Line 4"]

        let result = service.getText(from: buf, startLine: 2, endLine: 3)
        #expect(result?.lines == ["Line 2", "Line 3"])
        #expect(result?.totalLines == 4)
    }

    @Test func testGetSelection() {
        let service = ExternalRequestService()
        let buf = TextBuffer()
        buf.lines = ["Hello World"]
        buf.lineIndex = 0
        buf.columnIndex = 5
        buf.selectionMark = (line: 0, column: 0)

        let sel = service.getSelection(from: buf)
        #expect(sel?.hasSelection == true)
        #expect(sel?.text == "Hello")
        #expect(sel?.startLine == 1)
        #expect(sel?.startColumn == 1)
        #expect(sel?.endColumn == 6)
    }

    @Test func testCreateLogoProposal() {
        let service = ExternalRequestService()
        let buf = TextBuffer()
        buf.filePath = "/path/test.txt"

        let (proposal, output) = service.createLogoProposal(
            clientId: "test-client",
            clientName: "Test",
            script: "BOX 5 3",
            targetBuffer: buf,
            cursorLine: 1,
            cursorVisualCol: 1
        )
        #expect(proposal.clientId == "test-client")
        #expect(proposal.affectedFiles.first?.chunks.first?.lines.count == 3)
        #expect(!output.isEmpty)
    }
}
