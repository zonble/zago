#!/bin/sh
# zago installer for Linux
# Usage: curl -fsSL https://raw.githubusercontent.com/zonble/zago/main/install.sh | sh

set -e

REPO="zonble/zago"
BINARY_NAME="zago"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

# Detect architecture
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64)  ASSET_NAME="zago-linux-x86_64" ;;
    aarch64) ASSET_NAME="zago-linux-aarch64" ;;
    arm64)   ASSET_NAME="zago-linux-aarch64" ;;
    *)
        echo "Unsupported architecture: $ARCH"
        echo "Please build from source: https://github.com/$REPO"
        exit 1
        ;;
esac

# Ensure we are on Linux
if [ "$(uname -s)" != "Linux" ]; then
    echo "This script is for Linux only."
    echo "On macOS, use: brew tap zonble/zago && brew install zago"
    exit 1
fi

echo "Installing zago for Linux ($ARCH)..."

# Fetch latest release download URL from GitHub API
API_URL="https://api.github.com/repos/$REPO/releases/latest"
DOWNLOAD_URL=$(curl -fsSL "$API_URL" \
    -H "Accept: application/vnd.github+json" \
    | grep -o "\"browser_download_url\": *\"[^\"]*$ASSET_NAME\"" \
    | grep -o "https://[^\"]*")

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Could not find release asset '$ASSET_NAME' in the latest release."
    echo "Check: https://github.com/$REPO/releases/latest"
    exit 1
fi

# Create install directory if needed
mkdir -p "$INSTALL_DIR"

INSTALL_PATH="$INSTALL_DIR/$BINARY_NAME"
TEMP_FILE="$(mktemp)"

echo "Downloading $ASSET_NAME..."
curl -fsSL --progress-bar "$DOWNLOAD_URL" -o "$TEMP_FILE"

chmod +x "$TEMP_FILE"
mv "$TEMP_FILE" "$INSTALL_PATH"

echo ""
echo "zago installed to: $INSTALL_PATH"

# Advise on PATH if needed
case ":${PATH}:" in
    *":$INSTALL_DIR:"*) ;;
    *)
        echo ""
        echo "Note: $INSTALL_DIR is not in your PATH."
        echo "Add the following line to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
        echo ""
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
        ;;
esac

echo "Try running: zago --version"
