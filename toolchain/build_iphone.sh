#!/bin/bash
set -e

# Directories
SDK_PATH="sdk/iPhoneOS6.1.sdk"
OUTPUT_DIR="deploy"
mkdir -p "$OUTPUT_DIR"

if [ ! -d "$SDK_PATH" ]; then
    echo "Error: iOS SDK not found at $SDK_PATH"
    exit 1
fi

echo "=== Building Hello World for iPhone 4S ==="
clang -O3 \
  -arch armv7 \
  -isysroot "$SDK_PATH" \
  -miphoneos-version-min=6.0 \
  -target armv7-apple-ios6.0 \
  -o "$OUTPUT_DIR/hello" \
  hello.c

echo "Signing Hello World..."
codesign -f -s - "$OUTPUT_DIR/hello"

echo "=== Building TinyStories for iPhone 4S ==="
clang -O3 \
  -arch armv7 \
  -isysroot "$SDK_PATH" \
  -miphoneos-version-min=6.0 \
  -target armv7-apple-ios6.0 \
  -o "$OUTPUT_DIR/tinystories" \
  runtime/run.c \
  -lm

echo "Signing TinyStories..."
codesign -f -s - "$OUTPUT_DIR/tinystories"

echo "=== Build Complete! ==="
ls -la "$OUTPUT_DIR"
