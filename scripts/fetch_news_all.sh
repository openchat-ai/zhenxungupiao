#!/bin/sh
# 八股新闻抓取（可选 Python；固化进 research/archive/news_*.csv）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PY="$ROOT/scripts/export_news_optional.py"
chmod +x "$PY"

if ! command -v python3 >/dev/null 2>&1; then
  echo "SKIP: python3 not found (optional research tool)" >&2
  exit 0
fi

python3 "$PY" "$@"
# Python 已写 news_daily_eta.csv；awk 仅作备用
if [ ! -s "$ROOT/research/archive/news_daily_eta.csv" ]; then
  "$ROOT/scripts/news_to_eta_daily.sh"
fi
echo "OK news pipeline"
