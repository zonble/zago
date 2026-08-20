import Editor
import Foundation

#if os(Linux) || os(Android)
    internal final class LinuxClipboardBackend: EditorClipboardStrategy, @unchecked Sendable {
        private var inMemoryBlock: CanvasBlockClipboard? = nil
        private let lock = NSLock()

        init() {}

        func copyText(_ text: String) {
            lock.lock()
            defer { lock.unlock() }

            inMemoryBlock = nil
            writeToSystemClipboard(text)
        }

        func copyBlock(_ block: CanvasBlockClipboard) {
            lock.lock()
            defer { lock.unlock() }

            inMemoryBlock = block
            let plainText = block.rows.joined(separator: "\n")
            writeToSystemClipboard(plainText)
        }

        func getText() -> String? {
            lock.lock()
            defer { lock.unlock() }

            return readFromSystemClipboard()
        }

        func getBlock() -> CanvasBlockClipboard? {
            lock.lock()
            defer { lock.unlock() }

            return inMemoryBlock
        }

        func clear() {
            lock.lock()
            defer { lock.unlock() }

            inMemoryBlock = nil
            writeToSystemClipboard("")
        }

        private func writeToSystemClipboard(_ text: String) {
            if runCommand(["wl-copy"], input: text) { return }
            if runCommand(["xclip", "-selection", "clipboard"], input: text) { return }
            if runCommand(["xsel", "--clipboard", "--input"], input: text) { return }
        }

        private func readFromSystemClipboard() -> String? {
            if let output = runCommandWithOutput(["wl-paste", "--no-newline"]) { return output }
            if let output = runCommandWithOutput(["xclip", "-selection", "clipboard", "-out"]) { return output }
            if let output = runCommandWithOutput(["xsel", "--clipboard", "--output"]) { return output }
            return nil
        }

        private func runCommand(_ args: [String], input: String) -> Bool {
            guard let executable = args.first else { return false }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/\(executable)")
            if !FileManager.default.fileExists(atPath: process.executableURL?.path ?? "") {
                process.executableURL = URL(fileURLWithPath: "/bin/\(executable)")
            }
            guard FileManager.default.fileExists(atPath: process.executableURL?.path ?? "") else {
                return false
            }

            process.arguments = Array(args.dropFirst())
            let stdin = Pipe()
            process.standardInput = stdin
            process.standardOutput = Pipe()
            process.standardError = Pipe()

            do {
                try process.run()
                if let data = input.data(using: .utf8) {
                    stdin.fileHandleForWriting.write(data)
                }
                stdin.fileHandleForWriting.closeFile()
                process.waitUntilExit()
                return process.terminationStatus == 0
            } catch {
                return false
            }
        }

        private func runCommandWithOutput(_ args: [String]) -> String? {
            guard let executable = args.first else { return nil }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/\(executable)")
            if !FileManager.default.fileExists(atPath: process.executableURL?.path ?? "") {
                process.executableURL = URL(fileURLWithPath: "/bin/\(executable)")
            }
            guard FileManager.default.fileExists(atPath: process.executableURL?.path ?? "") else {
                return nil
            }

            process.arguments = Array(args.dropFirst())
            let stdout = Pipe()
            process.standardOutput = stdout
            process.standardError = Pipe()

            do {
                try process.run()
                process.waitUntilExit()
                guard process.terminationStatus == 0 else { return nil }
                let data = stdout.fileHandleForReading.readDataToEndOfFile()
                return String(data: data, encoding: .utf8)
            } catch {
                return nil
            }
        }
    }
#endif
