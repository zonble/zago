#!/bin/sh
set -e

BINARY_PATH="${1:-.build/release/zago}"
VERSION="${2:-0.1.0}"
ARCH_INPUT="${3:-$(uname -m)}"

if [ ! -f "$BINARY_PATH" ]; then
    echo "Binary not found at $BINARY_PATH"
    exit 1
fi

DEB_ARCH="$ARCH_INPUT"
case "$DEB_ARCH" in
    x86_64) DEB_ARCH="amd64" ;;
    aarch64|arm64) DEB_ARCH="arm64" ;;
esac

PACKAGE_NAME="zago_${VERSION}_${DEB_ARCH}"
BUILD_DIR=".build/deb/${PACKAGE_NAME}"

echo "Building Debian package: ${PACKAGE_NAME}.deb..."

mkdir -p "${BUILD_DIR}/usr/bin"
mkdir -p "${BUILD_DIR}/DEBIAN"

cp "$BINARY_PATH" "${BUILD_DIR}/usr/bin/zago"
chmod 755 "${BUILD_DIR}/usr/bin/zago"

sed -e "s/VERSION/${VERSION}/g" \
    -e "s/ARCH/${DEB_ARCH}/g" \
    packaging/deb/control > "${BUILD_DIR}/DEBIAN/control"

dpkg-deb --build "${BUILD_DIR}" "${PACKAGE_NAME}.deb"
echo "Created ${PACKAGE_NAME}.deb successfully!"
