#!/bin/sh
# 一次性：hist + tick → flow_v5_*.tri（2026 tick 窗口，仅导出期）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="$ROOT/research/archive"
AWK="$ROOT/scripts/hist_to_tri_v5.awk"
TICK="$ARCH/tick_hist_daily.csv"
TAIL="$ARCH/tick_tail_daily.csv"

mkdir -p "$ARCH"
for f in "$ARCH"/hist_*.csv; do
  base=$(basename "$f" .csv)
  code=${base#hist_}
  out="$ARCH/flow_v5_${code}.tri"
  awk -v code="$code" -v tickfile="$TICK" -v tailfile="$TAIL" \
      -f "$AWK" "$f" > "$out"
  bytes=$(wc -c < "$out")
  echo "OK $out ($bytes bytes, n=$(( (bytes - 6) / 5 )))"
done
