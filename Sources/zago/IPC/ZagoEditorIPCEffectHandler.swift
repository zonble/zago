import Editor
import Foundation

final class ZagoEditorIPCEffectHandler: EditorEffectDelegate {
    private weak var editor: Editor?
    private let terminal: EditorTerminal
    private var session: ZagoEditorIPCSession?

    init(editor: Editor, terminal: EditorTerminal) {
        self.editor = editor
        self.terminal = terminal
    }

    func editor(_ editor: Editor, didEmit effect: EditorEffect) {
        switch effect {
        case .ipcEnabled(true): startSession(for: editor)
        case .ipcEnabled(false): stopSession(for: editor)
        }
    }

    private func startSession(for editor: Editor) {
        guard session == nil else { return }
        let session = ZagoEditorIPCSession(editor: editor, terminal: terminal)
        do {
            try session.start()
            self.session = session
            editor.reportOperationResult(
                .succeeded(message: "[IPC] Socket: \(session.socketPath) | Token: \(session.sessionToken)"))
        } catch {
            editor.reportOperationResult(.failed(error.localizedDescription, message: "[IPC Error] \(error.localizedDescription)"))
            editor.apply(EditorSettingUpdate.ipc(false))
        }
    }

    private func stopSession(for editor: Editor) {
        guard let session else { return }
        session.stop()
        self.session = nil
        editor.reportOperationResult(.succeeded(message: "[IPC Disabled]"))
    }
}
