#!/bin/sh
# 合并 yoyo.ty + Phase 2/3/4 补丁 → build/yoyo_merged.ty（零外部依赖）
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="$ROOT/yoyo/compiler/yoyo.ty"
OUT="$ROOT/build/yoyo_merged.ty"
PATCH_D="$ROOT/yoyo/compiler/patches/phase2_dispatch.ty"
PATCH_F="$ROOT/yoyo/compiler/patches/phase2_emit.ty"
PATCH_E="$ROOT/yoyo/compiler/patches/phase3_elf.ty"
PATCH_G="$ROOT/yoyo/compiler/patches/phase4_emit.ty"
MARKER="; H_4C: reset scanner state and loop back to H_01"

mkdir -p "$ROOT/build"
awk -v patch="$PATCH_D" -v mark="$MARKER" '
  index($0, mark) { while ((getline line < patch) > 0) print line; close(patch) }
  { print }
' "$BASE" > "$OUT"

{
  echo ""
  echo "; === merged patches: float + elf + gui ==="
  cat "$PATCH_F" "$PATCH_E" "$PATCH_G"
} >> "$OUT"

echo "Merged: $OUT ($(wc -l < "$OUT") lines)"
