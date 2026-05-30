#!/bin/bash
# build_and_inject.sh
# Запускать на маке с Xcode: ./build_and_inject.sh
# Собирает RXKeySystem.dylib и вставляет его в IPA рядом с ___RXTikTok.dylib

set -e

IPA="Mytiktalkfromscratch_deobfuscated.ipa"
SRC_DIR="RXKeySystem_src"
DYLIB_NAME="RXKeySystem.dylib"
INJECT_PATH="Payload/TikTok.app/Frameworks/$DYLIB_NAME"
TMP_DIR=$(mktemp -d)
OUT_IPA="Mytiktalkfromscratch_deobf_keyed.ipa"

echo "=== RXKeySystem Builder ==="
echo ""

# Шаг 1: Компилируем
echo "[1/3] Компилируем $DYLIB_NAME..."

xcrun -sdk iphoneos clang \
    -arch arm64 \
    -miphoneos-version-min=14.0 \
    -fobjc-arc \
    -fmodules \
    -O2 \
    -dynamiclib \
    -framework Foundation \
    -framework UIKit \
    -framework Security \
    -install_name @rpath/$DYLIB_NAME \
    "$SRC_DIR/RXKeyManager.m" \
    "$SRC_DIR/RXActivationViewController.m" \
    -o "$TMP_DIR/$DYLIB_NAME"

echo "    ✓ Собрано: $TMP_DIR/$DYLIB_NAME"
echo "    Размер: $(du -sh "$TMP_DIR/$DYLIB_NAME" | cut -f1)"

# Шаг 2: Распаковываем IPA, вставляем dylib, запаковываем обратно
echo ""
echo "[2/3] Вставляем в IPA..."

cp "$IPA" "$TMP_DIR/work.ipa"
cd "$TMP_DIR"
mkdir -p unpacked
cd unpacked
unzip -q "../work.ipa"

# Копируем dylib на место
cp "../$DYLIB_NAME" "$INJECT_PATH"
echo "    ✓ Вставлено: $INJECT_PATH"

# Запаковываем обратно
cd "$TMP_DIR/unpacked"
zip -qr "$TMP_DIR/$OUT_IPA" Payload/
cd -

# Шаг 3: Копируем результат
echo ""
echo "[3/3] Финализируем..."
cp "$TMP_DIR/$OUT_IPA" "$(dirname "$0")/$OUT_IPA"

# Чистим
rm -rf "$TMP_DIR"

echo ""
echo "=== Готово! ==="
echo "Файл: $OUT_IPA"
echo ""
echo "Примечание: после вставки нужен ресайн через:"
echo "  codesign -f -s 'iPhone Developer: ...' Payload/TikTok.app/Frameworks/$DYLIB_NAME"
echo "  или используй AltStore / Sideloadly"
