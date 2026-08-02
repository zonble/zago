#!/bin/sh
set -e

PREFIX="${PREFIX:-/usr/local}"
INSTALL_DIR="${INSTALL_DIR:-$PREFIX/bin}"
BINARY_NAME="${BINARY_NAME:-zago}"
INSTALL_PATH="$INSTALL_DIR/$BINARY_NAME"
SIGN="${SIGN:-1}"

if [ "$(uname)" = "Darwin" ]; then
    echo "Building universal binary for macOS (arm64 + x86_64)..."
    swift build -c release --arch arm64 --arch x86_64
    BINARY_PATH=".build/apple/Products/Release/zago"
else
    echo "Building release binary..."
    swift build -c release
    BINARY_PATH=".build/release/zago"
fi

if [ -f "$BINARY_PATH" ]; then
    echo "Installing zago to $INSTALL_PATH..."
    mkdir -p "$INSTALL_DIR"
    cp "$BINARY_PATH" "$INSTALL_PATH"
fi

if [ "$(uname)" = "Darwin" ] && [ "$SIGN" != "0" ]; then
    echo "Performing ad-hoc code signing..."
    codesign -f -s - "$INSTALL_PATH"
fi

echo "Build and installation complete: $INSTALL_PATH"
