import Testing

@testable import Editor
@testable import zago

struct ZagoCLITests {
    @Test func testInteractiveOptionsDoNotOverrideConfigWhenRulerFlagIsAbsent() {
        let options = Zago.makeInteractiveOptions(
            baseOptions: EditorOptions(showRuler: nil, ipcEnabled: nil),
            ruler: false,
            enableSyntax: nil,
            ipc: false,
            noIpc: false
        )

        #expect(options.showRuler == nil)
        #expect(options.enableSyntax == nil)
        #expect(options.ipcEnabled == nil)
    }

    @Test func testInteractiveOptionsApplyExplicitCliOverrides() {
        let options = Zago.makeInteractiveOptions(
            baseOptions: EditorOptions(showRuler: nil, ipcEnabled: nil),
            ruler: true,
            enableSyntax: false,
            ipc: true,
            noIpc: false
        )

        #expect(options.showRuler == true)
        #expect(options.enableSyntax == false)
        #expect(options.ipcEnabled == true)
    }
}
