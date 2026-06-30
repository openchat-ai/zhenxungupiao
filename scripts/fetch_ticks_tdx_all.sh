#!/bin/sh
# 通达信逐笔：仅当年（默认 2026）+ 日汇总
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
YEAR="${1:-2026}"
PY="$ROOT/scripts/fetch_tick_tdx_optional.py"
chmod +x "$PY" "$ROOT/scripts/prune_tick_hist.sh"

if ! command -v python3 >/dev/null 2>&1; then
  echo "SKIP: python3 not found" >&2
  exit 0
fi

python3 -c "import easy_tdx" 2>/dev/null || {
  echo "SKIP: pip install easy-tdx" >&2
  exit 0
}

"$ROOT/scripts/prune_tick_hist.sh" "$ROOT/research/archive/tick_hist" "$YEAR"
python3 "$PY" "$YEAR"
"$ROOT/scripts/tick_hist_to_daily.sh"
echo "OK tdx tick pipeline (year=$YEAR only)"
