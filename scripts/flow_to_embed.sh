#!/bin/sh
# 从 tick_features_daily.csv 生成 yoyo 嵌入（主动买 + 上午/下午分化）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FEAT="${1:-$ROOT/research/archive/tick_features_daily.csv}"
OUT="${2:-$ROOT/build/flow_embed.ty}"
CODE="${3:-600519}"
DATE="${4:-}"

mkdir -p "$(dirname "$OUT")"

if [ -n "$DATE" ]; then
  ROW=$(awk -F, -v c="$CODE" -v d="$DATE" '$2==c && $1==d {print; exit}' "$FEAT")
else
  ROW=$(awk -F, -v c="$CODE" '$2==c {last=$0} END{print last}' "$FEAT")
fi

if [ -n "$ROW" ]; then
  BUY=$(echo "$ROW" | awk -F, '{printf "%d", $3+0.5}')
  DELTA=$(echo "$ROW" | awk -F, '{printf "%d", $11+50+0.5}')
  DT=$(echo "$ROW" | awk -F, '{print $1}')
else
  CSV="$ROOT/research/archive/tick_daily_summary.csv"
  BUY=$(awk -F, -v c="$CODE" '$2==c {print int($3+0.5); exit}' "$CSV")
  DELTA=50
  DT="unknown"
fi
[ -n "$BUY" ] || BUY=50

{
  echo "; auto-generated from $FEAT for $CODE date=$DT"
  printf "30 32 %02x\n" "$BUY"   # state[50] active_buy_pct
  printf "30 33 %02x\n" "$DELTA" # state[51] am_pm_delta + 50
  echo "30 34 00"                # state[52] mode: 0=flow_pure 1=flow_delta
} > "$OUT"

echo "Wrote $OUT buy=$BUY% delta_offset=$DELTA (date=$DT)"
