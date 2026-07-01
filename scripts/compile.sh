#!/bin/sh
# 编译 .ty → 可执行文件
# Linux:  build/tyrun（原生 ELF）
# Windows: yoyo/compiler/yoyo.exe（原生 PE）
#
# 用法: ./scripts/compile.sh flow_signal
#       ./scripts/compile.sh signal
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
YOBO="${YOBO:-$ROOT/yoyo/compiler/yoyo.exe}"
TYRUN="$ROOT/build/tyrun"
BUILD="$ROOT/build"
mkdir -p "$BUILD"

ensure_tyrun() {
  if [ ! -x "$TYRUN" ] || [ "$ROOT/yoyo/compiler/tyrun.c" -nt "$TYRUN" ]; then
    echo "gcc -O2 -o build/tyrun yoyo/compiler/tyrun.c"
    gcc -O2 -o "$TYRUN" "$ROOT/yoyo/compiler/tyrun.c"
  fi
}

try_yoyo_exe() {
  SRC="$1"
  OUT="$2"
  if [ ! -f "$YOBO" ]; then return 1; fi
  chmod +x "$YOBO" 2>/dev/null || true
  if command -v wine >/dev/null 2>&1; then
    if WINEDEBUG=-all wine "$YOBO" "$SRC" "$OUT" 2>/dev/null && [ -f "$OUT" ]; then
      echo "OK $OUT (yoyo.exe via Wine)"
      return 0
    fi
  elif "$YOBO" "$SRC" "$OUT" 2>/dev/null && [ -f "$OUT" ]; then
    echo "OK $OUT (yoyo.exe native)"
    return 0
  fi
  return 1
}

run_ty() {
  SRC="$1"
  OUT="$2"
  if try_yoyo_exe "$SRC" "$OUT"; then return 0; fi
  ensure_tyrun
  echo "tyrun -o $OUT $SRC"
  "$TYRUN" -o "$OUT" "$SRC"
}

RESEARCH_LIBS="
  $ROOT/yoyo/lib/fp.ty
  $ROOT/yoyo/lib/params.ty
  $ROOT/yoyo/lib/indicators.ty
  $ROOT/yoyo/lib/perturbation.ty
  $ROOT/yoyo/lib/news_eta.ty
  $ROOT/yoyo/lib/psychology.ty
  $ROOT/yoyo/lib/aggressive.ty
  $ROOT/yoyo/lib/wuwen.ty
  $ROOT/yoyo/ternary_signal.ty
"

TARGET="${1:-?}"
shift || true

case "$TARGET" in
  signal)
    SRC="$BUILD/ternary_signal.ty"
    cat $RESEARCH_LIBS > "$SRC"
    run_ty "$SRC" "$BUILD/ternary_signal.exe"
    ;;
  stock)
    SRC="$BUILD/stock_app.ty"
    cat $RESEARCH_LIBS "$ROOT/yoyo/lib/chart.ty" "$ROOT/yoyo/stock_app.ty" > "$SRC"
    run_ty "$SRC" "$BUILD/stock_app.exe"
    ;;
  stock_gui)
    SRC="$BUILD/stock_gui.ty"
    cat $RESEARCH_LIBS "$ROOT/yoyo/lib/chart.ty" "$ROOT/yoyo/stock_gui.ty" > "$SRC"
    run_ty "$SRC" "$BUILD/stock_gui.exe"
    ;;
  flow_signal)
    if [ ! -f "$BUILD/flow_embed.ty" ]; then
      chmod +x "$ROOT/scripts/flow_to_embed.sh" 2>/dev/null || true
      "$ROOT/scripts/flow_to_embed.sh" \
        "${FEAT:-$ROOT/research/archive/tick_features_daily.csv}" \
        "$BUILD/flow_embed.ty" "${CODE:-600036}"
    fi
    SRC="$BUILD/flow_signal_demo.ty"
    cat \
      "$ROOT/yoyo/lib/fp.ty" \
      "$ROOT/yoyo/lib/params.ty" \
      "$ROOT/yoyo/lib/flow_signal.ty" \
      "$BUILD/flow_embed.ty" \
      "$ROOT/yoyo/research/flow_signal_demo.ty" > "$SRC"
    run_ty "$SRC" "$BUILD/flow_signal_demo.exe"
    [ -x "$BUILD/flow_signal_demo" ] && echo "also: $BUILD/flow_signal_demo (Linux ELF)"
    ;;
  tick_demo)
    if [ ! -f "$BUILD/tick_embed.ty" ]; then
      chmod +x "$ROOT/scripts/tick_to_embed.sh" 2>/dev/null || true
      "$ROOT/scripts/tick_to_embed.sh" \
        "$ROOT/research/archive/tick_daily_summary.csv" \
        "$BUILD/tick_embed.ty" "${CODE:-600519}"
    fi
    SRC="$BUILD/tick_demo.ty"
    cat $RESEARCH_LIBS "$BUILD/tick_embed.ty" "$ROOT/yoyo/research/tick_demo.ty" > "$SRC"
    run_ty "$SRC" "$BUILD/tick_demo.exe"
    ;;
  butterfly|psychology|walk)
    case "$TARGET" in
      butterfly) E="$ROOT/yoyo/research/butterfly_demo.ty"; O="$BUILD/butterfly_demo" ;;
      psychology) E="$ROOT/yoyo/research/psychology_demo.ty"; O="$BUILD/psychology_demo" ;;
      walk) E="$ROOT/yoyo/research/walk_forward.ty"; O="$BUILD/walk_forward" ;;
    esac
    SRC="$O.ty"
    cat $RESEARCH_LIBS "$E" > "$SRC"
    run_ty "$SRC" "$O.exe"
    ;;
  custom)
    SRC="${1:?need source .ty}"; OUT="${2:?need output path}"
    run_ty "$SRC" "$OUT"
    ;;
  tyrun)
    ensure_tyrun
    echo "OK $TYRUN"
    ;;
  *)
    cat <<EOF
用法: ./scripts/compile.sh <target>

  flow_signal   逐笔买/卖指示
  signal        七票决策核心
  stock         App 主程序
  stock_gui     GUI 版
  tick_demo     第 7 票演示
  butterfly / psychology / walk
  tyrun         仅构建 Linux 原生 tyrun
  custom <in.ty> <out>

Linux  : tyrun → 原生 ELF（build/flow_signal_demo）
Windows: yoyo.exe → 原生 PE（build/flow_signal_demo.exe）
EOF
    exit 1
    ;;
esac
