#!/bin/bash
# Compila o Tella.  Uso:
#   ./build.sh            -> gera build/Tella.app
#   ./build.sh --install  -> gera, copia para /Applications e abre
#   ./build.sh --dmg      -> gera o instalador Tella-<versão>.dmg (ex.: Tella-1.3.dmg)
set -euo pipefail
cd "$(dirname "$0")"

APP="build/Tella.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Info.plist)
DMG="Tella-$VERSION.dmg"
TMP="build/tmp"
rm -rf build
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$TMP"

echo "🎨 Ícone…"
iconutil -c icns Resources/AppIcon.iconset -o "$APP/Contents/Resources/AppIcon.icns"

echo "🌐 Idiomas (pt-BR, en, es)…"
for L in Resources/*.lproj; do cp -R "$L" "$APP/Contents/Resources/"; done

echo "🔨 Compilando…"
swiftc -O -target arm64-apple-macos13 \
  Sources/main.swift \
  -o "$APP/Contents/MacOS/Tella" \
  -framework Cocoa -framework ServiceManagement

cp Info.plist "$APP/Contents/Info.plist"
codesign --force --deep --sign - "$APP"
echo "✅ Compilado: $APP"

case "${1:-}" in
  --install)
    pkill -x Tella 2>/dev/null || true
    rm -rf /Applications/Tella.app
    ditto "$APP" /Applications/Tella.app
    touch /Applications/Tella.app
    open /Applications/Tella.app
    echo "✅ Instalado em /Applications e aberto"
    ;;
  --dmg)
    echo "📦 Criando instalador DMG…"
    STAGE="$TMP/dmg"
    mkdir -p "$STAGE"
    ditto "$APP" "$STAGE/Tella.app"
    ln -s /Applications "$STAGE/Applications"
    rm -f "$DMG"
    hdiutil create -volname "Tella $VERSION" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null
    echo "✅ Instalador pronto: $(pwd)/$DMG"
    open -R "$DMG"
    ;;
esac
