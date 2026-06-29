#!/bin/sh
# 从 tick_daily_summary.csv 生成 yoyo 嵌入片段（主动买占比 → state[50]）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CSV="${1:-$ROOT/research/archive/tick_daily_summary.csv}"
OUT="${2:-$ROOT/build/tick_embed.ty}"
CODE="${3:-600519}"

mkdir -p "$(dirname "$OUT")"
PCT=$(awk -F, -v c="$CODE" '$2==c {print int($3+0.5); exit}' "$CSV")
[ -n "$PCT" ] || PCT=50

{
  echo "; auto-generated from $CSV for $CODE"
  printf "30 32 %02x\n" "$PCT"   # state[50] = active_buy_pct (0x32=50)
} > "$OUT"
echo "Wrote $OUT active_buy_pct=$PCT"
