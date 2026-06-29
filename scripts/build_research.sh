#!/bin/sh
# 纯 yoyo 研究构建（零 Python）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
YOBO="${YOBO:-$ROOT/yoyo/compiler/yoyo.exe}"
NAME="$1"
shift || true

RESEARCH_LIBS="$ROOT/yoyo/lib/fp.ty \
  $ROOT/yoyo/lib/params.ty \
  $ROOT/yoyo/lib/indicators.ty \
  $ROOT/yoyo/lib/perturbation.ty \
  $ROOT/yoyo/lib/news_eta.ty \
  $ROOT/yoyo/lib/psychology.ty \
  $ROOT/yoyo/lib/aggressive.ty \
  $ROOT/yoyo/lib/wuwen.ty \
  $ROOT/yoyo/ternary_signal.ty"

BACKTEST_LIBS="$ROOT/yoyo/lib/mem.ty \
  $ROOT/yoyo/lib/csv.ty"

case "$NAME" in
  walk)
    SRC="$ROOT/build/walk_forward.ty"
    OUT="$ROOT/build/walk_forward.exe"
    cat $RESEARCH_LIBS \
        "$ROOT/yoyo/research/walk_forward.ty" > "$SRC"
    ;;
  butterfly)
    SRC="$ROOT/build/butterfly_demo.ty"
    OUT="$ROOT/build/butterfly_demo.exe"
    cat $RESEARCH_LIBS \
        "$ROOT/yoyo/research/butterfly_demo.ty" > "$SRC"
    ;;
  hold)
    SRC="$ROOT/build/hold_ratio.ty"
    OUT="$ROOT/build/hold_ratio.exe"
    cat $RESEARCH_LIBS \
        "$ROOT/yoyo/research/hold_ratio.ty" > "$SRC"
    ;;
  verify)
    SRC="$ROOT/build/verify_archive.ty"
    OUT="$ROOT/build/verify_archive.exe"
    cp "$ROOT/yoyo/research/verify_archive.ty" "$SRC"
    ;;
  psychology)
    SRC="$ROOT/build/psychology_demo.ty"
    OUT="$ROOT/build/psychology_demo.exe"
    cat $RESEARCH_LIBS \
        "$ROOT/yoyo/research/psychology_demo.ty" > "$SRC"
    ;;
  tick)
    SRC="$ROOT/build/tick_demo.ty"
    OUT="$ROOT/build/tick_demo.exe"
    cat $RESEARCH_LIBS \
        "$ROOT/build/tick_embed.ty" \
        "$ROOT/yoyo/research/tick_demo.ty" > "$SRC"
    ;;
  news)
    SRC="$ROOT/build/news_demo.ty"
    OUT="$ROOT/build/news_demo.exe"
    cat $RESEARCH_LIBS \
        "$ROOT/build/news_embed.ty" \
        "$ROOT/yoyo/research/news_demo.ty" > "$SRC"
    ;;
  verify-v3)
    SRC="$ROOT/build/verify_v3.ty"
    OUT="$ROOT/build/verify_v3.exe"
    cp "$ROOT/yoyo/research/verify_v3.ty" "$SRC"
    ;;
  verify-v2)
    SRC="$ROOT/build/verify_v2.ty"
    OUT="$ROOT/build/verify_v2.exe"
    cp "$ROOT/yoyo/research/verify_v2.ty" "$SRC"
    ;;
  backtest-v2)
    SRC="$ROOT/build/backtest_v2.ty"
    OUT="$ROOT/build/backtest_v2.exe"
    cat $RESEARCH_LIBS $BACKTEST_LIBS \
        "$ROOT/yoyo/research/backtest_v2.ty" > "$SRC"
    ;;
  *)
    echo "usage: $0 {walk|butterfly|hold|psychology|tick|news|verify|verify-v2|verify-v3|backtest-v2}"
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
