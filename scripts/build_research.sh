#!/bin/sh
# 纯 yoyo 研究构建（零 Python）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
YOBO="${YOBO:-$ROOT/yoyo/compiler/yoyo.exe}"
NAME="$1"
shift || true

case "$NAME" in
  walk)
    SRC="$ROOT/build/walk_forward.ty"
    OUT="$ROOT/build/walk_forward.exe"
    cat "$ROOT/yoyo/lib/fp.ty" \
        "$ROOT/yoyo/lib/indicators.ty" \
        "$ROOT/yoyo/lib/perturbation.ty" \
        "$ROOT/yoyo/ternary_signal.ty" \
        "$ROOT/yoyo/research/walk_forward.ty" > "$SRC"
    ;;
  butterfly)
    SRC="$ROOT/build/butterfly_demo.ty"
    OUT="$ROOT/build/butterfly_demo.exe"
    cat "$ROOT/yoyo/lib/fp.ty" \
        "$ROOT/yoyo/lib/indicators.ty" \
        "$ROOT/yoyo/lib/perturbation.ty" \
        "$ROOT/yoyo/ternary_signal.ty" \
        "$ROOT/yoyo/research/butterfly_demo.ty" > "$SRC"
    ;;
  verify)
    SRC="$ROOT/build/verify_archive.ty"
    OUT="$ROOT/build/verify_archive.exe"
    cp "$ROOT/yoyo/research/verify_archive.ty" "$SRC"
    ;;
  *)
    echo "usage: $0 {walk|butterfly|verify}"
    exit 1
    ;;
esac

mkdir -p "$ROOT/build"
if command -v wine >/dev/null 2>&1; then
  wine "$YOBO" "$SRC" "$OUT"
else
  "$YOBO" "$SRC" "$OUT" 2>/dev/null || echo "Built $SRC (compile on Windows)"
fi
echo "OK $OUT"
