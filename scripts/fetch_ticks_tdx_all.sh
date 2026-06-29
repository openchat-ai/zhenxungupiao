#!/bin/sh
# 通达信历史逐笔批量抓取 + 日汇总（可选 Python）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DAYS="${1:-10}"
PY="$ROOT/scripts/fetch_tick_tdx_optional.py"
chmod +x "$PY"

if ! command -v python3 >/dev/null 2>&1; then
  echo "SKIP: python3 not found" >&2
  exit 0
fi

python3 -c "import easy_tdx" 2>/dev/null || {
  echo "SKIP: pip install easy-tdx" >&2
  exit 0
}

python3 "$PY" "$DAYS"
"$ROOT/scripts/tick_hist_to_daily.sh"
echo "OK tdx tick pipeline"
