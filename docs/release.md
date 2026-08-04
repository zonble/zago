# Release Process

This document is the canonical release checklist for zago.

## Audience

The current builds are preview builds for friends and early testers who are comfortable with terminal tools and can build Swift packages locally.

Good first testers:

- write Markdown, Org, reStructuredText, or AsciiDoc notes
- care about CJK and emoji terminal alignment
- are comfortable reporting exact terminal, OS, and reproduction steps
- can tolerate rough edges while the editor stabilizes

## Supported Platforms

- macOS 14.0 or later
- Linux with Swift 6.0 or later
- VT100 / ANSI-compatible terminal
- On Windows, prefer Windows Terminal or another VT-enabled console, and verify the console is using UTF-8 input/output (disable `Ctrl+Shift+Up` and `Ctrl+Shift+Down` in **Settings -> Actions** if they conflict with Canvas Mode arrow drawing)

Known-good terminal behavior should be checked on:

- macOS Terminal.app
- iTerm2
- kitty
- WezTerm
- common Linux terminal emulators

Unicode display width can vary by terminal. Test CJK, emoji, menu overlays, tables, and canvas blocks before calling a build ready.

## Install From Source

Clone and build:

```sh
git clone https://github.com/zonble/zago.git
cd zago
./build.sh
zago --version
```

By default this installs to:

```text
/usr/local/bin/zago
```

Install somewhere else:

```sh
PREFIX="$HOME/.local" ./build.sh
```

Then make sure the install path is in `PATH`:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

Build without installing:

```sh
swift build -c release
.build/release/zago notes.md
```

On macOS, `build.sh` builds a universal release binary and applies ad-hoc code signing. To skip signing:

```sh
SIGN=0 ./build.sh
```

## Install From Homebrew Tap

Users can install with:

```sh
brew tap zonble/zago
brew tap --trust zonble/zago  # allow this third-party tap
brew install zago
zago --version
```

If Homebrew refuses to use the third-party tap, run:

```sh
brew tap-info zonble/zago
brew tap --trust zonble/zago  # allow this third-party tap
brew install zago
```

Tap maintenance is documented in [Homebrew Tap](homebrew_tap.md).

On Linux, the Homebrew formula depends on Homebrew's `swift` package at build time. For non-Homebrew Linux installs, use Swift 6 from the distribution or Swift.org and build from source.

## Release Inputs

Before starting, choose the release version:

```text
X.Y.Z
```

For example:

```text
1.0.4
```

Use the corresponding tag name everywhere:

```text
vX.Y.Z
```

## Local Validation

Before sharing a build, run:

```powershell
swift test
swift build -c release --product zago
.build\x86_64-unknown-windows-msvc\release\zago.exe --version
```

On macOS or Linux, the release binary path is usually:

```sh
.build/release/zago --version
```

For install-script validation on macOS/Linux, also run:

```sh
./build.sh
zago --version
```

Then manually smoke-test:

- open, edit, save, and reopen a Markdown file
- paste CJK text and emoji such as `❌❌❌❌❌`
- resize the terminal window and verify the editor redraws automatically
- open the menu over lines containing wide characters
- toggle Canvas Mode with `M+V`
- create and edit a simple table
- run a small LOGO command from the prompt
- run a headless command such as `zago -e 'BOX 20 4'`

## Release Checklist

1. Update `Sources/Config/ZagoVersion.swift`.
2. Update `CHANGELOG.md`.
3. Update any version-specific tests.
4. Run the local validation commands above.
5. Commit the release changes:

```sh
git status --short
git add CHANGELOG.md Sources/Config/ZagoVersion.swift Tests/ConfigAndToolsTests.swift docs/release.md docs/homebrew_tap.md
git commit -m "Release X.Y.Z"
```

6. Create and push the tag:

```sh
git tag vX.Y.Z
git push origin main
git push origin vX.Y.Z
```

7. Convert the tag into a GitHub Release:

```sh
cat > release-notes-X.Y.Z.md <<'EOF'
Windows terminal redraw fix release.

### Fixed

- Windows terminal resize events now trigger an automatic full-screen redraw without waiting for the next keypress.
EOF

gh release create vX.Y.Z \
  --title "zago X.Y.Z" \
  --notes-file release-notes-X.Y.Z.md \
  --latest
```

If `gh` is unavailable, use GitHub's web UI:

1. Open `https://github.com/zonble/zago/releases/new`.
2. Choose the existing tag `vX.Y.Z`.
3. Set the release title to `zago X.Y.Z`.
4. Copy the `CHANGELOG.md` section for `X.Y.Z` into the release notes.
5. Publish the release.

8. Calculate the GitHub tag archive checksum:

```sh
curl -L https://github.com/zonble/zago/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
```

PowerShell alternative:

```powershell
$version = "X.Y.Z"
$archive = "$env:TEMP\zago-v$version.tar.gz"
Invoke-WebRequest -UseBasicParsing `
  -Uri "https://github.com/zonble/zago/archive/refs/tags/v$version.tar.gz" `
  -OutFile $archive
Get-FileHash -Algorithm SHA256 $archive
```

9. Update the Homebrew formula template and tap formula:

```ruby
url "https://github.com/zonble/zago/archive/refs/tags/vX.Y.Z.tar.gz"
sha256 "<sha256>"
```

10. In the tap repository, validate and push the formula:

```sh
brew install --build-from-source Formula/zago.rb
brew test zago
brew audit --strict Formula/zago.rb
brew style Formula/zago.rb
git add Formula/zago.rb
git commit -m "zago X.Y.Z"
git push origin main
```

11. Share install instructions and known limitations with testers.

## GitHub Release Notes

Use only the changelog section for the released version, not the entire changelog.

For `1.0.4`, the release notes should be:

```markdown
Windows terminal redraw fix release.

### Fixed

- Windows terminal resize events now trigger an automatic full-screen redraw without waiting for the next keypress.
```


## Tester Bug Reports

Ask testers to include:

- zago version: `zago --version`
- install method: Mint, source build, or copied binary
- OS and terminal app
- shell and locale: `echo $SHELL`, `locale`
- whether line numbers, ruler, syntax highlighting, or sub-line numbers were enabled
- exact text sample, especially for Unicode alignment bugs
- screenshot or short terminal recording when layout is involved

Useful Unicode layout samples:

```text
中文中文中文
❌❌❌❌❌
❤️❤️❤️
A❌B
│❌  │
```

## Current Preview Limitations

- Terminal Unicode width is pragmatic, not mathematically universal. Some terminals may render specific emoji differently.
- Mouse support is not a release goal.
- The document outline supports Markdown, Org, reStructuredText, and AsciiDoc only.
- Embedded syntax highlighting is intentionally single-level.
- The editor is still optimized for technical writers who are comfortable with keyboard-driven terminal workflows.
