#!/bin/sh
# Headless tests: every tools/test/*.spec.luau under Lune (see tools/test/run.luau).
# Pass words to run only the specs whose file name contains them: tools/test.sh upgrades
set -e
cd "$(dirname "$0")/.."
export PATH="$HOME/.rokit/bin:$PATH"
lune run tools/test/run.luau "$@"
