# Windows Swift Debugging

This guide describes the recommended debugging setup for developing and diagnosing `zago` on Windows.

## Recommended Tools

Use different tools for different failure modes:

- VS Code with the Swift extension: best for normal Swift breakpoints, SwiftPM launch configurations, and test debugging.
- Visual Studio native debugger: useful for attaching to a hung `zago.exe`, opening `.dmp` files, and inspecting native threads.
- WinDbg or `cdb`: useful for command-line stack capture, CI hang diagnosis, and bug reports.
- Targeted begin/end tracing: useful when a terminal editor hang is hard to inspect with a debugger.

Avoid using a standalone LLVM `lldb.exe` from a separate LLVM installation for Swift debugging. Swift debugging works best with the LLDB that matches the installed Swift toolchain. A mismatched LLDB can fail to start, fail to load Python runtime DLLs, or misinterpret Swift frames.

## Install Requirements

Install the official Swift toolchain for Windows and the Visual Studio C++/Windows SDK components required by Swift.

Useful components:

- Swift toolchain from Swift.org or Winget.
- Visual Studio 2022 or newer with MSVC C++ tools.
- Windows SDK.
- VS Code Swift extension for normal Swift development.
- Windows SDK Debugging Tools if `cdb` or WinDbg is needed.

Check the Swift toolchain:

```powershell
swift --version
swift build
swift test
```

If multiple Swift or LLVM installations exist, prefer toolchain binaries under:

```text
%LOCALAPPDATA%\Programs\Swift\Toolchains\...\usr\bin
```

## VS Code Swift Debugging

Open the repository folder in VS Code and install the Swift extension.

The extension can generate SwiftPM launch configurations for executable products and tests. For `zago`, a debug launch configuration should point at the debug executable:

```json
{
  "type": "swift",
  "request": "launch",
  "name": "Debug zago",
  "program": "${workspaceFolder}/.build/debug/zago.exe",
  "args": ["test.md"],
  "cwd": "${workspaceFolder}"
}
```

Use this mode for ordinary breakpoints and stepping through Swift code.

## Attach To A Hung zago Process

For terminal input/output bugs, attach after reproducing the hang. Launching under a debugger can change console behavior.

Run `zago` normally:

```powershell
.\.build\debug\zago.exe test.md
```

After it hangs, attach with Visual Studio:

1. Open Visual Studio.
2. Choose `Debug > Attach to Process...`.
3. Select `zago.exe`.
4. Use `Native` attach type.
5. Choose `Debug > Break All`.
6. Open `Debug > Windows > Threads`.
7. Open `Debug > Windows > Call Stack`.
8. In Call Stack, enable `Show External Code` and `Show Module Names`.

Inspect likely threads:

- `com.apple.root.user-interactive-qos.overcommit`: often the editor loop or terminal I/O work.
- `com.apple.root.utility-qos.overcommit`: often file watcher work.
- `Main Thread`: often dispatch runtime infrastructure, not always the editor loop.

Useful native stack clues:

- `ReadConsoleInputW`: waiting for terminal input.
- `WriteConsoleW`: blocked while writing terminal output.
- `WaitForMultipleObjects` or `WaitForSingleObject`: waiting on a Win32 handle, dispatch event, or watcher notification.
- `CreateFileW`, `WriteFile`, or `Data.write`: file I/O or lock issue.
- `dispatch.dll`: often a Swift `DispatchQueue.sync`, async worker, or semaphore wait.

## Capture A Dump

If live attach is awkward, create a dump:

1. Open Task Manager.
2. Go to the Details tab.
3. Right-click `zago.exe`.
4. Choose `Create dump file`.
5. Open the `.DMP` file in Visual Studio.
6. Select `Debug with Native Only`.

Use the same Threads and Call Stack windows to inspect where each thread is stopped.

## Command-Line Stack Capture

If Windows SDK Debugging Tools are installed, `cdb` can capture all stacks without opening Visual Studio:

```powershell
Get-Process zago
cdb -p <PID> -c "~* k; q"
```

The output is enough to classify many hangs, even when Swift symbols are incomplete.

If `cdb` is not found, check the usual SDK location:

```powershell
Get-Command cdb -ErrorAction SilentlyContinue
```

## Symbol Notes

Swift symbols on Windows may not always show clean Swift names in Visual Studio. Native module names and Windows API frames are still useful.

If only addresses are shown:

1. Open `Debug > Windows > Modules`.
2. Find `zago.exe`.
3. Check the module path and symbol status.
4. Record the stack with module names enabled.

Even a stack like this is useful:

```text
ntdll.dll!...
KERNELBASE.dll!...
dispatch.dll!...
zago.exe!...
```

The top native API and thread type usually identify the subsystem that is blocked.

## Trace-Based Hang Diagnosis

For terminal editor bugs, a short-lived trace can be faster than a debugger.

Use begin/end logging around suspected blocking boundaries:

- editor loop: before and after `refreshScreen`, `readKey`, and `processKey`
- rendering: before and after terminal write
- terminal: before and after `ReadConsoleInputW` and `WriteConsoleW`
- save path: before and after `Data.write`
- file watcher: before and after `start`, `stop`, and mtime recording

The last `begin` line without a matching `end` line identifies the blocking operation.

Keep trace code behind an environment variable and remove temporary tracing before committing unless it is intentionally added as a supported diagnostic facility.

Example workflow:

```powershell
Remove-Item $env:TEMP\zago-trace.log -ErrorAction SilentlyContinue
$env:ZAGO_TRACE_IO = "1"
.\.build\debug\zago.exe test.md
Get-Content $env:TEMP\zago-trace.log -Tail 80
```

## Windows-Specific Pitfalls

Console and file watcher bugs often look like editor command bugs. Confirm the blocked subsystem before changing command handling.

Common traps:

- Ctrl key input can leave key-up or zero-character console events in the input queue.
- Terminal output can appear frozen if `WriteConsoleW` is blocked.
- File watchers can deadlock if one serial dispatch queue is both running a long-lived worker and used with `queue.sync`.
- Closing a Win32 handle while another thread is waiting on it is unsafe; signal a stop event and let the worker close its own handles.
- Visual Studio, Windhawk, terminal customizations, and shell integrations can inject DLLs or hooks. Reproduce with those disabled when behavior is surprising.

## Practical Debugging Order

1. Reproduce with a debug build.
2. Attach or create a dump.
3. Identify the blocked thread and native API.
4. Add narrow begin/end trace if the stack is ambiguous.
5. Fix the smallest subsystem that explains the blocking point.
6. Remove temporary trace code.
7. Run targeted tests and manually re-check the original interaction.
