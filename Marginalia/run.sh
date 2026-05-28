#!/usr/bin/env bash
# Build Marginalia, package it into a minimal .app bundle, and launch.
# Usage: ./run.sh             — build + launch
#        ./run.sh build       — build only (no launch)
#        ./run.sh release     — build optimized release configuration

set -euo pipefail

cd "$(dirname "$0")"

CONFIG="debug"
LAUNCH=1
case "${1:-}" in
    build)   LAUNCH=0 ;;
    release) CONFIG="release" ;;
    "")      ;;
    *)       echo "Bilinmeyen argüman: $1"; exit 1 ;;
esac

echo "▸ Derleniyor ($CONFIG)…"
if [[ "$CONFIG" == "release" ]]; then
    swift build -c release
else
    swift build
fi

BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path)"
BIN_PATH="$BIN_DIR/Marginalia"
RES_BUNDLE="$BIN_DIR/Marginalia_Marginalia.bundle"
APP_DIR="$PWD/Marginalia.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "▸ Bundle hazırlanıyor: $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"
cp "$BIN_PATH" "$MACOS/Marginalia"
cp "Sources/Marginalia/Resources/Info.plist" "$CONTENTS/Info.plist"

# SwiftPM emits a separate resource bundle that Bundle.module looks up
# next to the executable. Copy it alongside the binary.
if [[ -d "$RES_BUNDLE" ]]; then
    cp -R "$RES_BUNDLE" "$MACOS/"
fi

# PkgInfo for proper app type identification.
printf 'APPL????' > "$CONTENTS/PkgInfo"

if [[ "$LAUNCH" -eq 1 ]]; then
    echo "▸ Açılıyor…"
    open "$APP_DIR"
else
    echo "✓ Bundle hazır: $APP_DIR"
fi
