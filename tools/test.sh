#!/bin/sh
# Headless tests: every tools/test/*.spec.luau under Lune (see tools/test/run.luau),
# then the Config <-> design-doc audit (tools/audit.py) and the threat estimate
# (tools/threat.py); both are reports, their findings don't fail the run.
# Pass words to run only the specs whose file name contains them (skips the audit):
#   tools/test.sh upgrades
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"
PYTHON=/Library/Developer/CommandLineTools/usr/bin/python3 # the Xcode licence blocks /usr/bin/python3
[ -x "$PYTHON" ] || PYTHON=python3

status=0
lune run tools/test/run.luau "$@" || status=1
if [ $# -eq 0 ]; then
	echo
	"$PYTHON" tools/audit.py || status=1
	echo
	"$PYTHON" tools/threat.py || status=1
fi
exit $status
