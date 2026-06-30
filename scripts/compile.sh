#!/bin/sh
# 直接用 yoyo.exe 编译 — 不依赖 make
# 用法: ./scripts/compile.sh <target>
# 例:   ./scripts/compile.sh flow_signal
#       ./scripts/compile.sh signal
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
YOBO="${YOBO:-$ROOT/yoyo/compiler/yoyo.exe}"
BUILD="$ROOT/build"
mkdir -p "$BUILD"

run_yoyo() {
  SRC="$1"
  OUT="$2"
  if [ ! -f "$YOBO" ]; then
    echo "error: $YOBO not found" >&2
    exit 1
  fi
  chmod +x "$YOBO" 2>/dev/null || true
  echo "yoyo.exe $SRC $OUT"
  if command -v wine >/dev/null 2>&1; then
    wine "$YOBO" "$SRC" "$OUT"
  else
    "$YOBO" "$SRC" "$OUT"
  fi
  echo "OK $OUT"
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
    run_yoyo "$SRC" "$BUILD/ternary_signal.exe"
    ;;
  stock)
    SRC="$BUILD/stock_app.ty"
    cat $RESEARCH_LIBS "$ROOT/yoyo/lib/chart.ty" "$ROOT/yoyo/stock_app.ty" > "$SRC"
    run_yoyo "$SRC" "$BUILD/stock_app.exe"
    ;;
  stock_gui)
    SRC="$BUILD/stock_gui.ty"
    cat $RESEARCH_LIBS "$ROOT/yoyo/lib/chart.ty" "$ROOT/yoyo/stock_gui.ty" > "$SRC"
    run_yoyo "$SRC" "$BUILD/stock_gui.exe"
    ;;
  flow_signal)
    # 先写入逐笔数据（可用 ./scripts/flow_to_embed.sh 单独跑）
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
    run_yoyo "$SRC" "$BUILD/flow_signal_demo.exe"
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
    run_yoyo "$SRC" "$BUILD/tick_demo.exe"
    ;;
  butterfly)
    SRC="$BUILD/butterfly_demo.ty"
    cat $RESEARCH_LIBS "$ROOT/yoyo/research/butterfly_demo.ty" > "$SRC"
    run_yoyo "$SRC" "$BUILD/butterfly_demo.exe"
    ;;
  psychology)
    SRC="$BUILD/psychology_demo.ty"
    cat $RESEARCH_LIBS "$ROOT/yoyo/research/psychology_demo.ty" > "$SRC"
    run_yoyo "$SRC" "$BUILD/psychology_demo.exe"
    ;;
  walk)
    SRC="$BUILD/walk_forward.ty"
    cat $RESEARCH_LIBS "$ROOT/yoyo/research/walk_forward.ty" > "$SRC"
    run_yoyo "$SRC" "$BUILD/walk_forward.exe"
    ;;
  custom)
    # ./scripts/compile.sh custom build/my_app.ty build/my_app.exe
    SRC="${1:?need source .ty}"; OUT="${2:?need output .exe}"
    run_yoyo "$SRC" "$OUT"
    ;;
  *)
    cat <<EOF
用法: ./scripts/compile.sh <target>

目标（合并 lib 后调用 yoyo.exe）:
  signal        七票决策核心 → build/ternary_signal.exe
  stock         App 主程序   → build/stock_app.exe
  stock_gui     GUI 版       → build/stock_gui.exe
  flow_signal   逐笔买/卖指示 → build/flow_signal_demo.exe
  tick_demo     第 7 票演示  → build/tick_demo.exe
  butterfly     蝴蝶效应演示
  psychology    心理学票演示
  walk          五票 walk-forward
  custom <in.ty> <out.exe>  已合并好的 .ty 直接编译

环境变量:
  YOBO=/path/yoyo.exe   编译器路径（默认 yoyo/compiler/yoyo.exe）
  CODE=600036           flow_signal / tick_demo 嵌入哪只股票

等价于（Windows 本机）:
  yoyo\\compiler\\yoyo.exe build\\flow_signal_demo.ty build\\flow_signal_demo.exe
EOF
    exit 1
    ;;
esac
