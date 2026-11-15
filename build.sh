#!/bin/bash
# Compila o Tella.  Uso:
#   ./build.sh            -> gera build/Tella.app
#   ./build.sh --install  -> gera, copia para /Applications e abre
#   ./build.sh --dmg      -> gera o instalador Tella-<versão>.dmg (ex.: Tella-1.4.dmg)
#
# O app sai "universal": roda em Macs com Apple Silicon e com Intel.
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

echo "🌐 Idiomas ($(ls -d Resources/*.lproj | wc -l | tr -d " "))…"
for L in Resources/*.lproj; do cp -R "$L" "$APP/Contents/Resources/"; done

echo "🔨 Compilando (Apple Silicon + Intel)…"
for ARCH in arm64 x86_64; do
  LOG="$TMP/swiftc-$ARCH.log"
  if ! swiftc -O -target "$ARCH-apple-macos13" \
      Sources/*.swift \
      -o "$TMP/Tella-$ARCH" \
      -framework Cocoa -framework ServiceManagement > "$LOG" 2>&1; then
    cat "$LOG"; exit 1
  fi
  # Avisos inofensivos do linker sobre uma biblioteca de compatibilidade sem a parte Intel.
  grep -v -e 'libswiftCompatibilityPacks' -e 'file missing arch' "$LOG" || true
done
lipo -create "$TMP/Tella-arm64" "$TMP/Tella-x86_64" -output "$APP/Contents/MacOS/Tella"

cp Info.plist "$APP/Contents/Info.plist"
# Assinatura: com um certificado de assinatura de código fixo (o primeiro válido do seu Chaves,
# ou o definido em TELLA_SIGN_ID), o macOS reconhece o app recompilado como o MESMO app e a
# permissão de Acessibilidade não se perde. Sem certificado, assina sem identidade ("-").
SIGN_ID="${TELLA_SIGN_ID:-$(security find-identity -v -p codesigning 2>/dev/null | awk -F'"' '/"/{print $2; exit}')}"
if [ -n "$SIGN_ID" ] && codesign --force --deep --sign "$SIGN_ID" "$APP" 2>/dev/null; then
  echo "🔏 Assinado com \"$SIGN_ID\""
else
  codesign --force --deep --sign - "$APP"
  echo "🔏 Assinado sem certificado (a permissão de Acessibilidade pode precisar ser liberada de novo)"
fi
echo "✅ Compilado: $APP"

case "${1:-}" in
  --install)
    pkill -x Tella 2>/dev/null || true
    # Espera a versão antiga fechar de verdade (senão o macOS só reativa a antiga)
    for _ in $(seq 1 30); do pgrep -x Tella >/dev/null || break; sleep 0.1; done
    pkill -9 -x Tella 2>/dev/null || true
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
