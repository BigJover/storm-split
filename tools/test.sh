#!/bin/sh
# Headless tests: every tools/test/*.spec.luau under Lune (see tools/test/run.luau),
# then the Config <-> design-doc audit (tools/audit.py, a report: findings don't fail
# the run; use --strict for that) and the threat estimate (tools/threat.py, which fails
# the run if a DECISIONS #42 target is missed), then the value and pacing models
# (tools/value.py and --pacing, reports: they only fail the run if they crash, e.g.
# when the pacing model no longer reproduces the Balance Check sheet), and the break bars
# (tools/value.py --breaks1, which fails the run if a PLAN T48 bar fails).
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
	echo
	"$PYTHON" -m doctest tools/value.py || status=1 # the overkill factor (PLAN T47)
	"$PYTHON" tools/value.py || status=1
	echo
	"$PYTHON" tools/value.py --breaks1 || status=1 # the break bars gate (PLAN T48 final)
	echo
	"$PYTHON" tools/value.py --pacing || status=1
fi
exit $status
