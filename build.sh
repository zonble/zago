#!/bin/sh 

swift build -c release --disable-sandbox
cp .build/release/se /usr/local/bin/se