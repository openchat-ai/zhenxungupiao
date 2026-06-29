#!/bin/sh
# 延伸八股日线至今日（可选 Python）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PY="$ROOT/scripts/export_hist_extend_optional.py"
chmod +x "$PY"
python3 -c "import akshare" 2>/dev/null || { echo "SKIP: pip install akshare" >&2; exit 0; }
python3 "$PY"
