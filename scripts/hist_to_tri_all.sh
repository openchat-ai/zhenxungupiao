#!/bin/sh
# 一次性：hist_*.csv → signal_*.tri（三进制存档，仅 research 导出）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ARCH="$ROOT/research/archive"
AWK="$ROOT/scripts/hist_to_tri.awk"

mkdir -p "$ARCH"
for f in "$ARCH"/hist_*.csv; do
  base=$(basename "$f" .csv)
  code=${base#hist_}
  out="$ARCH/signal_${code}.tri"
  awk -f "$AWK" "$f" > "$out"
  bytes=$(wc -c < "$out")
  echo "OK $out ($bytes bytes)"
done
