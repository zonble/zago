#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "==> Building zago for WebAssembly..."

mkdir -p web/public

if command -v docker >/dev/null 2>&1 && docker image inspect zago-wasm-builder >/dev/null 2>&1; then
    echo "==> Using cached Docker container 'zago-wasm-builder'..."
    docker run --rm -v "$ROOT_DIR":/workspace -w /workspace zago-wasm-builder \
        swift build --configuration release --swift-sdk wasm32-unknown-wasi --product zagoweb
elif swift sdk list 2>/dev/null | grep -q "wasm"; then
    echo "==> Using local Swift Wasm SDK..."
    # Keep the SDK selection deterministic on CI machines that may have more
    # than one WebAssembly SDK installed.
    WASM_SDK="6.3-RELEASE-wasm32-unknown-wasip1"
    if ! swift sdk list | grep -Fxq "$WASM_SDK"; then
        echo "==> Error: Expected Swift Wasm SDK '$WASM_SDK' is not installed."
        swift sdk list
        exit 1
    fi
    swift build --configuration release --swift-sdk "$WASM_SDK" --product zagoweb
else
    echo "==> Error: No Swift Wasm SDK found locally and 'zago-wasm-builder' image not built."
    echo "    Run: docker build -t zago-wasm-builder -f Dockerfile.wasm ."
    exit 1
fi

WASM_OUT=$(find .build -name "zagoweb.wasm" -o -name "zago.wasm" 2>/dev/null | grep -v "apple-macosx" | grep "release" | head -n 1 || true)

if [ -n "$WASM_OUT" ] && [ -f "$WASM_OUT" ]; then
    echo "==> Copying $WASM_OUT to web/public/zago.wasm"
    cp "$WASM_OUT" web/public/zago.wasm
    echo "==> Wasm build complete: web/public/zago.wasm ($(du -h web/public/zago.wasm | cut -f1))"
else
    echo "==> Error: Could not find compiled wasm binary."
    exit 1
fi
