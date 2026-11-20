#!/bin/sh
# Gold Rush set pieces (11e2, #457): build SET_GOLD_RUSH_<TOWER> and its previews on the tower at
# stage 2 (saved as <KEY>_s2.png, _s2_side, _s2_top) and stage 0 (<KEY>.png, _side, _top; the
# manifest entry is the same either way). Preview-only: GR_STAGE picks the tower drawn under it.
#   tools/art/goldrush_previews.sh SCOUT SNIPER ...
#   tools/art/goldrush_previews.sh --sheet      # previews/sheet_11e_set_gold_rush.png
cd "$(dirname "$0")/../.."
export ART_LOG=${ART_LOG:-${TMPDIR:-/tmp}/dinohunters-art-goldrush.log}
P=tools/art/previews/tower
ALL="SCOUT SNIPER GRENADIER CHILLER QUARTERMASTER HOSPITAL ARMORY COIL FALCON BALLISTA TARPIT RESIN RAPTOR TOTEM BLIMP METEOR VENT RANGER"
if [ "$1" = "--sheet" ]; then  # a row per tower: stage 0 top, 3/4 | stage 2 top, 3/4
	list=""
	for t in $ALL; do
		k=tower/SET_GOLD_RUSH_$t
		list="$list,${k}_top.png,$k.png,${k}_s2_top.png,${k}_s2.png"
	done
	exec tools/art/build.sh --pngs 11e_set_gold_rush 4 "${list#,}"
fi
for t in "$@"; do
	k=SET_GOLD_RUSH_$t
	GR_STAGE=2 tools/art/build.sh tower "$k" || exit 1
	for v in "" _side _top; do mv "$P/$k$v.png" "$P/${k}_s2$v.png"; done
	GR_STAGE=0 tools/art/build.sh tower "$k" || exit 1
done
