#!/bin/bash
# Build ellamma.dylib for ARMv7 iOS 6.1
# MobileSubstrate tweak: TinyStories + VoiceServices TTS

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDK="$PROJECT_ROOT/sdk/iPhoneOS6.1.sdk"
OUT="$PROJECT_ROOT/deploy/ellamma.dylib"

echo "=== Building ellamma MobileSubstrate tweak ==="

clang++ \
  -arch armv7 \
  -isysroot "$SDK" \
  -miphoneos-version-min=6.0 \
  -target armv7-apple-ios6.0 \
  -std=c++11 \
  -fmodules \
  -dynamiclib \
  -undefined dynamic_lookup \
  -install_name /Library/MobileSubstrate/DynamicLibraries/ellamma.dylib \
  -framework Foundation \
  -framework UIKit \
  -framework CoreGraphics \
  -framework AVFoundation \
  -rpath /usr/lib \
  -L"$SDK/usr/lib" \
  -o "$OUT" \
  "$SCRIPT_DIR/Tweak.mm"

echo "Signing..."
codesign -f -s - "$OUT"

echo "Done: $OUT"
file "$OUT"
