--[[
	Towers: placement, stats, abilities, targeting, firing.

	A tower is a plain table of state (ARCHITECTURE.md §5.1 — the model is a
	view, never the source of truth). Upgrades change `pathTiers` and
	recompute cached stats; the model can be swapped freely without losing
	anything.

	Towers never touch cash (ARCHITECTURE.md §5.4). The shop pays first, then
	calls place() / upgrade() / remove().

	Every tower has an owner — the player who built it (VISION.md). Kills by
	its shots, bomblets and burns are reported through the onPop hook.

	ABILITIES (UPGRADES.md) come from the spreadsheet's ability columns, which
	are cumulative per tier. Across a tower's paths, multipliers multiply,
	amounts take the highest, and yes/no flags combine with OR (Shared/TowerStats).

	  shots              trigger pulls per fire (Double Tap)
	  lineHits           a shot keeps going through enemies behind its target
	  piercesArmor       can damage Armored enemies at all
	  armoredMult/bossMult  extra damage against those enemies
	  splashMult         scales the tower's splash radius
	  markPercent        its target takes +% from every source for a while
	  stunSeconds, knockback  on every enemy it damages
	  burnDps/burnSeconds    leaves a burning patch on the track
	  bomblets           each shell throws this many smaller blasts
	  aura*              buffs OTHER towers inside this tower's range
	                     (strongest aura wins; auras don't stack)

	LEVELS: every tower's damage (shots, bomblets, freeze, burns) is multiplied
	by the team's level (Towers.setLevel, raised by Main every RoundsPerLevel
	rounds cleared), so towers keep pace with enemy HP alongside upgrades.

	CHILLER: every frame it chills enemies in range (slow, brittle, armour
	strip — Enemies.chill); Freeze towers also pulse a hard stop every
	`freezeEvery` seconds. QUARTERMASTER: never shoots; pays round income
	(Towers.roundIncome), drops chests (Towers.airdrops), and its Logistics
	aura discounts upgrades and raises sell refunds for towers in range.

	HEALTH (VISION.md Step 2, DECISIONS #8/#9): every tower has HP — its Max HP
	column, +Tower HP per tier x base for each tier bought (Shared/Combat).
	Towers owns it: damage() (resistance applied), heal(), repair(). At 0 HP a
	tower is trampled (`knockedOut`): it stops firing, chilling, giving auras,
	paying income and dropping chests, dinos stop targeting it (targets()),
	and it can't be upgraded until repaired. It keeps its tiers.

	FIELD HOSPITAL (DECISIONS #15): each frame it heals standing towers and
	hunters in range (the strongest hospital covering each, no stacking);
	Stitch-Up / Miracle Ward also raise trampled towers in range, which
	stand back up at full HP. Tonic's Aura HP % raises the max HP of towers in
	range (Shared/Combat.towerMaxHp), and Last Stand keeps one tower in range
	per round at 1 HP instead of trampled. Med kits ride Airdrops; the Rescue
	Beacon is Main's (respawn here, sooner).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Combat = require(Shared:WaitForChild("Combat"))
local Placement = require(Shared:WaitForChild("Placement"))
local TowerLook = require(Shared:WaitForChild("TowerLook"))
local TowerStats = require(Shared:WaitForChild("TowerStats"))
local Upgrades = require(Shared:WaitForChild("Upgrades"))

local Effects = require(script.Parent.Effects)
local Enemies = require(script.Parent.Enemies)
local Hazards = require(script.Parent.Hazards)
local Health = require(script.Parent.Health)

local Towers = {}

export type Stats = TowerStats.Stats

-- What nearby auras give this tower right now.
type Buff = {
	ratePercent: number,
	damagePercent: number,
	piercesArmor: boolean,
	discountPercent: number, -- off its upgrades (Logistics)
	sellRefund: number, -- 0 = the normal SellRefund
	resistPercent: number, -- damage resistance (an Armory in range, itself included)
	hpPercent: number, -- +% max HP (a Field Hospital's Tonic in range)
}

export type Tower = {
	id: number,
	key: string,
	def: any,
	owner: Player?, -- who built it; nil if they've left
	base: Vector3, -- on the build floor; what Placement checks against
	position: Vector3,
	muzzle: Vector3,
	pathTiers: { number },
	stats: Stats,
	buff: Buff,
	cooldown: number,
	freezeTimer: number,
	hp: number,
	maxHp: number,
	knockedOut: boolean, -- trampled at 0 HP until repaired
	lastStandUsed: boolean, -- a Field Hospital's Last Stand has saved a tower this round
	model: Model,
}

-- Visuals only.
local BOMBLET_COLOR = Color3.fromRGB(255, 190, 90)

local towers: { Tower } = {}
local towerFolder: Instance
local nextId = 0
local onPop: ((Player?, string?) -> ())? = nil
local levelScale = 1 -- damage multiplier from the team's level
local extraRatePercent: ((Tower) -> number)? = nil -- boosts from outside towers (hero Rally Cry)
local resistOf: ((Tower) -> { number })? = nil -- extra damage resistance sources (Field Medic Second Wind)

-- A pop goes to the tower's owner; if they've left, nobody gets it, but the hook still
-- hears which dino is gone (a boss counts for the whole team's bounties).
local function credit(owner: Player?, killed: boolean, gone: string?)
	if killed and onPop then
		onPop(if owner and owner.Parent then owner else nil, gone)
	end
end

------------------------------------------------------------------ stats

local NO_BUFF: Buff =
	table.freeze({ ratePercent = 0, damagePercent = 0, piercesArmor = false, discountPercent = 0, sellRefund = 0, resistPercent = 0, hpPercent = 0 })
local showHealth: (Tower) -> () -- below, with the rest of health

local function hasAura(s: Stats): boolean
	return s.auraRatePercent > 0
		or s.auraDamagePercent > 0
		or s.auraPiercesArmor
		or s.discountPercent > 0
		or s.sellRefund > 0
		or s.resistPercent > 0
		or s.auraHpPercent > 0
end

local function covers(source: Tower, point: Vector3): boolean
	local offset = point - source.base
	return Vector2.new(offset.X, offset.Z).Magnitude <= source.stats.range
end

-- Recomputed whenever a tower is placed, upgraded or removed. The shop panel
-- reads Discount / RefundRate from the tower's body.
local function refreshAuras()
	for _, tower in towers do
		local rate, damage, pierce, discount, refund, resist, hpBonus = 0, 0, false, 0, 0, 0, 0
		for _, source in towers do
			local s = source.stats
			if not source.knockedOut and hasAura(s) and covers(source, tower.base) then
				-- An Armory's resistance covers itself too; the other auras are for others.
				resist = math.max(resist, s.resistPercent)
				if source ~= tower then
					rate = math.max(rate, s.auraRatePercent)
					damage = math.max(damage, s.auraDamagePercent)
					pierce = pierce or s.auraPiercesArmor
					discount = math.max(discount, s.discountPercent)
					refund = math.max(refund, s.sellRefund)
					hpBonus = math.max(hpBonus, s.auraHpPercent)
				end
			end
		end
		tower.buff = if rate > 0 or damage > 0 or pierce or discount > 0 or refund > 0 or resist > 0 or hpBonus > 0
			then {
				ratePercent = rate,
				damagePercent = damage,
				piercesArmor = pierce,
				discountPercent = discount,
				sellRefund = refund,
				resistPercent = resist,
				hpPercent = hpBonus,
			}
			else NO_BUFF
		-- Tonic: gaining the aura adds the HP it gives; losing it only caps HP.
		local maxHp = Combat.towerMaxHp(tower.def, tower.pathTiers, hpBonus)
		if maxHp ~= tower.maxHp then
			if maxHp > tower.maxHp and not tower.knockedOut then
				tower.hp += maxHp - tower.maxHp
			end
			tower.maxHp = maxHp
			tower.hp = math.min(tower.hp, maxHp)
			showHealth(tower)
		end
		local body = tower.model.PrimaryPart
		if body then
			body:SetAttribute("Discount", discount)
			body:SetAttribute("RefundRate", math.max(Config.Tuning.SellRefund, refund))
		end
	end
end

-- The crossover rule lives in Shared/Upgrades so the client can grey out buttons.
-- A trampled tower can't be upgraded until it's repaired.
function Towers.canUpgrade(tower: Tower, pathIndex: number): boolean
	local path = tower.def.paths[pathIndex]
	return path ~= nil and not tower.knockedOut and Upgrades.check(tower.pathTiers, pathIndex, #path.tiers) == "ok"
end

------------------------------------------------------------------ health

-- The body carries HP / MaxHP / KO for the tower panel; the model shows a bar.
function showHealth(tower: Tower)
	local body = tower.model.PrimaryPart
	if body then
		-- Exact values, so the panel's repair price matches the server's.
		body:SetAttribute("HP", tower.hp)
		body:SetAttribute("MaxHP", tower.maxHp)
		body:SetAttribute("KO", tower.knockedOut)
	end
	TowerLook.setHealth(tower.model, if tower.maxHp > 0 then tower.hp / tower.maxHp else 1)
end

local function setKnockedOut(tower: Tower, on: boolean)
	if tower.knockedOut == on then
		return
	end
	tower.knockedOut = on
	tower.cooldown = 0
	tower.freezeTimer = 0
	TowerLook.setKnockedOut(tower.model, on)
	refreshAuras() -- its auras go (and come back on repair)
end

-- Last Stand: the first standing hospital covering this tower that hasn't
-- saved one yet this round spends its save. Returns that hospital, or nil.
local function lastStand(tower: Tower): Tower?
	for _, source in towers do
		if source.stats.lastStand and not source.lastStandUsed and not source.knockedOut and covers(source, tower.base) then
			source.lastStandUsed = true
			return source
		end
	end
	return nil
end

-- Hurts a standing tower, less its resistance. At 0 HP it's trampled.
-- `source` is who or what did it (kept for PvP later). Returns the damage dealt.
function Towers.damage(tower: Tower, amount: number, source: any?): number
	if tower.knockedOut or amount <= 0 or not table.find(towers, tower) then
		return 0
	end
	local sources = if resistOf then table.clone(resistOf(tower)) else {}
	table.insert(sources, tower.buff.resistPercent) -- an Armory in range
	local resist = Combat.combineResist(sources)
	local dealt = math.min(tower.hp, Combat.afterResist(amount, resist))
	tower.hp -= dealt
	local saver = if tower.hp <= 0 then lastStand(tower) else nil
	local outcome = Combat.hitOutcome(tower.hp, dealt, saver ~= nil)
	if outcome == "saved" then
		tower.hp = 1 -- a Field Hospital's Last Stand: not this time
	elseif outcome == "trampled" then
		tower.hp = 0
		setKnockedOut(tower, true)
	end
	-- Visual only: a red hit flash, or Last Stand's green save flash and the
	-- saving hospital's "+" pulse (DECISIONS #48).
	TowerLook.showHit(tower.model, outcome, if saver then saver.model else nil)
	showHealth(tower)
	return dealt
end

-- Heals a standing tower, never past max. Trampled towers need a repair.
function Towers.heal(tower: Tower, amount: number)
	if tower.knockedOut or amount <= 0 or tower.hp >= tower.maxHp then
		return
	end
	tower.hp = math.min(tower.maxHp, tower.hp + amount)
	showHealth(tower)
end

-- Back to full HP, and standing again if it was trampled. Doesn't charge
-- cash: the caller (Shop) pays first.
function Towers.repair(tower: Tower)
	tower.hp = tower.maxHp
	setKnockedOut(tower, false)
	showHealth(tower)
end

------------------------------------------------------------------ Armory

-- The strongest Armory resistance covering a point (a hunter standing there).
function Towers.resistAt(position: Vector3): number
	local best = 0
	for _, source in towers do
		if not source.knockedOut and source.stats.resistPercent > 0 and covers(source, position) then
			best = math.max(best, source.stats.resistPercent)
		end
	end
	return best
end

-- A dino just bit something standing at `position`: the strongest Thorn
-- Plating covering it bites back (pierces armour, scales with the team's
-- level, kill credited to the Armory's owner), and Bulwark stuns the biter
-- (not bosses). Called by DinoAttacks through its onBite hook.
function Towers.bitten(enemy: Enemies.Enemy, position: Vector3)
	local thorns, thornsOwner, stun = 0, nil, 0
	for _, source in towers do
		local s = source.stats
		if not source.knockedOut and (s.thornsDamage > 0 or s.stunBitersSeconds > 0) and covers(source, position) then
			if s.thornsDamage > thorns then
				thorns, thornsOwner = s.thornsDamage, source.owner
			end
			stun = math.max(stun, s.stunBitersSeconds)
		end
	end
	if stun > 0 then
		Enemies.stun(enemy, stun, false)
	end
	if thorns > 0 then
		credit(thornsOwner, Enemies.damage(enemy, thorns * levelScale, true))
	end
end

export type HunterGear = { recoilMult: number, reloadMult: number, spreadMult: number, ratePercent: number }

-- What an Outfitter Armory covering this point does for a hunter's gun: the
-- strongest of each buff (auras don't stack).
function Towers.hunterGearAt(position: Vector3): HunterGear
	local gear = { recoilMult = 1, reloadMult = 1, spreadMult = 1, ratePercent = 0 }
	for _, source in towers do
		local s = source.stats
		if not source.knockedOut and covers(source, position) then
			gear.recoilMult = math.min(gear.recoilMult, s.hunterRecoilMult)
			gear.reloadMult = math.min(gear.reloadMult, s.hunterReloadMult)
			gear.spreadMult = math.min(gear.spreadMult, s.hunterSpreadMult)
			gear.ratePercent = math.max(gear.ratePercent, s.hunterRatePercent)
		end
	end
	return gear
end

-- Standing towers, for dinos to pick targets from.
function Towers.targets(): { Tower }
	local standing = {}
	for _, tower in towers do
		if not tower.knockedOut then
			table.insert(standing, tower)
		end
	end
	return standing
end

-- How many model swaps the tower has reached (0, 1 or 2), from the tiers
-- flagged swapsModel in Config.
local function swapStage(tower: Tower): number
	local stage = 0
	for pathIndex, tier in tower.pathTiers do
		local reached = 0
		for t = 1, tier do
			if tower.def.paths[pathIndex].tiers[t].swapsModel then
				reached += 1
			end
		end
		stage = math.max(stage, reached)
	end
	return stage
end

------------------------------------------------------------------ public

export type Hooks = {
	-- (who gets the pop, or nil if they've left; the species key if the dino is gone,
	-- nil for a shrink)
	onPop: ((Player?, string?) -> ())?,
	extraRatePercent: ((Tower) -> number)?,
	resistOf: ((Tower) -> { number })?,
}

function Towers.init(folder: Instance, hooks: Hooks?)
	towerFolder = folder
	onPop = hooks and hooks.onPop
	extraRatePercent = hooks and hooks.extraRatePercent
	resistOf = hooks and hooks.resistOf
end

-- Callers check Placement first (Shop does); this only builds.
function Towers.place(key: string, position: Vector3, owner: Player?): Tower?
	local def = Config.Towers[key]
	if not def then
		warn(`[Towers] Unknown tower '{key}'`)
		return nil
	end

	local base = Placement.ground(position)
	local model = TowerLook.build(key, def.range, base)
	model.Parent = towerFolder

	nextId += 1
	local pathTiers = { 0, 0, 0 }
	local maxHp = Combat.towerMaxHp(def, pathTiers)
	local tower: Tower = {
		id = nextId,
		key = key,
		def = def,
		owner = owner,
		base = base,
		position = base + Vector3.new(0, TowerLook.BODY_HEIGHT / 2, 0),
		muzzle = base + Vector3.new(0, TowerLook.BODY_HEIGHT - 0.5, 0),
		pathTiers = pathTiers,
		stats = TowerStats.compute(def, pathTiers),
		buff = NO_BUFF,
		cooldown = 0,
		freezeTimer = 0,
		hp = maxHp,
		maxHp = maxHp,
		knockedOut = false,
		lastStandUsed = false,
		model = model,
	}
	table.insert(towers, tower)
	showHealth(tower)
	refreshAuras()
	return tower
end

-- Returns true if the upgrade was applied. Does NOT charge cash — the caller
-- (Shop) must Economy.trySpend first. Keeps this module free of money.
function Towers.upgrade(tower: Tower, pathIndex: number): boolean
	if not Towers.canUpgrade(tower, pathIndex) then
		return false
	end
	tower.pathTiers[pathIndex] += 1
	tower.stats = TowerStats.compute(tower.def, tower.pathTiers)
	-- The HP an upgrade adds to the max is added to current HP too.
	local maxHp = Combat.towerMaxHp(tower.def, tower.pathTiers, tower.buff.hpPercent)
	tower.hp = math.min(maxHp, tower.hp + (maxHp - tower.maxHp))
	tower.maxHp = maxHp
	TowerLook.refresh(tower.model, tower.stats.range, tower.pathTiers, swapStage(tower))
	TowerLook.setLantern(tower.model, tower.stats.rescueRespawnMult > 0) -- Rescue Beacon
	showHealth(tower)
	refreshAuras()
	return true
end

------------------------------------------------------------------ targeting

local function piercing(tower: Tower): boolean
	return tower.stats.piercesArmor or tower.buff.piercesArmor
end

-- Can this tower both reach and hurt this enemy?
local function canTarget(tower: Tower, enemy: Enemies.Enemy): boolean
	if enemy.def.flying and not tower.def.hitsAir then
		return false
	end
	return Enemies.canHurt(enemy, piercing(tower))
end

-- "First" targeting: the enemy furthest along the track that is in range.
-- Enemies the tower can't hurt (armour without pierce) are ignored.
local function pickFirst(tower: Tower, live): Enemies.Enemy?
	local best, bestDistance = nil, -1
	local range = tower.stats.range
	for _, enemy in live do
		if enemy.distance > bestDistance and canTarget(tower, enemy) and (enemy.part.Position - tower.position).Magnitude <= range then
			best, bestDistance = enemy, enemy.distance
		end
	end
	return best
end

local function splashTargets(tower: Tower, primary: Enemies.Enemy, live): { Enemies.Enemy }
	local hits = { primary }
	local count, radius = tower.stats.targets, tower.stats.splashRadius
	if count <= 1 or radius <= 0 then
		return hits
	end
	local centre = primary.part.Position
	for _, enemy in live do
		if #hits >= count then
			break
		end
		if enemy ~= primary and canTarget(tower, enemy) and (enemy.part.Position - centre).Magnitude <= radius then
			table.insert(hits, enemy)
		end
	end
	return hits
end

-- The target plus the enemies right behind it on the track, nearest first.
local function lineTargets(tower: Tower, primary: Enemies.Enemy, live): { Enemies.Enemy }
	local reach = Config.Tuning.LinePierceReach or 0
	local behind = {}
	for _, enemy in live do
		if enemy ~= primary and canTarget(tower, enemy) then
			local gap = primary.distance - enemy.distance
			if gap >= 0 and gap <= reach then
				table.insert(behind, enemy)
			end
		end
	end
	table.sort(behind, function(a, b)
		return a.distance > b.distance
	end)
	local hits = { primary }
	for i = 1, math.min(#behind, tower.stats.lineHits - 1) do
		table.insert(hits, behind[i])
	end
	return hits
end

------------------------------------------------------------------ hitting

local function hit(tower: Tower, enemy: Enemies.Enemy, damage: number)
	local stats = tower.stats
	local pierce = piercing(tower)
	if not Enemies.canHurt(enemy, pierce) then
		return
	end
	if enemy.def.armored then
		damage *= stats.armoredMult
	end
	if enemy.def.boss then
		damage *= stats.bossMult
	end
	Enemies.stun(enemy, stats.stunSeconds, stats.stunsBosses)
	Enemies.knockback(enemy, stats.knockback)
	credit(tower.owner, Enemies.damage(enemy, damage, pierce))
end

-- Bomblets land along the track around `distance`, alternating behind and
-- ahead of it. Each generation throws the same number again, weaker.
local function bomblets(tower: Tower, distance: number, damage: number, generation: number, live)
	local stats = tower.stats
	if generation > stats.bombletGenerations or stats.bomblets <= 0 then
		return
	end
	local spread = Config.Tuning.BombletSpread or 0
	local share = Config.Tuning.BombletDamage or 0
	local blastDamage = damage * share
	for i = 1, stats.bomblets do
		local side = if i % 2 == 1 then -1 else 1
		local centre = distance + side * spread * math.ceil(i / 2)
		for _, enemy in live do
			if canTarget(tower, enemy) and math.abs(enemy.distance - centre) <= spread / 2 then
				hit(tower, enemy, blastDamage)
			end
		end
		Effects.part(Vector3.one * 2, CFrame.new(Enemies.pointAt(centre) + Vector3.new(0, 1, 0)), BOMBLET_COLOR, 0.15, Enum.PartType.Ball)
		bomblets(tower, centre, blastDamage, generation + 1, live)
	end
end

local function addBurn(tower: Tower, primary: Enemies.Enemy)
	local stats = tower.stats
	if primary.def.flying then
		return
	end
	Hazards.burn(primary.distance, stats.splashRadius, stats.burnDps * levelScale, stats.burnSeconds, piercing(tower), tower.owner)
end

local function fire(tower: Tower, live): boolean
	local stats = tower.stats
	local damage = stats.damage * (1 + tower.buff.damagePercent / 100) * levelScale
	local fired = false

	for _ = 1, stats.shots do
		local target = pickFirst(tower, live)
		if not target then
			break
		end
		fired = true
		local targetPosition = target.part.Position
		local targetDistance = target.distance

		if stats.markPercent > 0 then
			Enemies.mark(target, stats.markPercent, Config.Tuning.MarkDuration or 0)
		end
		addBurn(tower, target)

		local hits = if stats.lineHits > 1 then lineTargets(tower, target, live) else splashTargets(tower, target, live)
		for _, enemy in hits do
			hit(tower, enemy, damage)
		end
		bomblets(tower, targetDistance, damage, 1, live)

		Effects.tracer(tower.muzzle, targetPosition, TowerLook.COLORS[tower.key] or Color3.new(1, 1, 1))
	end
	return fired
end

-- Visuals only.
local FREEZE_COLOR = Color3.fromRGB(150, 220, 255)
-- How long a chill lasts after the last frame an enemy spent in range (plus
-- any Permafrost linger). Keeps the chill continuous between frames.
local CHILL_REFRESH = 0.25

-- Chillers: chill everything in range every frame; Freeze pulses hard stops.
local function stepChill(tower: Tower, dt: number, live)
	local stats = tower.stats
	if tower.knockedOut or (stats.slowPercent <= 0 and stats.freezeEvery <= 0) then
		return
	end
	local range = stats.range
	local chill: Enemies.Chill = {
		slowPercent = stats.slowPercent,
		seconds = CHILL_REFRESH + stats.slowLinger,
		affectsBosses = stats.slowsBosses,
		brittlePercent = stats.brittlePercent,
		stripsArmor = stats.stripsArmor,
	}
	local pulse = false
	if stats.freezeEvery > 0 then
		tower.freezeTimer += dt
		if tower.freezeTimer >= stats.freezeEvery then
			tower.freezeTimer -= stats.freezeEvery
			pulse = true
		end
	end
	for _, enemy in live do
		if (enemy.part.Position - tower.position).Magnitude <= range then
			if stats.slowPercent > 0 then
				Enemies.chill(enemy, chill)
			end
			if pulse then
				Enemies.knockOut(enemy, stats.freezeSeconds, stats.freezeHoldsBosses)
				if stats.freezeDamage > 0 then
					credit(tower.owner, Enemies.damage(enemy, stats.freezeDamage * levelScale, piercing(tower)))
				end
			end
		end
	end
	if pulse then
		Effects.disc(tower.base + Vector3.new(0, 0.3, 0), range, FREEZE_COLOR, 0.3, 0.6)
	end
end

-- Called every Heartbeat by Main.
-- NOTE: fires at most once per frame (times `shots`), so fire rates above
-- ~60/s are capped.
------------------------------------------------------------------ Field Hospital

-- The strongest standing hospital's heal (and revive) rate covering a point.
local function healRates(point: Vector3): (number, number)
	local heal, revive = 0, 0
	for _, source in towers do
		local s = source.stats
		if s.healPerSecond > 0 and not source.knockedOut and covers(source, point) then
			heal = math.max(heal, s.healPerSecond)
			if s.revives then
				revive = math.max(revive, s.healPerSecond * s.reviveSpeed)
			end
		end
	end
	return heal, revive
end

local function stepHealing(dt: number)
	local any = false
	for _, source in towers do
		if source.stats.healPerSecond > 0 and not source.knockedOut then
			any = true
			break
		end
	end
	if not any then
		return
	end
	for _, tower in towers do
		local heal, revive = healRates(tower.base)
		if not tower.knockedOut and heal > 0 and tower.hp < tower.maxHp then
			Towers.heal(tower, heal * dt)
		elseif tower.knockedOut and revive > 0 then
			-- Revive: HP climbs while it stays trampled; it stands at full.
			tower.hp = math.min(tower.maxHp, tower.hp + revive * dt)
			if tower.hp >= tower.maxHp then
				Towers.repair(tower)
			else
				showHealth(tower)
			end
		end
	end
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local heal = healRates(root.Position)
			if heal > 0 then
				Health.heal(player, heal * dt)
			end
		end
	end
end

export type MedKitDrop = { base: Vector3, count: number, heal: number }

-- Med kits each standing hospital drops this round.
function Towers.medKits(): { MedKitDrop }
	local drops = {}
	for _, tower in towers do
		local s = tower.stats
		if s.medKits > 0 and s.medKitHeal > 0 and not tower.knockedOut then
			table.insert(drops, { base = tower.base, count = s.medKits, heal = s.medKitHeal })
		end
	end
	return drops
end

-- A standing Rescue Beacon: where downed hunters come back, and the share of
-- the respawn time they wait. nil if there's none.
function Towers.rescueBeacon(): (Vector3?, number)
	local best, mult = nil, 1
	for _, tower in towers do
		local m = tower.stats.rescueRespawnMult
		if m > 0 and not tower.knockedOut and (best == nil or m < mult) then
			best, mult = tower.base, m
		end
	end
	return best, mult
end

-- A new round: every Last Stand is ready again.
function Towers.newRound()
	for _, tower in towers do
		tower.lastStandUsed = false
	end
end

function Towers.step(dt: number)
	stepHealing(dt)
	local live = Enemies.getLive()
	for _, tower in towers do
		stepChill(tower, dt, live)
	end

	for _, tower in towers do
		local stats = tower.stats
		if stats.rate <= 0 or stats.damage <= 0 or tower.knockedOut then
			continue -- Quartermaster and anything else that doesn't shoot; trampled towers
		end

		tower.cooldown -= dt
		if tower.cooldown > 0 then
			continue
		end

		if fire(tower, live) then
			local boost = tower.buff.ratePercent + (if extraRatePercent then extraRatePercent(tower) else 0)
			tower.cooldown += 1 / (stats.rate * (1 + boost / 100))
		else
			tower.cooldown = 0 -- stay ready
		end
	end
end

function Towers.byId(id: number): Tower?
	for _, tower in towers do
		if tower.id == id then
			return tower
		end
	end
	return nil
end

function Towers.positions(): { Vector3 }
	local list = {}
	for _, tower in towers do
		table.insert(list, tower.base)
	end
	return list
end

-- Takes the tower off the map. Refunds are the caller's job.
function Towers.remove(tower: Tower)
	local index = table.find(towers, tower)
	if not index then
		return
	end
	table.remove(towers, index)
	tower.model:Destroy()
	refreshAuras()
end

-- Level 1 is the start; each level multiplies tower damage by 1 + TowerDamagePerLevel.
function Towers.setLevel(level: number)
	levelScale = (1 + Config.Tuning.TowerDamagePerLevel) ^ math.max(0, level - 1)
end

-- Quartermaster income for the round that just ended. Interest is on the
-- team's banked cash; the best Amber Vault applies, they don't stack.
function Towers.roundIncome(bankedCash: number): number
	local income, interest = 0, 0
	for _, tower in towers do
		local perRound = tower.def.incomePerRound or 0
		if perRound > 0 and not tower.knockedOut then
			local stats = tower.stats
			income += perRound * stats.incomeMult
			if stats.interestPercent > 0 then
				interest = math.max(interest, math.min(stats.interestCap, bankedCash * stats.interestPercent / 100))
			end
		end
	end
	return income + interest
end

export type Airdrop = { base: Vector3, count: number, cash: number, owner: Player? }

-- Chests each Quartermaster drops this round.
function Towers.airdrops(): { Airdrop }
	local drops = {}
	for _, tower in towers do
		if tower.stats.chests > 0 and tower.stats.chestCash > 0 and not tower.knockedOut then
			table.insert(drops, { base = tower.base, count = tower.stats.chests, cash = tower.stats.chestCash, owner = tower.owner })
		end
	end
	return drops
end

-- Between matches: every tower off the map.
function Towers.clearAll()
	for i = #towers, 1, -1 do
		towers[i].model:Destroy()
		towers[i] = nil
	end
	levelScale = 1
end

function Towers.all(): { Tower }
	return towers
end

return Towers
