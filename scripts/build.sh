#!/bin/sh
# 合并 yoyo 模块为单一 .ty（无链接器、无外部库），供 yoyo.exe 一次编译。
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/build/stock_app.ty"
YOBO="$ROOT/yoyo/compiler/yoyo.exe"
mkdir -p "$ROOT/build"

cat \
  "$ROOT/yoyo/lib/fp.ty" \
  "$ROOT/yoyo/lib/indicators.ty" \
  "$ROOT/yoyo/ternary_signal.ty" \
  "$ROOT/yoyo/stock_app.ty" \
  > "$OUT"

echo "Wrote $OUT"

if [ -x "$YOBO" ] || command -v wine >/dev/null 2>&1; then
  EXE="$ROOT/build/stock_app.exe"
  if command -v wine >/dev/null 2>&1; then
    wine "$YOBO" "$OUT" "$EXE"
  else
    "$YOBO" "$OUT" "$EXE"
  fi
  echo "Compiled $EXE"
else
  echo "Skip compile: need Windows or wine to run yoyo.exe"
fi
