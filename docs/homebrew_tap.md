# Homebrew Tap

This document describes how to publish zago through a personal Homebrew tap.

The source repository is:

```text
https://github.com/zonble/zago
```

The Homebrew tap repository should be:

```text
https://github.com/zonble/homebrew-zago
```

With that repository name, users install zago with:

```sh
brew tap zonble/zago
brew install zago
```

## Tap Repository Layout

Create a separate repository named `homebrew-zago`:

```text
homebrew-zago/
  Formula/
    zago.rb
```

Copy the template from this repository:

```sh
mkdir -p Formula
cp packaging/homebrew/zago.rb Formula/zago.rb
```

The checked-in template uses a placeholder SHA. Replace it before pushing the tap.

## Release Source Archive

Homebrew should build from an immutable release tag archive:

```text
https://github.com/zonble/zago/archive/refs/tags/vX.Y.Z.tar.gz
```

To prepare a new release:

1. Update `Sources/Config/ZagoVersion.swift`.
2. Update `CHANGELOG.md`.
3. Run the release smoke test from `docs/release.md`.
4. Commit the release changes.
5. Create and push a tag:

```sh
git tag vX.Y.Z
git push origin vX.Y.Z
```

6. Calculate the archive checksum:

```sh
curl -L https://github.com/zonble/zago/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
```

7. Update `Formula/zago.rb` in `homebrew-zago`:

```ruby
url "https://github.com/zonble/zago/archive/refs/tags/vX.Y.Z.tar.gz"
sha256 "<sha256>"
```

## Formula

The current formula template lives at:

```text
packaging/homebrew/zago.rb
```

It builds the SwiftPM executable from source:

```ruby
system "swift", "build",
  "--configuration", "release",
  "--disable-sandbox",
  "--product", "zago"
```

The first tap version is macOS-focused and depends on Xcode 16 or later because zago uses Swift 6. Linux users can still build from source with Swift 6 until the Homebrew Linux dependency story is verified.

## Local Tap Test

From the `homebrew-zago` repository:

```sh
brew install --build-from-source Formula/zago.rb
brew test zago
zago --version
```

For the HEAD build:

```sh
brew install --HEAD Formula/zago.rb
```

Optional checks before sharing the tap:

```sh
brew audit --strict Formula/zago.rb
brew style Formula/zago.rb
```

## User Install Instructions

After the tap repository is pushed:

```sh
brew tap zonble/zago
brew install zago
zago --version
```

To update:

```sh
brew update
brew upgrade zago
```

To uninstall:

```sh
brew uninstall zago
brew untap zonble/zago
```
