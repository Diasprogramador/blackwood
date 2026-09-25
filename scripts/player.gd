class_name Player
extends Node2D

## Jogador: stats portados do Player.java, desenho do ChampionArt,
## movimento com colisão de grade, combate e canalização de mana.

signal died
signal leveled_up(msg: String)
signal gold_changed(gold: int)

var champ_name := "Garen"
var role := "tank"

var level := 1
var xp := 0
var max_hp := 100
var hp := 100
var max_mana := 100
var mana := 100.0
var attack := 10
var defense := 5
var magic := 5
var gold := 200
var crit_chance := 0.15
var mana_regen := 1.0
var attack_range := 70

## Habilidades desbloqueadas (no menu, com ◆). Começa vazia: só ATK básico.
## Cada item: {cfg, cd_left}. Máximo = ChampData.SKILL_SLOTS (5, teclas 1-5).
var skills: Array = []  # [{cfg, cd_left}]
var upgrade_counts := [0, 0, 0, 0, 0, 0]

# Inventário (port de Player.java)
const MAX_INVENTORY := 10
var inventory: Array = []  # Item[]
var weapon: Equipment = null
var armor: Equipment = null

signal item_used(item: Item)
signal inventory_changed()

var facing := 1
var moving := false
var walk_phase := 0.0
var attack_cd := 0.0
var punch_t := 0.0
var hit_flash := 0
var channeling := false

# Animação com sprites do kit (suavização total: sem teleporte de pose).
var body: Sprite2D = null
var vel := Vector2.ZERO
var flip := 1.0
var spr_scale := 1.0
var spr_folder := "garen"
var has_sprites := false
var _pose := ""
var attack_t := 0.0
var hurt_t := 0.0
var cast_t := 0.0
var cast_slot := 0
var death_t := 0.0
var squash := 0.0
var lean := 0.0
var bob_t := 0.0
var sh_w := 22.0
var _part_t := 0.0
# Anti-garra: empurra e não sai do lugar → cutuca de lado, depois teleporta.
var _unstick_anchor := Vector2.ZERO
var _unstick_t := 0.0
var _unstick_stage := 0
# Rastro de movimento (fumaça na cor do campeão).
var trail: Array = []
const TRAIL_N := 14
const TRAIL_LIFE := 0.35

var world: World
var controlled := true
## Multiplayer: host dirige o P2 com inputs da rede (ignora o teclado local).
var use_ext := false
var ext_dir := Vector2.ZERO
## Mobile: direção do joystick (main preenche todo tick).
var touch_move := Vector2.ZERO
## Teclas da run (foto do GameSettings feita no setup; no menu não muda).
var bind: Dictionary = {}

const SPEED := 192.0  # 3.2 px/frame * 60

func _ready() -> void:
	z_index = 5
	_ensure_body()

func _ensure_body() -> void:
	if body != null and is_instance_valid(body):
		return
	body = Sprite2D.new()
	body.name = "Body"
	body.centered = true
	add_child(body)

## skill_cfgs: cfgs desbloqueadas no menu (pode ser vazio = só ATK básico).
func setup(p_name: String, p_role: String, skill_cfgs: Array = []) -> void:
	champ_name = p_name
	role = p_role
	var rs: Dictionary = ChampData.ROLES[role]
	level = 1
	xp = 0
	max_hp = rs.hp
	hp = max_hp
	max_mana = rs.mana
	mana = max_mana
	attack = rs.atk
	defense = rs.def
	magic = rs.mag
	attack_range = rs.range
	gold = 100
	crit_chance = 0.15
	mana_regen = 1.0
	bind = GameSettings.load_data().get("keys", {})
	skills.clear()
	for sk in skill_cfgs:
		if skills.size() >= ChampData.SKILL_SLOTS:
			break
		skills.append({ cfg = sk, cd_left = 0.0 })
	upgrade_counts = [0, 0, 0, 0, 0, 0]
	inventory.clear()
	weapon = null
	armor = null
	give_starting_items()
	facing = 1
	attack_cd = 0.0
	punch_t = 0.0
	hit_flash = 0
	trail.clear()
	channeling = false
	attack_t = 0.0
	hurt_t = 0.0
	cast_t = 0.0
	death_t = 0.0
	squash = 0.0
	lean = 0.0
	flip = 1.0
	vel = Vector2.ZERO
	_pose = ""
	# Sprites do kit (com fallback procedural se faltar arquivo).
	_ensure_body()
	spr_folder = str(SpriteKit.CHAMP_BY_ROLE.get(role, "garen"))
	has_sprites = SpriteKit.tex(SpriteKit.champ_pose(role, "idle")) != null
	if has_sprites:
		spr_scale = SpriteKit.fit(body, SpriteKit.champ_pose(role, "idle"), SpriteKit.CHAMP_H)
		sh_w = 22.0
		body.modulate = Color.WHITE
		body.rotation = 0.0
	queue_redraw()

func _process(delta: float) -> void:
	var d := minf(delta, 0.05)
	if attack_cd > 0: attack_cd -= d
	if punch_t > 0: punch_t = maxf(0.0, punch_t - d / 0.2)
	if attack_t > 0: attack_t = maxf(0.0, attack_t - d)
	if hurt_t > 0:
		hurt_t = maxf(0.0, hurt_t - d)
		if hurt_t <= 0.0:
			queue_redraw()
	if cast_t > 0: cast_t = maxf(0.0, cast_t - d)
	if hit_flash > 0:
		hit_flash -= 1
		if hit_flash <= 0:
			queue_redraw()
	for s in skills:
		if s.cd_left > 0:
			s.cd_left = maxf(0.0, s.cd_left - d)
	squash = maxf(0.0, squash - d * 5.0)
	if not is_alive():
		death_t += d

	# flip suave (atravessa o zero = esmagadinha natural, sem snap)
	flip = move_toward(flip, float(facing), d / 0.12)
	_update_body(d)

	# animação / aura pedem redesenho contínuo
	if moving or hit_flash > 0 or punch_t > 0 or channeling or attack_t > 0 or cast_t > 0:
		queue_redraw()

	# mana (piscina pequena: cada skill dói no bolso)
	if channeling:
		# Canalizar enche ~100 de mana em ~2.5s parado (jogo difícil: parado = alvo).
		mana = minf(max_mana, mana + 40.0 * d)
		_spawn_channel_part(d)
		if mana >= max_mana - 0.5:
			channeling = false
			set_process_unhandled_input(true)
	else:
		var per_sec := 3.5 + mana_regen + level * 0.6
		mana = minf(max_mana, mana + per_sec * d)

## Pose + transform do sprite (tudo interpolado: nada teleporta).
func _update_body(d: float) -> void:
	if body == null or not has_sprites:
		return
	var pose := "idle"
	if not is_alive():
		pose = "death"
	elif hurt_t > 0.0:
		pose = "hurt"
	elif attack_t > 0.0:
		pose = "attack"
	elif cast_t > 0.0:
		pose = "ultimate" if cast_slot >= 4 else ("skill_w" if cast_slot >= 2 else "skill_q")
	elif channeling:
		pose = "base"
	elif moving:
		pose = "walk"
	if pose != _pose:
		_pose = pose
		SpriteKit.swap(body, SpriteKit.champ_pose(role, pose))
	var spd := vel.length()
	bob_t += d * (4.0 + spd * 0.045)
	var bob := 0.0
	if not is_alive():
		bob = 6.0
	elif moving:
		bob = sin(bob_t) * minf(3.0, 1.0 + spd * 0.008)
	else:
		bob = sin(bob_t * 0.5) * 1.2  # respiração parado
	lean = lerpf(lean, clampf(vel.x * 0.00045, -0.10, 0.10), 1.0 - exp(-8.0 * d))
	var lunge := 0.0
	if attack_t > 0.0:
		lunge = 10.0 * (attack_t / 0.22)
	var kx := 0.18 * squash
	var ky := -0.14 * squash
	var fall := 0.0
	var fade := 1.0
	if not is_alive():
		var k := clampf(death_t / 0.4, 0.0, 1.0)
		fall = 1.5 * k * float(facing)
		fade = 1.0 - clampf((death_t - 0.5) / 1.0, 0.0, 1.0)
	body.position = Vector2(lunge * flip, bob)
	body.rotation = lean + fall
	body.scale = Vector2(-flip * spr_scale * (1.0 + kx), spr_scale * (1.0 + ky))
	if hurt_t > 0.0:
		body.modulate = Color(1, 0.45, 0.45)
	elif not is_alive():
		body.modulate = Color(1, 1, 1, maxf(0.0, fade))
	else:
		body.modulate = Color.WHITE

## Fagulhas subindo enquanto carrega mana (pose "carregando mana" do kit = base).
func _spawn_channel_part(d: float) -> void:
	_part_t -= d
	if _part_t > 0.0:
		return
	_part_t = 0.08
	var p := ParticleFx.new()
	add_child(p)
	# (ParticleFx anda em px/frame, não px/s: valores pequenos.)
	p.setup(randf_range(-10.0, 10.0), 8.0, randf_range(-0.6, 0.6), -2.8, Color(0.45, 0.7, 1))

func _physics_process(delta: float) -> void:
	var d := minf(delta, 0.05)
	if not controlled or channeling or world == null:
		# Desacelera suave até parar (sem trava seca).
		vel = vel.lerp(Vector2.ZERO, 1.0 - exp(-12.0 * d))
		moving = false
		return

	var dir := Vector2.ZERO
	if use_ext:
		dir = ext_dir
	else:
		if _held("move_up"): dir.y -= 1
		if _held("move_down"): dir.y += 1
		if _held("move_left"): dir.x -= 1
		if _held("move_right"): dir.x += 1
		if touch_move != Vector2.ZERO:
			dir = touch_move.normalized()

	var pushing := dir != Vector2.ZERO
	if pushing:
		if dir.x > 0: facing = 1
		elif dir.x < 0: facing = -1
		dir = dir.normalized()
		walk_phase += 0.3 * d * 60.0
	else:
		walk_phase += 0.06 * d * 60.0
	# Velocidade com aceleração/desaceleração exponencial: natural, sem snap.
	var target := dir * SPEED if pushing else Vector2.ZERO
	vel = vel.lerp(target, 1.0 - exp(-12.0 * d))
	moving = vel.length() > 25.0

	var step := vel * d
	# Passo com corpo (raio): desliza na parede em vez de agarrar no canto.
	position = MoveHelper.slide_step(world, position, step)
	_watch_unstick(d, pushing)
	_update_trail(d)
	queue_redraw()

## Anti-garra do jogador: 0.7s empurrando sem sair do lugar → cutucada
## de lado; se persistir → teleporta para o ponto livre mais próximo.
func _watch_unstick(d: float, pushing: bool) -> void:
	if world == null:
		return
	if not pushing:
		_unstick_t = 0.0
		_unstick_anchor = position
		_unstick_stage = 0
		return
	_unstick_t += d
	if _unstick_t < 0.7:
		return
	if position.distance_to(_unstick_anchor) >= 8.0:
		_unstick_t = 0.0
		_unstick_anchor = position
		_unstick_stage = 0
		return
	_unstick_stage += 1
	_unstick_t = 0.0
	_unstick_anchor = position
	if _unstick_stage == 1:
		_nudge_side()
	else:
		var free := MoveHelper.find_free(world, position)
		if free != Vector2.INF:
			position = free
		_unstick_stage = 0

func _nudge_side() -> void:
	var dir := vel.normalized() if vel.length() > 1.0 else Vector2.RIGHT
	for s in [1.0, -1.0]:
		var cand: Vector2 = position + Vector2(-dir.y, dir.x) * s * 26.0
		if MoveHelper.can_enter(world, cand):
			position = cand
			break

## Rastro de fumaça: guarda posições recentes, desenha esvaecendo.
func _update_trail(d: float) -> void:
	if moving and is_alive():
		trail.append({ p = position, life = TRAIL_LIFE })
	var i := trail.size() - 1
	while i >= 0:
		trail[i].life -= d
		if trail[i].life <= 0.0:
			trail.remove_at(i)
		i -= 1
	while trail.size() > TRAIL_N:
		trail.pop_front()

func _held(action_id: String) -> bool:
	if not bind.has(action_id):
		return false
	for code in (bind[action_id] as Array):
		if Input.is_physical_key_pressed(int(code)):
			return true
	return false

# =====================================================================
#  COMBATE
# =====================================================================
func is_alive() -> bool:
	return hp > 0

func take_damage(raw: int) -> int:
	var reduction := defense / float(defense + 100)
	var final_d := maxi(1, int(raw * (1.0 - reduction)))
	hp = maxi(0, hp - final_d)
	hit_flash = 8
	hurt_t = 0.3
	squash = 1.0
	queue_redraw()
	if hp <= 0:
		died.emit()
	return final_d

func calc_damage() -> int:
	return int(attack * randf_range(0.8, 1.2))

func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)
	queue_redraw()

func restore_mana(amount: int) -> void:
	mana = minf(float(max_mana), mana + float(amount))

func toggle_channel() -> bool:
	if channeling:
		channeling = false
		return false
	if mana >= max_mana:
		return false
	channeling = true
	return true

## Ataca o alvo mais próximo dentro do alcance. Retorna o alvo ou null.
func basic_attack(enemies: Array) -> Variant:
	if attack_cd > 0.0 or channeling:
		return null
	var target = nearest_enemy(enemies, attack_range)
	if target == null:
		return null
	var raw := calc_damage()
	var is_crit := randf() < crit_chance
	var dealt: int = target.take_damage(raw)
	if is_crit:
		dealt += target.take_damage(int(raw / 2.0))
	attack_cd = 22.0 / 60.0
	punch_t = 1.0
	attack_t = 0.22
	squash = 1.0
	queue_redraw()
	return { target = target, crit = is_crit, dmg = dealt }

func cast_skill(index: int, enemies: Array) -> Dictionary:
	if index >= skills.size():
		return { ok = false }
	var s: Dictionary = skills[index]
	var cfg: Dictionary = s.cfg
	if s.cd_left > 0.0 or mana < float(cfg.mana):
		return { ok = false, reason = "Sem mana / em cooldown!" }
	mana -= float(cfg.mana)
	s.cd_left = cfg.cd
	cast_t = 0.35
	cast_slot = index
	squash = 0.8

	if cfg.kind == "heal":
		var amount: int = magic + int(cfg.power) + 4
		heal(amount)
		return { ok = true, kind = "heal", amount = amount }

	var skill_range := attack_range + 80
	var target = nearest_enemy(enemies, skill_range)
	if target == null:
		mana += float(cfg.mana)
		s.cd_left = 0.0
		return { ok = false, reason = "Sem alvo no alcance!" }

	var raw: int
	if cfg.kind == "magic":
		raw = magic + cfg.power + 6
	else:
		raw = attack + cfg.power + 5
	var dealt: int = target.take_damage(raw)
	return { ok = true, kind = cfg.kind, target = target, dmg = dealt, name = cfg.name }

func nearest_enemy(enemies: Array, range_px: float) -> Variant:
	var best = null
	var best_d := range_px
	for e in enemies:
		if not e.is_alive():
			continue
		var d := position.distance_to(e.position)
		if d < best_d:
			best_d = d
			best = e
	return best

# =====================================================================
#  PROGRESSÃO / LOJA
# =====================================================================
func gain_exp(amount: int) -> String:
	xp += amount
	var msg := ""
	while xp >= exp_to_next():
		xp -= exp_to_next()
		level += 1
		_on_level_up()
		msg = "LEVEL UP! Lv.%d  +%d HP  +%d ATK  +%d DEF  +%d MAG" % [
			level, maxi(8, int(max_hp / 8.0)), maxi(1, int(attack / 6.0)), maxi(1, int(defense / 6.0)), maxi(1, int(magic / 6.0))
		]
	leveled_up.emit(msg)
	return msg

func exp_to_next() -> int:
	# Curva dura: L1=180, L2=285, L3=440, L4=645... (~2-3 ups por run).
	return 100 + level * 80 + (level - 1) * (level - 1) * 25

func _on_level_up() -> void:
	var hp_gain := maxi(8, int(max_hp / 8.0))
	max_hp += hp_gain
	max_mana += 8
	attack += maxi(1, int(ChampData.ROLES[role].atk / 6.0))
	defense += maxi(1, int(ChampData.ROLES[role].def / 6.0))
	magic += maxi(1, int(ChampData.ROLES[role].mag / 6.0))
	crit_chance = minf(0.5, crit_chance + 0.015)
	# Level up cura 60% em vez de 100% (jogo mais difícil).
	hp = mini(max_hp, hp + int(max_hp * 0.6))
	mana = max_mana

func upgrade_cost(type_idx: int) -> int:
	var base: int = ChampData.UPGRADE_BASE_COST[type_idx]
	return base + int(upgrade_counts[type_idx] * base * 0.75)

func buy_upgrade(type_idx: int) -> bool:
	var cost := upgrade_cost(type_idx)
	if gold < cost:
		return false
	gold -= cost
	upgrade_counts[type_idx] += 1
	match type_idx:
		0:
			max_hp += 30
			hp += 30
		1: attack += 5
		2: defense += 4
		3: magic += 4
		4: crit_chance = minf(0.75, crit_chance + 0.05)
		5: mana_regen += 1.5
	gold_changed.emit(gold)
	return true

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false

# =====================================================================
#  INVENTÁRIO / ITENS (port de Player.java)
# =====================================================================
func give_starting_items() -> void:
	inventory.append(HealthPotion.new(ItemType.HEALTH_POTION, 100))
	inventory.append(HealthPotion.new(ItemType.HEALTH_POTION, 100))
	inventory.append(ManaPotion.new(ItemType.MANA_POTION, 80))
	# Suprimentos da LOJA do menu (◆): poções extras em toda run.
	var prog := StageData.load_progress()
	for i in StageData.supply_owned(prog, "hp"):
		inventory.append(HealthPotion.new(ItemType.HEALTH_POTION, 100))
	for i in StageData.supply_owned(prog, "mp"):
		inventory.append(ManaPotion.new(ItemType.MANA_POTION, 80))
	for i in StageData.supply_owned(prog, "elix"):
		inventory.append(Elixir.new(ItemType.ELIXIR, 200, 150))
	inventory_changed.emit()

func add_item(item: Item) -> bool:
	if inventory.size() >= MAX_INVENTORY:
		print("  >> Inventario cheio!")
		return false
	inventory.append(item)
	inventory_changed.emit()
	return true

func remove_item(item: Item) -> bool:
	var idx := inventory.find(item)
	if idx < 0:
		return false
	inventory.remove_at(idx)
	inventory_changed.emit()
	return true

func get_item(index: int) -> Item:
	if index >= 0 and index < inventory.size():
		return inventory[index]
	return null

func use_item(index: int) -> bool:
	if index < 0 or index >= inventory.size():
		print("  >> Item invalido!")
		return false
	var item: Item = inventory[index]
	if item is Equipment:
		return equip_item(index)
	item.use(self)
	inventory.remove_at(index)
	item_used.emit(item)
	inventory_changed.emit()
	return true

func equip_item(inventory_index: int) -> bool:
	if inventory_index < 0 or inventory_index >= inventory.size():
		return false
	var item: Item = inventory[inventory_index]
	if not (item is Equipment):
		print("  >> Este item nao pode ser equipado!")
		return false
	var equipment := item as Equipment
	var stat := equipment.stat_type
	if stat == "ATK":
		if weapon != null:
			attack -= weapon.bonus_value
			inventory.append(weapon)
		weapon = equipment
		attack += equipment.bonus_value
	elif stat == "DEF":
		if armor != null:
			defense -= armor.bonus_value
			inventory.append(armor)
		armor = equipment
		defense += equipment.bonus_value
	elif stat == "MAG":
		magic += equipment.bonus_value
	inventory.remove_at(inventory_index)
	print("  >> %s equipou %s!" % [champ_name, equipment.name])
	inventory_changed.emit()
	return true

func buy_item(item: Item) -> bool:
	if gold >= item.price:
		if add_item(item):
			gold -= item.price
			gold_changed.emit(gold)
			print("  >> %s comprou %s por %d gold!" % [champ_name, item.name, item.price])
			return true
	else:
		print("  >> Gold insuficiente!")
	return false

func sell_item(index: int) -> void:
	if index < 0 or index >= inventory.size():
		return
	var item: Item = inventory[index]
	var sell_price := int(item.price / 2.0)
	gold += sell_price
	gold_changed.emit(gold)
	inventory.remove_at(index)
	inventory_changed.emit()
	print("  >> %s vendeu %s por %d gold!" % [champ_name, item.name, sell_price])

func shop_catalog() -> Array:
	return [
		HealthPotion.new(ItemType.HEALTH_POTION, 100),
		ManaPotion.new(ItemType.MANA_POTION, 80),
		Elixir.new(ItemType.ELIXIR, 200, 150),
		Equipment.new(ItemType.ATTACK_BOOTS, "ATK", 5),
		Equipment.new(ItemType.DEFENSE_ARMOR, "DEF", 8),
		Equipment.new(ItemType.MAGIC_ROBE, "MAG", 7),
	]

# =====================================================================
#  DESENHO (sombra + fallback procedural; o corpo é o Sprite2D `body`)
# =====================================================================
func _draw() -> void:
	# Sombra suave no chão (acompanha a largura do sprite).
	ArtUtil.fill_ellipse(self, 0, 10, sh_w, sh_w * 0.32, Color(0, 0, 0, 0.32))

	# Rastro (fumaça na cor do campeão, atrás do corpo).
	var rc := SkillIcon.role_color(role)
	for tp in trail:
		var a: float = clampf(float(tp.life) / TRAIL_LIFE, 0.0, 1.0)
		var lp: Vector2 = tp.p - position
		var tr := 2.0 + 6.0 * a
		ArtUtil.fill_ellipse(self, lp.x, lp.y, tr, tr * 0.7, Color(rc, 0.28 * a))

	# Fallback procedural (se o kit não carregou): espelha via transform.
	if not has_sprites:
		var bob := int(sin(walk_phase) * (3.0 if moving else 1.0))
		if facing < 0:
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1, 1))
			ChampionArt.draw_champion(self, role, bob, hit_flash > 0, walk_phase, moving, punch_t)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			ChampionArt.draw_champion(self, role, bob, hit_flash > 0, walk_phase, moving, punch_t)

	# aura de canalização
	if channeling:
		var pulse := sin(Time.get_ticks_msec() * 0.01) * 0.5 + 0.5
		var r := 40.0 + pulse * 15.0
		draw_circle(Vector2.ZERO, r, Color(0.24, 0.47, 1, 0.18 + 0.15 * pulse))
		draw_arc(Vector2.ZERO, r - 8, 0, TAU, 32, Color(0.4, 0.67, 1, 0.6), 2)
		# raízes
		ArtUtil.fill_ellipse(self, 0, 12, 18, 5, Color(0.31, 0.24, 0.12, 0.7))
		draw_arc(Vector2(0, 12), 18, 0, TAU, 20, Color(0.24, 0.18, 0.08), 1.5)

## Barra de vida flutuante desenhada pela Main (em coordenadas de mundo).
func draw_status_bar(node: CanvasItem) -> void:
	var y := -30.0
	# HP
	_sprite_bar(node, -16, y, 32, 4, hp, max_hp, Color(0.2, 0.8, 0.25))
	# MP
	_sprite_bar(node, -16, y + 6, 32, 3, int(mana), max_mana, Color(0.31, 0.55, 1))

func _sprite_bar(node: CanvasItem, x: float, y: float, w: float, h: float,
		cur: int, mx: int, col: Color) -> void:
	node.draw_rect(Rect2(x - 1, y - 1, w + 2, h + 2), Color(0, 0, 0, 0.6))
	node.draw_rect(Rect2(x, y, w, h), Color(0.2, 0.2, 0.2))
	var ratio := clampf(cur / float(maxi(1, mx)), 0.0, 1.0)
	node.draw_rect(Rect2(x, y, w * ratio, h), col)
	node.draw_rect(Rect2(x, y, w, h), Color(0, 0, 0, 0.8))
