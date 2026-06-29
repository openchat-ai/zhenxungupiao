#!/bin/sh
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="$1"
YOBO="${YOBO:-$ROOT/yoyo/compiler/yoyo.exe}"
OUT_TY="$ROOT/build/${NAME}.ty"
OUT_EXE="$ROOT/build/${NAME}.exe"
ENTRY="$ROOT/yoyo/${NAME}.ty"

mkdir -p "$ROOT/build"
cat \
  "$ROOT/yoyo/lib/fp.ty" \
  "$ROOT/yoyo/lib/params.ty" \
  "$ROOT/yoyo/lib/indicators.ty" \
  "$ROOT/yoyo/lib/perturbation.ty" \
  "$ROOT/yoyo/lib/news_eta.ty" \
  "$ROOT/yoyo/lib/psychology.ty" \
  "$ROOT/yoyo/lib/aggressive.ty" \
  "$ROOT/yoyo/lib/wuwen.ty" \
  "$ROOT/yoyo/ternary_signal.ty" \
  "$ROOT/yoyo/lib/chart.ty" \
  "$ENTRY" \
  > "$OUT_TY"
echo "Wrote $OUT_TY"

if command -v wine >/dev/null 2>&1; then
  wine "$YOBO" "$OUT_TY" "$OUT_EXE" && echo "Built $OUT_EXE"
else
  echo "Skip compile: install Wine to run yoyo.exe on Linux"
fi
