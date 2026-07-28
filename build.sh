#!/bin/sh
set -e

swift build -c release

cp .build/release/se /usr/local/bin/se

# Perform ad-hoc codesign on the installed destination binary on macOS
if [ "$(uname)" = "Darwin" ]; then
    codesign -f -s - /usr/local/bin/se
fi