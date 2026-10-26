#!/bin/sh
# Build one art model headless (PLAN 11a T146): FBX + preview PNG + manifest entry.
#   tools/art/build.sh dino HUSK            # one model
#   tools/art/build.sh --sheet dino 11a     # contact sheet of a batch's previews
# Exits non-zero on a script error, a budget miss (#433) or a 300 s timeout.
# Blender's full log goes to $ART_LOG (default: $TMPDIR/dinohunters-art.log).
cd "$(dirname "$0")/../.."
BLENDER=${BLENDER:-/Applications/Blender.app/Contents/MacOS/Blender}
LOG=${ART_LOG:-${TMPDIR:-/tmp}/dinohunters-art.log}
[ $# -ge 2 ] || { echo "usage: $0 <kind> <key> | --sheet <kind> <batch>"; exit 2; }
perl -e 'alarm shift; exec @ARGV' 300 "$BLENDER" --background --factory-startup \
	--python-exit-code 1 --python tools/art/build.py -- "$@" > "$LOG" 2>&1
status=$?
grep '^ART ' "$LOG"
if [ $status -ne 0 ] || ! grep -q '^ART OK' "$LOG"; then
	grep -E 'Error|Traceback' "$LOG" | tail -5
	echo "art build failed (exit $status, log $LOG)"
	exit 1
fi
