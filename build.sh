#!/bin/bash
# Compila o Tella.  Uso:
#   ./build.sh            -> gera build/Tella.app
#   ./build.sh --install  -> gera, copia para /Applications e abre
#   ./build.sh --dmg      -> gera o instalador Tella.dmg
set -euo pipefail
cd "$(dirname "$0")"

APP="build/Tella.app"
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
    ln -s /Applications "$STAGE/Aplicativos"
    rm -f Tella.dmg
    hdiutil create -volname "Tella" -srcfolder "$STAGE" -ov -format UDZO Tella.dmg >/dev/null
    echo "✅ Instalador pronto: $(pwd)/Tella.dmg"
    open -R Tella.dmg
    ;;
esac
