#!/bin/sh
# Static check: type-checks src/ against Roblox's API. Catches type errors and unknown
# names; not misspelled Roblox property names (only a playtest catches those).
set -e
cd "$(dirname "$0")/.."
DEFS="${TMPDIR:-/tmp}/storm-split-globalTypes.d.luau"
[ -f "$DEFS" ] || curl -sSfL -o "$DEFS" \
  https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.None.d.luau
rojo sourcemap default.project.json -o sourcemap.json
luau-lsp analyze --definitions="$DEFS" --sourcemap=sourcemap.json --platform=roblox src 2>&1 \
  | grep -v -E '^\[(INFO|WARN)\]' || true
echo "check done"
