# How Jovan decides — a digest for the agents

Everything here comes from Jovan's own decisions while building the game (Sept 2026). When
a question isn't answered by `VISION.md`, `UPGRADES.md` or `HEROES.md`, decide the way these
point, then log it in `DECISIONS.md`.

## What the game is

- **Dino Hunters**: co-op (up to ~10 players) dinosaur-hunting tower defense on Roblox,
  BTD6-inspired but original. "As open and chaotic as possible." Future PvP modes (team
  battle, battle royale) must not be blocked by today's code.
- Players are **hunters**; enemies are **dinosaurs**; towers, weapons and abilities are
  **hunting gear**. Each tier is its own species; dinos **shrink** (one enemy, smaller,
  weaker) rather than split. Currency: **Amber**.

## Design taste

- **Specialised, named upgrades**, BTD6-style — never a boring "+30%". Each path has a
  role (attack speed, anti-armour, support, control, economy); tiers have names.
- **Hero upgrades are about handling** (reload, recoil, fire modes, special rounds), not
  raw damage. Power growth comes from levels.
- **Towers and heroes must both stay useful.** A hero must never out-damage the best tower
  (the exporter checks). Levels (+25% hero / +10% tower every 5 rounds) keep pace with HP;
  since 2026-10-02 a hunter's own level comes from hero XP and may run one level ahead.
- **Clean, uncluttered UI.** Separate screens for separate jobs (hero select vs upgrades;
  unlocks split into Heroes and Towers). Show prices, discounts and what an upgrade does in
  plain words.
- **PvP fairness:** first person for everyone, always; third person only while placing a
  tower. The mouse cursor must be visible whenever it's free.
- **No pop-up may ever trap a player** (Jovan, 2026-10-01, after one did). Every panel or
  screen must: fit on any window size with its close control always visible (scroll, scale
  or shrink, never overflow); free the mouse while it's open; close with the key that opened
  it and with an on-screen X; and close on every match-state change except the ones
  `Shared/PanelRules` allows. Anything a player must click (Play, Start) must stay reachable
  for every player who needs it, not just the host.
- **Everyone starts fair:** no free starting towers beyond the free roster; heroes picked
  for free once owned; you can only place towers you own but may upgrade a teammate's.
- **Numbers belong in the spreadsheet**, never in code. Visual-only values may live in code.
- Effects he's tuned by feel: Chiller/Tranq slow buffed (base 40%); Dragon's Breath is a
  small one-tick burn (35% of the shot), not an automatic kill. Expect him to prefer
  "small, readable effect" over "big automatic effect".

## Mastery perks and hero XP (Jovan, 2026-10-02)

- **Mastery ability perks scale up:** the objectively stronger perk sits at level 15, the
  lesser one at level 10. If two are equal, make one edge out the other.
- **Designed for PvP too:** "nothing extremely strong, just something that gives a somewhat
  fair advantage". An edge, never a fight-winner; no hard crowd control on hunters.
- **Hero XP from pops is good, but small**, so nobody farms pops, and it **only counts at
  the end**: XP is banked when a round is finished, to entice players to finish rounds and
  games.
- **Saving and publishing can wait** until the game is published. Don't build for it now.
  (2026-10-02 update below: the player level does save, on the same offline-tolerant path
  as Amber, and must degrade gracefully while unpublished.)

## Round-4 answers (Jovan, 2026-10-02)

His words, verbatim where quoted; how the agents read them is in `DECISIONS.md` #118–#142.

1. **XP "count at the end" = a new overall player level**, not the hero level. Hero level
   stays as built (rises mid-match per cleared round); the match's XP *also* counts at the
   end of the game toward the overall level. Saved between matches; "the cap should be
   infinite for now"; "i want a level leader board". Rewards: "cosmetics and titles as well
   as being shown off… we need a lot of cosmetics, nothing too good from levels 1-100 then
   some nicer ones that are more spaced out like every 10 levels then from 100-200 ones
   that are really nice spaced out by 50 each". A cross-server leaderboard needs the place
   published: build it so it works unpublished and degrades gracefully.
2. **Take-down XP:** "not too small as there are a lot of dinos per round maybe consider a
   slight increase if it is not noticeable in practice (single player maybe we buff xp from
   take downs as to speed up the leveling process for new players but dont change it much
   or at all in multiplayer/co-op modes". Perk names approved.
3. **Competitive (phase 7 only):** "mastery perks stay on in competitive modes; other perks
   may need to be buffed to be in line so money advantage isnt too big (players who have
   maxed heros and towers would be the target audience for the competitive mode)".
4. **Raw damage and pierce-through:** "hunter vs longshot is good some towers should be
   better than others in terms of raw damage, also some that are more powerful in raw
   damage should be able to 'pierce through' levels meaning one shot can take the dino down
   2 or more levels based on how leveled up the tower is and the level of the balloon [dino
   size], dinos should have one health pool which have thresholds so hitting a threshold
   would de-level the dino not depleting the level health bar".
5. **Empty mastery levels (6–9, 11–14, 16–19):** "Small perks" — non-damage, PvP-safe.
6. **Difficulty:** "more cash for hard; chaos should be nearly impossible relying on player
   gun skill rather than tower defense".
7. **Towers:** unlock pace "fine as is but we need more towers, the next batch needs to be
   2x the cost but worth it (some that dont take damage) (lightning chaining abilities
   reaching all dinos on the field at once)". He wants ideas and to be asked about the
   highest tiers (`TOWERS_NEXT.md`, a proposal until he picks).
8. **Renames:** "apply all but change trophies to bones, i want to use a clash royale trophy
   system for ranked". So take-downs are **Bones**; **Trophies** are reserved for ranked.
9. **Linebreaker:** ×2 over tier 4. 10. **Dragon's Breath:** ground patch 3 studs; a new
   tier may make it 4 ("so its more powerful and feels right as a high tier upgrade"), and
   then every hero path gets the same number of tiers. 11. **Horn Toss:** unchanged.
12. **UI:** bigger PLAY, Amber shown on the Hunt Board, the "+N on round clear" line on its
   own, softer round-31 boss throws.

**Tower picks (Jovan, 2026-10-02, later the same day):** all four proposed towers ("these
are all good at the 2x price point of amber"). **Only the Amber unlock doubles**; in-match
prices stay normal. Towers that can't be damaged are "somewhat weaker". Tar Pit sits on the
track itself. Tier 5s: Power Grid ("the more storm coils you have increases the aoe and
damage, only having one can be nerfed"), Judgement Bolt, Lightning Rodeo; Eagle of the
Peak, Murmuration, Hunting Party; Tar Lake, Eruption ("takes 2 levels of any dino in the
pool"), Tar Totem; Skewer, Tow Line, Chain Harpoons. Next: "we now only need the 4x amber
costing ones" (`TOWERS_LATER.md`, a proposal). He picks from options quickly, so keep
offering 3–4 per top tier.

What this adds to his taste:
- **Raw damage is allowed to differ** between towers, and the hard hitters earn a mechanic
  (pierce-through) rather than just a bigger number. Keep the models honest about it.
- **Difficulty has character, not just multipliers:** Hard is generous with starting cash;
  Chaos is a gun-skill mode where towers alone can't win.
- **Progression wants lots of small, frequent rewards early and rarer, showier ones late.**
  Cosmetics and titles only: never gameplay power.
- **New players get help in solo, never at co-op's expense.**
- **Bigger, pricier content must be "worth it"**, and he wants options to choose from for
  the top tiers.

## Phase-7 answers (Jovan, 2026-10-06)

- **Mode names:** "go with the name changes" — Team Battle is **Camp Clash**, Battle Royale
  is **Bone Rush** (DECISIONS #230). He accepts theme renames of his own words when they're
  proposed with reasons.
- **Next:** "begin phase 8 when all loose ends on phase 7 are done" (PLAN T87).

## Match length, joiners, strength gap (Jovan, 2026-10-09)

Verbatim: "60-80 mins is a little long for a multiplayer, lets have a 15 min max for pvp
modes that arent competitve then 30 min max with overtime included for competitve we need
tie breakers so you cant tie in comp, single player/co-op pve lets half that time so
30-40min max make sure there is no mid round joining for comp and that late joiners are
accounted for with some extra cash so they arent a detriment to their team or unable to
fairly compete in battle royale, that strength difference is good as competitve is meant
for players who have maxed out troops, sort of like clash royale, where trophy road is card
level based, quick play should still have a strength difference as i want new players to
encounter maxed out hunters of other classes and think "i need to unlock that one" lets do
the 4x picks after all of this is dealt with"

What this adds to his taste (applied in DECISIONS #249–#257, PLAN "Phase 8 batch 2"):
- **Match length is a hard ceiling, per mode:** casual Camp Clash / Bone Rush ≤ 15 min;
  Ranked ≤ 30 min *including* overtime; solo/co-op PvE ≤ 30–40 min. Shorter matches beat
  the full 40-round epic for multiplayer.
- **Ranked can never tie.** Every ranked result needs a decided winner/placing.
- **Ranked seats lock at the start** (no mid-match joining). **Casual welcomes late
  joiners**, who get catch-up cash so they help their camp and can still fight for Bone
  Rush placings.
- **The strength gap is a feature.** Competitive is for maxed players (Clash Royale's
  level-based trophy road). Quick play keeps the gap on purpose: a new player meeting a
  maxed hunter of another class should think "I need to unlock that one". Don't level or
  normalise power in either queue; parity *between heroes* (#235) still holds.
- **Order:** finish match length and joiners first, then the 4×-Amber picks.

## Economy (his numbers)

- Casual: solo pays only on a track clear (Easy 50 / Normal 100 / Hard 150 / Chaos 200
  Amber); multiplayer losers 5, winners the clear reward. Competitive (phase 7): 10–20
  Amber buy-in pot, battle royale split 72/23/5 rounded down.
- Unlocks: Tracker + Hunting Blind / Longshot Perch / Mortar Pit free; Big Game Hunter 75,
  Brush Beater 75, Tranq Station 100, Supply Camp 150. The next tower batch costs about 2×
  (2026-10-02).
- Starting cash: 450, and more on Hard (2026-10-02; the number is PLAN T42's).

## How he works

- He tests in Studio and reports briefly ("works", "perfect", "X is off"). He wants short
  recaps: what changed, what to try.
- He likes being asked before big design changes, and approves quickly. When he's away
  (the gauntlet loop), decide in line with this file and log it instead.
- He wants every verified step committed and pushed.
- He wants builds **tested in Roblox Studio whenever that's possible** (2026-10-01), by a
  Tester agent through Studio's MCP server (`GAUNTLET.md`). Headless specs don't replace it.
- **"Make sure everything is play tested and phase 7 is fully done"** (2026-10-06). Done
  means built, plus a Studio playtest of every step that can be tested, plus a clear list of
  what only he (multi-client) or real players (published) can test.
- Be honest about what was and wasn't verified. Never claim something works in Studio
  unless it was run there.
