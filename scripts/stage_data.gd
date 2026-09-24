class_name StageData
extends Object

## Fases, dificuldades, composição de waves e save de progresso.
## 3 fases x 5 ondas = 15 ondas. Desbloqueio em cadeia:
## vencer uma fase libera a próxima; vencer uma dificuldade libera a seguinte.

const WAVES_PER_STAGE := 5

const STAGES := [
	{
		name = "Floresta Verde", desc = "Onde tudo começa.\nInimigos fracos.",
		color = Color(0.3, 0.7, 0.3), boss = "GOLEM",
		palette = {
			grass = Color(0.16, 0.42, 0.16),
			dirt = Color(0.48, 0.36, 0.22),
			water = Color(0.12, 0.35, 0.62),
		},
	},
	{
		name = "Terra Queimada", desc = "Cinzas e brasas.\nInimigos furiosos.",
		color = Color(0.85, 0.45, 0.2), boss = "DRAGON",
		palette = {
			grass = Color(0.36, 0.3, 0.13),
			dirt = Color(0.32, 0.24, 0.17),
			water = Color(0.16, 0.3, 0.24),
		},
	},
	{
		name = "Pântano Sombrio", desc = "O coração das trevas.\nSem piedade.",
		color = Color(0.6, 0.3, 0.8), boss = "BARON",
		palette = {
			grass = Color(0.1, 0.3, 0.24),
			dirt = Color(0.26, 0.18, 0.26),
			water = Color(0.26, 0.16, 0.46),
		},
	},
]

const DIFFS := [
	{ name = "NORMAL", hp = 1.0, atk = 1.0, df = 1.0, count = 1.0, exp = 1.0, gold = 1.0, speed = 1.0, color = Color(0.6, 0.8, 0.6) },
	{ name = "MÉDIO", hp = 1.5, atk = 1.4, df = 1.3, count = 1.25, exp = 1.2, gold = 1.2, speed = 1.1, color = Color(1, 0.85, 0.3) },
	{ name = "HARD", hp = 2.2, atk = 2.0, df = 1.7, count = 1.5, exp = 1.5, gold = 1.5, speed = 1.2, color = Color(1, 0.5, 0.2) },
	{ name = "IMPOSSÍVEL", hp = 3.2, atk = 2.9, df = 2.2, count = 2.0, exp = 2.0, gold = 1.8, speed = 1.3, color = Color(0.9, 0.2, 0.3) },
]

## Suprimentos da LOJA do menu (◆): entram no inventário no início da run.
const SUPPLIES := [
	{ id = "hp", name = "Poção de Vida extra", desc = "+1 Poção de Vida (100 HP) no início de cada run", base = 40, max = 2 },
	{ id = "mp", name = "Poção de Mana extra", desc = "+1 Poção de Mana (80 MP) no início de cada run", base = 40, max = 2 },
	{ id = "elix", name = "Elixir inicial", desc = "Começa cada run com 1 Elixir Supremo", base = 150, max = 1 },
]

## Quantos inimigos a onda exige (chefão da última onda conta na cota).
static func wave_quota(_stage: int, wave_idx: int, diff: int) -> int:
	var dd: Dictionary = DIFFS[clampi(diff, 0, DIFFS.size() - 1)]
	var base := 3 + wave_idx * 2
	if wave_idx == WAVES_PER_STAGE - 1:
		base += 2
	return maxi(3, int(base * float(dd.get("count", 1.0))))

static func alive_cap(stage: int, diff: int) -> int:
	return 6 + stage * 2 + diff

static func global_wave(stage: int, wave_idx: int) -> int:
	return stage * WAVES_PER_STAGE + wave_idx + 1

static func stage_name(stage: int) -> String:
	var st: Dictionary = STAGES[clampi(stage, 0, STAGES.size() - 1)]
	return str(st.get("name", "?"))

static func diff_name(diff: int) -> String:
	var dd: Dictionary = DIFFS[clampi(diff, 0, DIFFS.size() - 1)]
	return str(dd.get("name", "?"))

static func boss_type(stage: int) -> String:
	var st: Dictionary = STAGES[clampi(stage, 0, STAGES.size() - 1)]
	return str(st.get("boss", "DRAGON"))

# =====================================================================
#  SAVE (user://rpg_league_save.cfg)
# =====================================================================
const SAVE_PATH := "user://rpg_league_save.cfg"

static func default_progress() -> Dictionary:
	return {
		"unlocked": 1,
		"cleared": [
			[false, false, false, false],
			[false, false, false, false],
			[false, false, false, false],
		],
		# Essência ◆ = moeda meta (de fases/ondas, NUNCA de kills).
		# Gasta no menu para desbloquear habilidades permanentemente.
		"essence": 0,
		"skills": {
			"tank": [false, false, false, false, false],
			"assassin": [false, false, false, false, false],
			"mage": [false, false, false, false, false],
			"marksman": [false, false, false, false, false],
			"support": [false, false, false, false, false],
		},
		"supplies": {"hp": 0, "mp": 0, "elix": 0},
	}

static func load_progress() -> Dictionary:
	var unlocked := 1
	var cleared: Array = [
		[false, false, false, false],
		[false, false, false, false],
		[false, false, false, false],
	]
	var bank := 0
	var skills := {		"tank": [false, false, false, false, false],
		"assassin": [false, false, false, false, false],
		"mage": [false, false, false, false, false],
		"marksman": [false, false, false, false, false],
		"support": [false, false, false, false, false],
	}
	var supplies := {"hp": 0, "mp": 0, "elix": 0}
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		unlocked = clampi(int(cfg.get_value("progress", "unlocked_stages", 1)), 1, STAGES.size())
		for s in STAGES.size():
			var loaded = cfg.get_value("progress", "cleared_%d" % s, [])
			if loaded is Array:
				var loaded_arr: Array = loaded
				var row: Array = cleared[s]
				for d in mini(DIFFS.size(), loaded_arr.size()):
					row[d] = bool(loaded_arr[d])
		bank = maxi(0, int(cfg.get_value("progress", "essence", 0)))
		for role in skills.keys():
			var sloaded = cfg.get_value("progress", "skills_" + str(role), [])
			if sloaded is Array:
				var srow: Array = skills[role]
				var sarr: Array = sloaded
				for i in mini(srow.size(), sarr.size()):
					srow[i] = bool(sarr[i])
		for sid in supplies.keys():
			supplies[sid] = maxi(0, int(cfg.get_value("progress", "supply_" + str(sid), 0)))
	return {"unlocked": unlocked, "cleared": cleared, "essence": bank, "skills": skills, "supplies": supplies}

static func save_progress(prog: Dictionary) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked_stages", int(prog.get("unlocked", 1)))
	var cleared: Array = prog.get("cleared", [])
	for s in mini(STAGES.size(), cleared.size()):
		cfg.set_value("progress", "cleared_%d" % s, cleared[s])
	cfg.set_value("progress", "essence", maxi(0, int(prog.get("essence", 0))))
	var skills: Dictionary = prog.get("skills", {})
	for role in skills.keys():
		cfg.set_value("progress", "skills_" + str(role), skills[role])
	var supplies: Dictionary = prog.get("supplies", {})
	for sid in supplies.keys():
		cfg.set_value("progress", "supply_" + str(sid), int(supplies[sid]))
	cfg.save(SAVE_PATH)

static func is_stage_unlocked(prog: Dictionary, stage: int) -> bool:
	return stage < int(prog.get("unlocked", 1))

static func is_diff_unlocked(prog: Dictionary, stage: int, diff: int) -> bool:
	if diff <= 0:
		return true
	if stage < 0 or stage >= STAGES.size():
		return false
	var cleared: Array = prog.get("cleared", [])
	if stage >= cleared.size():
		return false
	var row: Array = cleared[stage]
	if diff - 1 >= row.size():
		return false
	return bool(row[diff - 1])

static func is_cleared(prog: Dictionary, stage: int, diff: int) -> bool:
	var cleared: Array = prog.get("cleared", [])
	if stage < 0 or stage >= cleared.size():
		return false
	var row: Array = cleared[stage]
	if diff < 0 or diff >= row.size():
		return false
	return bool(row[diff])

## Marca fase+dificuldade como vencidas, libera o próximo passo e salva.
## Retorna lista de textos do que desbloqueou (para a tela de vitória).
static func mark_cleared(prog: Dictionary, stage: int, diff: int) -> Array:
	var news: Array = []
	var cleared: Array = prog.get("cleared", [])
	var row: Array = cleared[clampi(stage, 0, cleared.size() - 1)]
	row[clampi(diff, 0, row.size() - 1)] = true
	var unlocked: int = int(prog.get("unlocked", 1))
	if diff + 1 < DIFFS.size():
		news.append("%s liberado!" % diff_name(diff + 1))
	if stage + 1 < STAGES.size() and stage + 2 > unlocked:
		unlocked = stage + 2
		news.append("%s liberada!" % stage_name(stage + 1))
	prog["unlocked"] = unlocked
	save_progress(prog)
	return news

# =====================================================================
#  ESSÊNCIA ◆ (moeda meta: só de ondas/fases, nunca de kills)
# =====================================================================
static func essence(prog: Dictionary) -> int:
	return maxi(0, int(prog.get("essence", 0)))

## Soma essência ao banco e salva. Retorna o novo total.
static func add_essence(prog: Dictionary, amount: int) -> int:
	var total := maxi(0, int(prog.get("essence", 0)) + maxi(0, amount))
	prog["essence"] = total
	save_progress(prog)
	return total

## Prêmio por limpar uma onda (ondas finais pagam mais).
static func essence_for_wave(stage: int, wave_idx: int, diff: int) -> int:
	var base := 6 + wave_idx * 3 + stage * 8
	if wave_idx == WAVES_PER_STAGE - 1:
		base += 10
	return maxi(1, int(base * (1.0 + diff * 0.25)))

## Bônus por zerar a fase inteira.
static func essence_for_victory(stage: int, diff: int) -> int:
	return 25 * (stage + 1) * (diff + 1)

# =====================================================================
#  HABILIDADES (desbloqueio permanente por role, 5 slots)
# =====================================================================
static func unlocked_skills(prog: Dictionary, role: String) -> Array:
	var skills: Dictionary = prog.get("skills", {})
	if not skills.has(role):
		return [false, false, false, false, false]
	var row: Array = skills[role]
	var out: Array = []
	for i in 5:
		out.append(bool(row[i]) if i < row.size() else false)
	return out

static func unlocked_count(prog: Dictionary, role: String) -> int:
	var n := 0
	for b in unlocked_skills(prog, role):
		if b:
			n += 1
	return n

static func is_skill_unlocked(prog: Dictionary, role: String, idx: int) -> bool:
	var row := unlocked_skills(prog, role)
	if idx < 0 or idx >= row.size():
		return false
	return bool(row[idx])

## Tenta comprar a habilidade com essência. Retorna true se desbloqueou.
static func unlock_skill(prog: Dictionary, role: String, idx: int, cost: int) -> bool:
	var skills: Dictionary = prog.get("skills", {})
	if not skills.has(role):
		return false
	var row: Array = skills[role]
	if idx < 0 or idx >= row.size() or bool(row[idx]):
		return false
	if essence(prog) < cost:
		return false
	prog["essence"] = essence(prog) - cost
	row[idx] = true
	save_progress(prog)
	return true

# =====================================================================
#  SUPRIMENTOS (poções iniciais, comprados com ◆ na LOJA do menu)
# =====================================================================
static func supply_owned(prog: Dictionary, sid: String) -> int:
	var supplies: Dictionary = prog.get("supplies", {})
	return maxi(0, int(supplies.get(sid, 0)))

static func _supply_spec(sid: String) -> Dictionary:
	for spec in SUPPLIES:
		if str(spec.get("id", "")) == sid:
			return spec
	return {}

## Preço da próxima unidade (-1 se já no máximo).
static func supply_price(prog: Dictionary, sid: String) -> int:
	var spec := _supply_spec(sid)
	if spec.is_empty():
		return -1
	if supply_owned(prog, sid) >= int(spec.get("max", 1)):
		return -1
	return int(spec.get("base", 50)) * (supply_owned(prog, sid) + 1)

static func buy_supply(prog: Dictionary, sid: String) -> bool:
	var price := supply_price(prog, sid)
	if price < 0 or essence(prog) < price:
		return false
	prog["essence"] = essence(prog) - price
	var supplies: Dictionary = prog.get("supplies", {})
	supplies[sid] = supply_owned(prog, sid) + 1
	save_progress(prog)
	return true
