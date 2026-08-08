#!/bin/sh
set -e

PREFIX="${PREFIX:-/usr/local}"
INSTALL_DIR="${INSTALL_DIR:-$PREFIX/bin}"
BINARY_NAME="${BINARY_NAME:-zago}"
INSTALL_PATH="$INSTALL_DIR/$BINARY_NAME"
SIGN="${SIGN:-1}"

if [ "$(uname)" = "Darwin" ]; then
    echo "Building universal binary for macOS (arm64 + x86_64)..."
    swift build -c release -Xswiftc -Osize --arch arm64 --arch x86_64
    BINARY_PATH=".build/apple/Products/Release/zago"
else
    echo "Building release binary..."
    swift build -c release -Xswiftc -Osize
    BINARY_PATH=".build/release/zago"
fi

if [ -f "$BINARY_PATH" ]; then
    echo "Installing zago to $INSTALL_PATH..."
    mkdir -p "$INSTALL_DIR"
    cp "$BINARY_PATH" "$INSTALL_PATH"
    if command -v strip >/dev/null 2>&1; then
        echo "Stripping debug symbols..."
        strip "$INSTALL_PATH" 2>/dev/null || true
    fi
fi

if [ "$(uname)" = "Darwin" ] && [ "$SIGN" != "0" ]; then
    echo "Performing ad-hoc code signing..."
    codesign -f -s - "$INSTALL_PATH"
fi

echo "Build and installation complete: $INSTALL_PATH"
