#!/bin/bash
# Builds Sources/*.swift into a universal (arm64 + x86_64) "HDR Shield.app".
# Requires Xcode or the Command Line Tools. Usage: bash build.sh
#
# 把 Sources/*.swift 编译并打包成通用二进制(arm64 + x86_64)的「HDR Shield.app」。
# 需要 Xcode 或 Command Line Tools。用法:bash build.sh
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="HDR Shield"          # Shown in Finder and the menu bar / Finder 和菜单中显示的名字
EXECUTABLE="HDRShield"         # Binary name inside the bundle (no spaces) / 包内可执行文件名(无空格)
BUNDLE_ID="com.latecommitoffice.hdrshield"
APP="$APP_NAME.app"
MIN_OS="13.0"
VERSION="1.0"
BUILD="1"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# Compile once per architecture, then merge with lipo.
# 每个架构各编译一次,再用 lipo 合并。
for ARCH in arm64 x86_64; do
    swiftc -O -module-name "$EXECUTABLE" -target "$ARCH-apple-macos$MIN_OS" \
        Sources/*.swift -o "$TMP/$EXECUTABLE-$ARCH"
done
lipo -create "$TMP/$EXECUTABLE-arm64" "$TMP/$EXECUTABLE-x86_64" \
    -output "$APP/Contents/MacOS/$EXECUTABLE"

# App icon: turn Resources/AppIcon.png (1024×1024) into AppIcon.icns. Skipped if the PNG is missing.
# app 图标:把 Resources/AppIcon.png(1024×1024)转换成 AppIcon.icns。没有这个 PNG 时跳过。
ICON_SRC="Resources/AppIcon.png"
ICON_PLIST=""
if [[ -f "$ICON_SRC" ]]; then
    ICONSET="$TMP/AppIcon.iconset"
    mkdir -p "$ICONSET"
    for SIZE in 16 32 128 256 512; do
        sips -z "$SIZE" "$SIZE" "$ICON_SRC" --out "$ICONSET/icon_${SIZE}x${SIZE}.png" >/dev/null
        sips -z "$((SIZE * 2))" "$((SIZE * 2))" "$ICON_SRC" --out "$ICONSET/icon_${SIZE}x${SIZE}@2x.png" >/dev/null
    done
    iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
    ICON_PLIST="<key>CFBundleIconFile</key>
    <string>AppIcon</string>"
else
    echo "warning: $ICON_SRC not found, building without an app icon" >&2
fi

cat > "$APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$EXECUTABLE</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleVersion</key>
    <string>$BUILD</string>
    <key>LSMinimumSystemVersion</key>
    <string>$MIN_OS</string>
    <key>LSUIElement</key>
    <true/>
    $ICON_PLIST
</dict>
</plist>
EOF

# Ad-hoc signature; needed for the login item.
# 本地临时签名,登录项功能需要。
codesign --force --sign - "$APP"

echo "Built: $(pwd)/$APP ($(lipo -archs "$APP/Contents/MacOS/$EXECUTABLE"))"
