#!/bin/sh
# 删除 tick_hist 中非指定年份的文件（默认仅保留 2026）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIR="${1:-$ROOT/research/archive/tick_hist}"
YEAR="${2:-2026}"
PREFIX="${YEAR}"

n=0
for f in "$DIR"/tick_*_*.csv; do
  [ -f "$f" ] || continue
  base=$(basename "$f" .csv)
  dpart=${base##*_}
  case "$dpart" in
    ${PREFIX}*) ;;
    *)
      rm -f "$f"
      n=$((n + 1))
      ;;
  esac
done
echo "OK pruned $n files (keep year=$YEAR in $DIR)"
