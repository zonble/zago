# Homebrew Tap

This document describes how to publish zago through a personal Homebrew tap.

The source repository is:

```text
https://github.com/zonble/zago
```

The Homebrew tap repository is:

```text
https://github.com/zonble/homebrew-zago
```

With that repository name, users install zago with:

```sh
brew tap zonble/zago
brew tap --trust zonble/zago  # allow this third-party tap
brew install zago
```

Homebrew may refuse to install from an untrusted third-party tap. Ask users to run `brew tap-info zonble/zago` first if they want to inspect the tap, then `brew tap --trust zonble/zago` before installing.

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

The checked-in template tracks the current release. Update the tag URL and SHA before each tap release.

## Release Source Archive

Homebrew should build from an immutable release tag archive:

```text
https://github.com/zonble/zago/archive/refs/tags/vX.Y.Z.tar.gz
```

To prepare a new release, follow the canonical checklist in [Release Process](release.md). The Homebrew-specific steps are:

1. Create and push the source release tag:

```sh
git tag vX.Y.Z
git push origin main
git push origin vX.Y.Z
```

2. Convert the tag into a GitHub Release.
3. Calculate the archive checksum:

```sh
curl -L https://github.com/zonble/zago/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
```

4. Update `Formula/zago.rb` in `homebrew-zago`:

```ruby
url "https://github.com/zonble/zago/archive/refs/tags/vX.Y.Z.tar.gz"
sha256 "<sha256>"
```

5. Validate and push the tap formula:

```sh
brew install --build-from-source Formula/zago.rb
brew test zago
brew audit --strict Formula/zago.rb
brew style Formula/zago.rb
git add Formula/zago.rb
git commit -m "zago X.Y.Z"
git push origin main
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

The formula supports macOS and Linux:

- macOS builds with Xcode 16 or later.
- Linux builds with Homebrew's `swift` package as a build dependency.

For non-Homebrew Linux installs, ask users to install Swift 6 from their distribution or Swift.org and build from source.

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
brew tap --trust zonble/zago  # allow this third-party tap
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
