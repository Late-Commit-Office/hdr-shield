#!/bin/bash
# Builds HDRClamp.swift into a universal (arm64 + x86_64) HDRClamp.app.
# Requires Xcode or the Command Line Tools. Usage: bash build.sh
#
# 把 HDRClamp.swift 编译并打包成通用二进制(arm64 + x86_64)的 HDRClamp.app。
# 需要 Xcode 或 Command Line Tools。用法:bash build.sh
set -euo pipefail
cd "$(dirname "$0")"

APP="HDRClamp.app"
MIN_OS="13.0"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"

# Compile once per architecture, then merge with lipo.
# 每个架构各编译一次,再用 lipo 合并。
for ARCH in arm64 x86_64; do
    swiftc -O -target "$ARCH-apple-macos$MIN_OS" HDRClamp.swift -o "$TMP/HDRClamp-$ARCH"
done
lipo -create "$TMP/HDRClamp-arm64" "$TMP/HDRClamp-x86_64" -output "$APP/Contents/MacOS/HDRClamp"

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>local.hdrclamp</string>
    <key>CFBundleName</key>
    <string>HDRClamp</string>
    <key>CFBundleExecutable</key>
    <string>HDRClamp</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>$MIN_OS</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Ad-hoc signature; needed for the login item.
# 本地临时签名,登录项功能需要。
codesign --force --sign - "$APP"

echo "Built: $(pwd)/$APP ($(lipo -archs "$APP/Contents/MacOS/HDRClamp"))"
