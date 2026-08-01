#!/bin/sh
set -e

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
    echo "Installing zago to /usr/local/bin/zago..."
    cp "$BINARY_PATH" /usr/local/bin/zago
fi

if [ "$(uname)" = "Darwin" ]; then
    echo "Performing ad-hoc code signing..."
    codesign -f -s - /usr/local/bin/zago
fi

echo "Build and installation complete!"