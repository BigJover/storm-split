#!/bin/sh
# Static check: type-checks src/ against Roblox's API. Catches type errors and unknown
# names; not misspelled Roblox property names (only a playtest catches those).
# Fails (exit 1) on any reported problem or a missing tool.
set -e
cd "$(dirname "$0")/.."
PATH="$HOME/.rokit/bin:$PATH"
for tool in rojo luau-lsp; do
  command -v "$tool" >/dev/null || { echo "check FAILED: $tool not found (run rokit install)"; exit 1; }
done
DEFS="${TMPDIR:-/tmp}/storm-split-globalTypes.d.luau"
[ -f "$DEFS" ] || curl -sSfL -o "$DEFS" \
  https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.None.d.luau
rojo sourcemap default.project.json -o sourcemap.json
OUT=$(luau-lsp analyze --definitions="$DEFS" --sourcemap=sourcemap.json --platform=roblox src 2>&1 \
  | grep -v -E '^\[(INFO|WARN)\]' || true)
if [ -n "$OUT" ]; then
  echo "$OUT"
  echo "check FAILED"
  exit 1
fi
echo "check done"
