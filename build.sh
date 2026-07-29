#!/bin/sh
set -e

swift build -c release

cp .build/release/zago /usr/local/bin/zago

# Perform ad-hoc codesign on the installed destination binary on macOS
if [ "$(uname)" = "Darwin" ]; then
    codesign -f -s - /usr/local/bin/zago
fi